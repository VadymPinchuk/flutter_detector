import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_detector/src/bloc/cameras/cameras_bloc.dart';
import 'package:flutter_detector/src/bloc/cropper/cropper_bloc.dart';
import 'package:flutter_detector/src/bloc/detector/detector_bloc.dart';
import 'package:flutter_detector/src/bloc/lifecycle/lifecycle_bloc.dart';
import 'package:flutter_detector/src/bloc/permissions/permissions_bloc.dart';
import 'package:flutter_detector/src/ui/detector_widget.dart';
import 'package:flutter_detector/src/utils.dart';
import 'package:wakelock/wakelock.dart';

// Hardcoded app bar height. Need to be taken into account while detected labels are drawn on the screen.
// If screen will have some other widgets in column on top of camera - need to know their height
const double APP_BAR_HEIGHT = 50.0;

/// To be used in applications as single source of truth
/// Outer accessible Widget which wraps all BLoCs and UI
class VisorComponent extends StatefulWidget {
  @override
  State<VisorComponent> createState() => _VisorComponentState();
}

class _VisorComponentState extends State<VisorComponent> {
  PermissionsBloc permissionsBloc;
  LifecycleBloc lifecycleBloc;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    Bloc.observer = SimpleBlocObserver();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    Wakelock.enable();
    permissionsBloc = PermissionsBloc();
    lifecycleBloc = LifecycleBloc();
  }

  @override
  void dispose() {
    Wakelock.disable();
    lifecycleBloc.dispose();
    Utils.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider<LifecycleBloc>(create: (_) => lifecycleBloc),
          BlocProvider<CamerasBloc>(create: (_) => CamerasBloc()),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: BlocListener<LifecycleBloc, LifecycleState>(
                listener: (_, lifecycle) => lifecycle.isActive ? permissionsBloc.checkPermissions() : null,
                child: BlocBuilder<PermissionsBloc, PermissionsState>(
                  cubit: permissionsBloc,
                  builder: (_, permissions) => permissions is PermissionsGrantedState
                      ? MultiBlocProvider(
                          providers: [
                            BlocProvider<DetectorBloc>(create: (_) => DetectorBloc()),
                            BlocProvider<CropperBloc>(create: (_) => CropperBloc()),
                          ],
                          child: DetectorWidget(),
                        )
                      : Center(
                          child: FlatButton(
                            child: const Text('GRAND PERMISSIONS'),
                            textColor: Colors.blue,
                            onPressed: () => permissionsBloc.add(CheckPermissionsEvent()),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      );
}

/// Simple listener to observe BLoC changes
/// For debug purposes only
class SimpleBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object event) {
    print(event);
    super.onEvent(bloc, event);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    print(transition);
    super.onTransition(bloc, transition);
  }

  @override
  void onError(Cubit cubit, Object error, StackTrace stackTrace) {
    print(error);
    super.onError(cubit, error, stackTrace);
  }
}
