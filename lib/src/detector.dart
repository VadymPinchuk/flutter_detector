import 'dart:async';
import 'dart:io' as io;
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:exif/exif.dart';
import 'package:firebase_ml_custom/firebase_ml_custom.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_detector/src/models/decode_params.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:image/image.dart' as image;
import 'package:path_provider/path_provider.dart';
import 'package:tflite/tflite.dart';

const String WIDTH_KEY = 'EXIF ExifImageWidth';
const String HEIGHT_KEY = 'EXIF ExifImageLength';
const String ROTATION_KEY = 'Image Orientation';

typedef DetectionCallback = void Function(List<dynamic> list);
typedef CutOffCallback = void Function();

/// Class with access to model loading, label detection, etc.
class Detector {
  factory Detector() => _instance;

  Detector._internal();

  static final Detector _instance = Detector._internal();

  /// Initialize detector with provided models
  /// Gets the model ready for inference on images.
  Future<String> initializeDetector({String model, String labels}) async {
    final modelFile = await _loadModelFromFirebase(model);
    return await loadTFLiteModel(modelFile, labels);
  }

  /// Downloads custom model from the Firebase console and return its file.
  /// located on the mobile device.
  Future<File> _loadModelFromFirebase([String modelName]) async {
    try {
      // Create model with a name that is specified in the Firebase console
      final model = FirebaseCustomRemoteModel(modelName ?? 'ssd_mobilenet');

      // Specify conditions when the model can be downloaded.
      // If there is no wifi access when the app is started,
      // this app will continue loading until the conditions are satisfied.
      final conditions = FirebaseModelDownloadConditions(androidRequireWifi: true, iosAllowCellularAccess: false);

      // Create model manager associated with default Firebase App instance.
      final modelManager = FirebaseModelManager.instance;

      // Begin downloading and wait until the model is downloaded successfully.
      await modelManager.download(model, conditions);
      assert(await modelManager.isModelDownloaded(model) == true);

      // Get latest model file to use it for inference by the interpreter.
      final modelFile = await modelManager.getLatestModelFile(model);
      assert(modelFile != null);
      return modelFile;
    } catch (exception) {
      print('Failed on loading your model from Firebase: $exception');
      print('The program will not be resumed');
      rethrow;
    }
  }

  /// Loads the model into some TF Lite interpreter.
  /// In this case interpreter provided by tflite plugin.
  Future<String> loadTFLiteModel(File modelFile, [String labelsName]) async {
    try {
      final appDirectory = await getApplicationDocumentsDirectory();
      final labelsData = await rootBundle.load(labelsName ?? 'assets/ssd_mobilenet.txt');
      final labelsFile = await File(appDirectory.path + '/ssd_mobilenet.txt')
          .writeAsBytes(labelsData.buffer.asUint8List(labelsData.offsetInBytes, labelsData.lengthInBytes));

      assert(await Tflite.loadModel(
            model: modelFile.path,
            labels: labelsFile.path,
            numThreads: 2,
            isAsset: false,
          ) ==
          'success');
      return 'Model is loaded';
    } catch (exception) {
      print('Failed on loading your model to the TFLite interpreter: $exception');
      print('The program will not be resumed');
      rethrow;
    }
  }

  /// Release memory
  Future<dynamic> release() => Tflite.close();

  /// Detect objects on image
  Future<List<dynamic>> detectObjects(String imagePath) async {
    final int startTime = DateTime.now().millisecondsSinceEpoch;

    return FlutterExifRotation.rotateImage(path: imagePath)
        .then((file) => Tflite.detectObjectOnImage(
              path: file.path,
              threshold: 0.3,
            ))
        .then<List<dynamic>>(
      (List<dynamic> recognitions) {
        final int endTime = DateTime.now().millisecondsSinceEpoch;
        debugPrint('Detection took ${endTime - startTime}');
        return recognitions;
      },
    );
  }

  /// Cropping task in a separate isolate
  Future<dynamic> croppObjects(DecodeParam param) => Isolate.spawn(_readAndCropp, param);

  /// Read image from path and crop all boxes from it
  static Future<dynamic> _readAndCropp(DecodeParam param) async {
    final image.Image picture = await _getBytes(param.path).then((value) => image.decodeImage(value));

    param.sendPort.send(
      param.boxes
          .map((dynamic box) => _scaleBox(box, param.preview))
          .map((List<int> box) => _copyCropp(
                picture,
                box[0],
                box[1],
                min(box[2], picture.width - box[0]), // min is used to fit into image bounds
                min(box[3], picture.height - box[1]), // min is used to fit into image bounds
              ))
          .map((image.Image img) {
        final String path = '${param.dirPath}/${DateTime.now().millisecondsSinceEpoch.toString()}.jpg';
        io.File(path).writeAsBytesSync(image.encodePng(img));
        return path;
      }).toList(),
    );
  }

  /// Crop and return cropped image
  static image.Image _copyCropp(image.Image src, int x, int y, int w, int h) {
    final image.Image dst = image.Image(w, h, channels: src.channels, exif: src.exif, iccp: src.iccProfile);

    for (var yi = 0, sy = y; yi < h; ++yi, ++sy) {
      for (var xi = 0, sx = x; xi < w; ++xi, ++sx) {
        dst.setPixel(xi, yi, src.getPixel(sx, sy));
      }
    }
    return dst;
  }

  /// Scaling recognition box in respect with size of preview (image)
  static List<int> _scaleBox(dynamic box, Size preview) {
    final previewH = max(preview.height, preview.width);
    final previewW = min(preview.height, preview.width);

    final double _x = box['rect']['x'] as double;
    final double _w = box['rect']['w'] as double;
    final double _y = box['rect']['y'] as double;
    final double _h = box['rect']['h'] as double;
    double x, y, w, h;
    x = _x * previewW;
    y = _y * previewH;
    w = _w * previewW;
    h = _h * previewH;
    return <int>[
      x.toInt(),
      y.toInt(),
      w.toInt(),
      h.toInt(),
    ];
  }

  /// Image Exif information reader
  static Future<Map<String, IfdTag>> getExif(String imagePath) => _getBytes(imagePath).then(readExifFromBytes);

  /// Image Exif size getter
  static Future<Size> getImageSize(String imagePath) => _getBytes(imagePath).then(readExifFromBytes).then((data) {
        Size size;
        if (data != null && data.isNotEmpty) {
          final double w = double.tryParse(data[WIDTH_KEY].toString());
          final double h = double.tryParse(data[HEIGHT_KEY].toString());
          size = Size(min(w, h), max(w, h));
        }
        return size;
      });

  /// Get list of image bytes
  static Future<Uint8List> _getBytes(String imagePath) => io.File(imagePath).readAsBytes();

  static Future<void> _printExifOfPath(String path) => _getBytes(path).then(_printExifOfBytes);

  static Future<void> _printExifOfBytes(Uint8List bytes) async {
    final Map<String, IfdTag> data = await readExifFromBytes(bytes);

    if (data == null || data.isEmpty) {
      debugPrint('No EXIF information found\n');
      return;
    }

    if (data.containsKey('JPEGThumbnail')) {
      debugPrint('File has JPEG thumbnail');
      data.remove('JPEGThumbnail');
    }
    if (data.containsKey('TIFFThumbnail')) {
      debugPrint('File has TIFF thumbnail');
      data.remove('TIFFThumbnail');
    }

    for (final key in data.keys) {
      debugPrint('$key (${data[key].tagType}): ${data[key]}');
    }
  }
}
