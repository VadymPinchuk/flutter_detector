import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'src/ui/detector_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(CameraApp());
}

class CameraApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData.fromWindow(window),
          child: DetectorScreen(),
        ),
      );
}
