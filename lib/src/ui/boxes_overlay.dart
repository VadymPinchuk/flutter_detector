import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_detector/src/bloc/detector/detector_bloc.dart';

/// Stack widget with frames for each detected entity
class BoxesOverlay extends StatelessWidget {
  const BoxesOverlay(this.previewH, this.previewW, this.screenH, this.screenW);

  final double previewH;
  final double previewW;
  final double screenH;
  final double screenW;

  @override
  Widget build(BuildContext context) => BlocBuilder<DetectorBloc, DetectorState>(
        buildWhen: (_, state) => state is DetectedObjectsState,
        builder: (_, boxesState) => Stack(
          children: boxesState.boxes
              .map(_scaleBox)
              .map(
                (List<dynamic> box) => Positioned(
                  left: math.max(0, box[0] as double),
                  top: math.max(0, box[1] as double),
                  width: box[2] as double,
                  height: box[3] as double,
                  child: Container(
                    padding: const EdgeInsets.all(5.0),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(const Radius.circular(8.0)),
                      border: Border.all(
                        color: Colors.teal,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      box[4] as String,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );

  /// Recognition processing to be displayed in proper places on the screen
  List<dynamic> _scaleBox(dynamic box) {
    final double _x = box['rect']['x'] as double;
    final double _w = box['rect']['w'] as double;
    final double _y = box['rect']['y'] as double;
    final double _h = box['rect']['h'] as double;
    double scaleW, scaleH, x, y, w, h;

    if (screenH / screenW > previewH / previewW) {
      scaleW = screenH / previewH * previewW;
      scaleH = screenH;
      final difW = (scaleW - screenW) / scaleW;
      x = (_x - difW / 2) * scaleW;
      w = _w * scaleW;
      if (_x < difW / 2) {
        w -= (difW / 2 - _x) * scaleW;
      }
      y = _y * scaleH;
      h = _h * scaleH;
    } else {
      scaleH = screenW / previewW * previewH;
      scaleW = screenW;
      final difH = (scaleH - screenH) / scaleH;
      x = _x * scaleW;
      w = _w * scaleW;
      y = (_y - difH / 2) * scaleH;
      h = _h * scaleH;
      if (_y < difH / 2) {
        h -= (difH / 2 - _y) * scaleH;
      }
    }
    return <dynamic>[
      x,
      y,
      w,
      h,
      box['detectedClass'],
      box['confidenceInClass'],
    ];
  }
}
