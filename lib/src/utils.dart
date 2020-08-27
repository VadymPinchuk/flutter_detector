import 'dart:async';
import 'dart:io' as io;
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:exif/exif.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_detector/src/models/decode_params.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:image/image.dart' as image;
import 'package:tflite/tflite.dart';

const String WIDTH_KEY = 'EXIF ExifImageWidth';
const String HEIGHT_KEY = 'EXIF ExifImageLength';
const String ROTATION_KEY = 'Image Orientation';

typedef DetectionCallback = void Function(List<dynamic> list);
typedef CutOffCallback = void Function();

// ignore: avoid_classes_with_only_static_members
/// Utils class with access to model loading, label detection, etc.
class Utils {
  /// Initialize detector with provided models
  static Future<String> initializeDetector({String model, String labels}) async => Tflite.loadModel(
        model: model ?? 'assets/ssd_mobilenet.tflite',
        labels: labels ?? 'assets/ssd_mobilenet.txt',
        numThreads: 2,
      );

  /// Release memory
  static Future<dynamic> release() => Tflite.close();

  /// Detect objects on image
  static Future<List<dynamic>> detectObjects(String imagePath) async {
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
  static Future<dynamic> croppObjects(DecodeParam param) => Isolate.spawn(_readAndCropp, param);

  /// Read image from path and crop all boxes from it
  static Future<dynamic> _readAndCropp(DecodeParam param) async {
    final image.Image picture = await _getBytes(param.path).then((value) => image.decodeImage(value));

    param.sendPort.send(
      param.boxes
          .map((dynamic box) => _scaleBox(box, param.preview))
          .map((List<int> box) => _copyCrop(
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
  static image.Image _copyCrop(image.Image src, int x, int y, int w, int h) {
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
