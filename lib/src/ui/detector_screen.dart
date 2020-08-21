import 'package:flutter/material.dart';
import 'package:flutter_detector/src/ui/detector_component.dart';

class DetectorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        color: Colors.blue,
        child: SafeArea(
          child: Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(APP_BAR_HEIGHT),
              child: AppBar(
                title: const Text('TFLite detector example'),
              ),
            ),
            body: VisorComponent(),
          ),
        ),
      );
}
