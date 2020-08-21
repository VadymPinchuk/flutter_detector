import 'dart:isolate';
import 'dart:ui';

/// Basic data model to be provided to isolate, to cropp labels from image
class DecodeParam {
  DecodeParam(this.path, this.dirPath, this.preview, this.boxes, this.sendPort);

  final String path;
  final String dirPath;
  final Size preview;
  final List<dynamic> boxes;
  final SendPort sendPort;
}
