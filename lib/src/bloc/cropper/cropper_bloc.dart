import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_detector/src/detector.dart';
import 'package:flutter_detector/src/models/decode_params.dart';
import 'package:meta/meta.dart';

part 'cropper_event.dart';
part 'cropper_state.dart';

/// BLoC responsible for cropping detected labels from image
class CropperBloc extends Bloc<CropperEvent, CropperState> {
  CropperBloc(this._detector) : super(InitialCropperState());
  final Detector _detector;

  @override
  Stream<CropperState> mapEventToState(CropperEvent event) async* {
    if (event is LastImageDataEvent) {
      if (state is CroppInProgressState) {
        return;
      }
      yield CroppDataState(event.dirPath, event.imagePath, event.imageSize, event.boxes);
      return;
    }
    if (event is CroppImageEvent) {
      if (state is CroppInProgressState) {
        return;
      }
      if (state is CroppDataState) {
        yield CroppInProgressState.from(state as CroppDataState);
        final dataState = state as CroppInProgressState;
        final ReceivePort receivePort = ReceivePort();
        final DecodeParam param = DecodeParam(
          dataState.imagePath,
          '${dataState.dirPath}/cropp',
          dataState.imageSize,
          dataState.boxes,
          receivePort.sendPort,
        );
        await _detector.croppObjects(param);
        yield CroppSuccessState(await receivePort.first as List<String>);
      }
    }
  }
}
