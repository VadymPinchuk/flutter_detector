import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// BLoC

/// Tiny BLoC for fetching device cameras list
class CamerasBloc extends Bloc<CamerasEvent, CamerasState> {
  CamerasBloc() : super(const InitialCamerasState()) {
    add(GetCamerasEvent());
  }

  @override
  Stream<CamerasState> mapEventToState(CamerasEvent event) async* {
    try {
      final cameras = await availableCameras();
      yield CamerasAvailableState(cameras);
    } on CameraException catch (e) {
      yield const NoCamerasAvailableState();
      logError(e.code, e.description);
    }
  }
}

void logError(String code, String message) => print('Error: $code\nError Message: $message');

/// State
@immutable
abstract class CamerasState extends Equatable {
  const CamerasState(this.cameras);

  final List<CameraDescription> cameras;

  @override
  List<Object> get props => cameras;
}

class InitialCamerasState extends CamerasState {
  const InitialCamerasState({List<CameraDescription> cameras = const <CameraDescription>[]}) : super(cameras);
}

class NoCamerasAvailableState extends CamerasState {
  const NoCamerasAvailableState({List<CameraDescription> cameras = const <CameraDescription>[]}) : super(cameras);
}

class CamerasAvailableState extends CamerasState {
  const CamerasAvailableState(List<CameraDescription> cameras) : super(cameras);
}

/// Event

@immutable
abstract class CamerasEvent {}

class GetCamerasEvent extends CamerasEvent {}
