import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugDefaultTargetPlatformOverride;
import 'package:path_drawing/path_drawing.dart';

void _desktopInitHack() {
  bool isWeb = identical(0, 0.0);
  if (isWeb) return;

  if (Platform.isMacOS) {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  } else if (Platform.isLinux || Platform.isWindows) {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  } else if (Platform.isFuchsia) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
}

void main() {
  _desktopInitHack();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final title = 'Flutter Bounding Box';
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: title,
        theme: ThemeData(primarySwatch: Colors.blue),
        home: Scaffold(
          appBar: AppBar(title: Text(title)),
          body: BoundingBox(Rect.fromLTWH(10, 10, 100, 100)),
        ),
      );
}

class BoundingBox extends StatefulWidget {
  final Rect initialBounds;
  const BoundingBox(this.initialBounds);

  @override
  _BoundingBoxState createState() => _BoundingBoxState();
}

class _BoundingBoxState extends State<BoundingBox> {
  Rect bounds;

  @override
  initState() {
    super.initState();
    bounds = widget.initialBounds;
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: <Widget>[
          Positioned(
            top: bounds.top,
            left: bounds.left,
            child: Container(
              decoration: BoxDecoration(
                border:
                    DashPathBorder.all(dashArray: CircularIntervalList<double>(<double>[5.0, 2.5])),
              ),
              width: bounds.width,
              height: bounds.height,
            ),
          ),
        ],
      );
}

class DashPathBorder extends Border {
  DashPathBorder({
    @required this.dashArray,
    BorderSide top = BorderSide.none,
    BorderSide left = BorderSide.none,
    BorderSide right = BorderSide.none,
    BorderSide bottom = BorderSide.none,
  }) : super(
          top: top,
          left: left,
          right: right,
          bottom: bottom,
        );

  factory DashPathBorder.all({
    BorderSide borderSide = const BorderSide(),
    @required CircularIntervalList<double> dashArray,
  }) {
    return DashPathBorder(
      dashArray: dashArray,
      top: borderSide,
      right: borderSide,
      left: borderSide,
      bottom: borderSide,
    );
  }
  final CircularIntervalList<double> dashArray;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius borderRadius,
  }) {
    if (isUniform) {
      switch (top.style) {
        case BorderStyle.none:
          return;
        case BorderStyle.solid:
          switch (shape) {
            case BoxShape.circle:
              assert(
                  borderRadius == null, 'A borderRadius can only be given for rectangular boxes.');
              canvas.drawPath(
                dashPath(Path()..addOval(rect), dashArray: dashArray),
                top.toPaint(),
              );
              break;
            case BoxShape.rectangle:
              if (borderRadius != null) {
                final RRect rrect = RRect.fromRectAndRadius(rect, borderRadius.topLeft);
                canvas.drawPath(
                  dashPath(Path()..addRRect(rrect), dashArray: dashArray),
                  top.toPaint(),
                );
                return;
              }
              canvas.drawPath(
                dashPath(Path()..addRect(rect), dashArray: dashArray),
                top.toPaint(),
              );

              break;
          }
          return;
      }
    }

    assert(borderRadius == null, 'A borderRadius can only be given for uniform borders.');
    assert(shape == BoxShape.rectangle, 'A border can only be drawn as a circle if it is uniform.');
  }
}
