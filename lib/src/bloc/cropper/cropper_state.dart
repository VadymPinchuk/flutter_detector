part of 'cropper_bloc.dart';

@immutable
abstract class CropperState extends Equatable {
  @override
  List<Object> get props => [];
}

class InitialCropperState extends CropperState {}

class CroppDataState extends CropperState {
  CroppDataState(this.dirPath, this.imagePath, this.imageSize, this.boxes);

  final String dirPath;
  final String imagePath;
  final Size imageSize;
  final List<dynamic> boxes;

  @override
  List<Object> get props => [imagePath, boxes];
}

class CroppInProgressState extends CroppDataState {
  CroppInProgressState.from(CroppDataState state) : super(state.dirPath, state.imagePath, state.imageSize, state.boxes);
}

class CroppSuccessState extends CropperState {
  CroppSuccessState(this.crops);

  final List<String> crops;

  @override
  List<Object> get props => crops;
}
