import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

/// BLoC

/// Tiny BLoC responsible only for listening lifecycle state and push changes if any
class LifecycleBloc extends Bloc<LifecycleEvent, LifecycleState> with WidgetsBindingObserver {
  LifecycleBloc() : super(const LifecycleState(true)) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Stream<LifecycleState> mapEventToState(LifecycleEvent event) async* {
    if (event.isActive != state.isActive) {
      yield LifecycleState(event.isActive);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      add(const LifecycleEvent(true));
      return;
    }
    if (state == AppLifecycleState.paused) {
      add(const LifecycleEvent(false));
      return;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

/// Event

class LifecycleEvent {
  const LifecycleEvent(this.isActive);

  final bool isActive;

  @override
  String toString() => 'LifecycleEvent $isActive';
}

/// State

class LifecycleState extends Equatable {
  const LifecycleState(this.isActive);

  final bool isActive;

  @override
  List<Object> get props => [isActive];
}
