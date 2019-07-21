import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugDefaultTargetPlatformOverride;

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
          body: ImageCropper(AssetImage('images/map.png')),
        ),
      );
}

class ImageCropper extends StatefulWidget {
  final ImageProvider image;
  ImageCropper(this.image);

  @override
  _ImageCropperState createState() => _ImageCropperState();
}

class _ImageCropperState extends State<ImageCropper> {
  static Color _kSelectionRectangleBackground = Color(0x15000000);
  static Color _kSelectionRectangleBorder = Color(0x80000000);
  Color backgroundColor;
  Rect region;
  Rect dragRegion;
  Offset startDrag;
  Offset currentDrag;
  final GlobalKey imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _getBackgroundColor();
  }

  void _getBackgroundColor() async {
    PaletteGenerator paletteGenerator = await PaletteGenerator.fromImageProvider(widget.image);
    setState(() => backgroundColor = paletteGenerator.dominantColor.color);
  }

  // Called when the user starts to drag
  void _onPanDown(DragDownDetails details) {
    var box = imageKey.currentContext.findRenderObject() as RenderBox;
    var localPosition = box.globalToLocal(details.globalPosition);
    setState(() {
      startDrag = localPosition;
      currentDrag = startDrag;
      dragRegion = Rect.fromPoints(startDrag, currentDrag);
    });
  }

  // Called as the user drags
  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      currentDrag += details.delta;
      dragRegion = Rect.fromPoints(startDrag, currentDrag);
    });
  }

  // Called if the drag is canceled (e.g. by rotating the device or switching apps)
  void _onPanCancel() {
    setState(() {
      dragRegion = null;
      startDrag = null;
    });
  }

  // Called when the drag ends
  void _onPanEnd(DragEndDetails details) async {
    Rect newRegion = (Offset.zero & imageKey.currentContext.size).intersect(dragRegion);
    if (newRegion.size.width < 4 && newRegion.size.width < 4) {
      newRegion = Offset.zero & imageKey.currentContext.size;
    }
    setState(() {
      region = newRegion;
      dragRegion = null;
      startDrag = null;
    });
  }

  @override
  Widget build(BuildContext context) => Container(
        color: backgroundColor,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(10),
          // GestureDetector is used to handle the selection rectangle
          child: GestureDetector(
            onPanDown: _onPanDown,
            onPanUpdate: _onPanUpdate,
            onPanCancel: _onPanCancel,
            onPanEnd: _onPanEnd,
            child: Stack(
              children: [
                Image(
                  key: imageKey,
                  image: widget.image,
                ),
                // This is the selection rectangle
                Positioned.fromRect(
                  rect: dragRegion ?? region ?? Rect.zero,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _kSelectionRectangleBackground,
                      border: Border.all(
                        width: 1.0,
                        color: _kSelectionRectangleBorder,
                        style: BorderStyle.solid,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/*
class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
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
*/
