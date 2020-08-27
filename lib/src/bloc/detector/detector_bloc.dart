import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_detector/src/utils.dart';
import 'package:meta/meta.dart';

/// BLoC

/// Object detector on provided image
/// Responsible for models loading and detections itself
class DetectorBloc extends Bloc<DetectorEvent, DetectorState> {
  DetectorBloc() : super(DetectorLoadingSuccessState());

  @override
  Stream<DetectorState> mapEventToState(DetectorEvent event) async* {
    if (event is InitialiseDetectorEvent) {
      if (state is! DetectorLoadingState) {
        yield DetectorLoadingState();
        try {
          await Utils.initializeDetector();
          yield DetectorLoadingSuccessState();
        } catch (e) {
          yield DetectorLoadingErrorState();
        }
      }
      return;
    }
    if (event is DetectObjectsEvent) {
      if (state is DetectionInProgressState || state is DetectorLoadingErrorState) {
        return;
      }
      yield DetectionInProgressState();
      final value = await Utils.detectObjects(event.imagePath);
      yield DetectedObjectsState(value);
      return;
    }
  }
}

/// State

abstract class DetectorState extends Equatable {
  DetectorState(List<dynamic> list) {
    boxes.clear();
    boxes.addAll(list.where((dynamic box) => box['confidenceInClass'] as double > 0.5));
  }

  final List<dynamic> boxes = <dynamic>[];

  @override
  List<Object> get props => boxes;
}

class DetectorLoadingState extends DetectorState {
  DetectorLoadingState() : super(<dynamic>[]);
}

class DetectorLoadingSuccessState extends DetectorState {
  DetectorLoadingSuccessState() : super(<dynamic>[]);
}

class DetectorLoadingErrorState extends DetectorState {
  DetectorLoadingErrorState() : super(<dynamic>[]);
}

class DetectionInProgressState extends DetectorState {
  DetectionInProgressState() : super(<dynamic>[]);
}

class DetectedObjectsState extends DetectorState {
  DetectedObjectsState(List<dynamic> boxes) : super(boxes);
}

/// Event

@immutable
abstract class DetectorEvent {
  const DetectorEvent();
}

class InitialiseDetectorEvent extends DetectorEvent {}

class DetectObjectsEvent extends DetectorEvent {
  const DetectObjectsEvent(this.imagePath);

  final String imagePath;

  @override
  String toString() => 'DetectObjectsEvent $imagePath';
}
