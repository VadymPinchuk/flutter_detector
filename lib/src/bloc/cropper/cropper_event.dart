part of 'cropper_bloc.dart';

@immutable
abstract class CropperEvent {}

class LastImageDataEvent extends CropperEvent {
  LastImageDataEvent(this.dirPath, this.imagePath, this.imageSize, this.boxes);

  final String dirPath;
  final String imagePath;
  final Size imageSize;
  final List<dynamic> boxes;
}

class CroppImageEvent extends CropperEvent {}
