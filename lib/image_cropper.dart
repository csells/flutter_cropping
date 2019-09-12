import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'cropped_image.dart';

typedef ImageCropCallback = void Function(ImageCropDetails info);

class ImageCropper extends StatefulWidget {
  final ImageProvider imageProvider;
  final ImageCropCallback onCrop;
  ImageCropper(this.imageProvider, this.onCrop);

  @override
  _ImageCropperState createState() => _ImageCropperState();
}

class _ImageCropperState extends State<ImageCropper> {
  Color _bgColor;
  ui.Image _image;
  Rect _cropRect;
  Rect _dragRect;
  Offset _startDrag;
  Offset _currentDrag;
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    asyncInit();
  }

  void asyncInit() async {
    var image = await _resolveImage(widget.imageProvider);
    var size = Size(image.width.toDouble(), image.height.toDouble());
    var rect = Offset.zero & size;
    var palette = await PaletteGenerator.fromImage(image, region: rect);

    setState(() {
      _image = image;
      _bgColor = palette.dominantColor.color;
    });

    _crop(rect, size);
  }

  static Future<ui.Image> _resolveImage(ImageProvider provider) {
    Timer timer;
    final stream = provider.resolve(ImageConfiguration());
    final completer = Completer<ui.Image>();
    ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      timer?.cancel();
      stream.removeListener(listener);
      completer.complete(info.image);
    });

    timer = Timer(Duration(seconds: 15), () {
      stream.removeListener(listener);
      completer.completeError(TimeoutException('Timeout loading from $provider'));
    });

    stream.addListener(listener);
    return completer.future;
  }

  // Called when the user starts to drag
  void _onPanDown(DragDownDetails details) {
    var box = _imageKey.currentContext.findRenderObject() as RenderBox;
    var localPosition = box.globalToLocal(details.globalPosition);

    setState(() {
      _startDrag = _currentDrag = localPosition;
      _dragRect = Rect.fromPoints(_startDrag, _currentDrag);
    });
  }

  // Called as the user drags
  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentDrag += details.delta;
      _dragRect = Rect.fromPoints(_startDrag, _currentDrag);
    });
  }

  // Called if the drag is canceled (e.g. by rotating the device or switching apps)
  void _onPanCancel() {
    setState(() {
      _dragRect = null;
      _startDrag = null;
    });
  }

  // Called when the drag ends
  void _onPanEnd(DragEndDetails details) async {
    var boxSize = _imageKey.currentContext.size;
    var newRect = (Offset.zero & boxSize).intersect(_dragRect);
    if (newRect.size.width < 4 && newRect.size.height < 4) {
      newRect = Offset.zero & boxSize;
    }

    setState(() {
      _dragRect = null;
      _startDrag = null;
    });

    _crop(newRect, boxSize);
  }

  void _crop(Rect rect, Size size) {
    setState(() => _cropRect = rect);
    widget.onCrop(ImageCropDetails(image: _image, cropRect: _cropRect, bgColor: _bgColor));
  }

  @override
  Widget build(BuildContext context) => Container(
        color: _bgColor,
        alignment: Alignment.center,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: FittedBox(
            child: GestureDetector(
              onPanDown: _onPanDown,
              onPanUpdate: _onPanUpdate,
              onPanCancel: _onPanCancel,
              onPanEnd: _onPanEnd,
              child: Stack(
                children: [
                  Image(key: _imageKey, image: widget.imageProvider),
                  SelectionRect(dragRect: _dragRect, cropRect: _cropRect),
                ],
              ),
            ),
          ),
        ),
      );
}

class SelectionRect extends StatelessWidget {
  final ui.Rect dragRect;
  final ui.Rect cropRect;

  SelectionRect({
    @required this.dragRect,
    @required this.cropRect,
  });

  @override
  Widget build(BuildContext context) => PositionedRect(dragRect ?? cropRect);
}

class PositionedRect extends StatelessWidget {
  final ui.Rect rect;
  PositionedRect(this.rect);

  @override
  Widget build(BuildContext context) => rect == null
      ? Container()
      : Positioned(
          top: rect.top,
          left: rect.left,
          width: rect.width,
          height: rect.height,
          child: Container(decoration: BoxDecoration(border: Border.all(width: 2))),
        );
}
