import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:permission_handler/permission_handler.dart';

/// BLoC

/// Tiny BLoC responsible for handling permissions
class PermissionsBloc extends Bloc<CheckPermissionsEvent, PermissionsState> {
  PermissionsBloc() : super(PermissionsRequestedState()) {
    checkPermissions();
  }

  void checkPermissions() {
    if (state is PermissionsRequestedState) {
      add(CheckPermissionsEvent());
    }
  }

  @override
  Stream<PermissionsState> mapEventToState(CheckPermissionsEvent event) async* {
    if (state is PermissionsPermDeniedState) {
      await openAppSettings();
      yield PermissionsRequestedState();
    } else {
      final Map<Permission, PermissionStatus> permissions = await _getPermissions();
      if (permissions.values.contains(PermissionStatus.permanentlyDenied)) {
        yield PermissionsPermDeniedState();
      } else if (permissions.values.contains(PermissionStatus.denied)) {
        yield PermissionsDeniedState();
      } else {
        yield PermissionsGrantedState();
      }
    }
  }

  /// Permissions request
  Future<Map<Permission, PermissionStatus>> _getPermissions() => [
        Permission.camera,
        Permission.microphone,
        Permission.storage,
      ].request();
}

/// State

enum PermissionsStatus { REQUESTED, GRANTED, DENIED, PERMANENTLY_DENIED }

@immutable
abstract class PermissionsState extends Equatable {
  PermissionsStatus get status;

  @override
  List<Object> get props => [status];
}

class PermissionsRequestedState extends PermissionsState {
  @override
  PermissionsStatus get status => PermissionsStatus.REQUESTED;
}

class PermissionsGrantedState extends PermissionsState {
  @override
  PermissionsStatus get status => PermissionsStatus.GRANTED;
}

class PermissionsDeniedState extends PermissionsState {
  @override
  PermissionsStatus get status => PermissionsStatus.DENIED;
}

class PermissionsPermDeniedState extends PermissionsState {
  @override
  PermissionsStatus get status => PermissionsStatus.PERMANENTLY_DENIED;
}

/// Event

@immutable
class CheckPermissionsEvent {}
