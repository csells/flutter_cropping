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
  Size _boxSizeAtCrop;
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
    _image = await _getImage();
    var size = Size(_image.width.toDouble(), _image.height.toDouble());
    var rect = Offset.zero & size;

    var palette = await PaletteGenerator.fromImage(_image, region: rect);
    setState(() => _bgColor = palette.dominantColor.color);

    _crop(rect, size);
  }

  Future<ui.Image> _getImage() async {
    Timer timer;
    final stream = widget.imageProvider.resolve(ImageConfiguration());
    final completer = Completer<ui.Image>();
    ImageStreamListener listener;
    listener = ImageStreamListener((ImageInfo info, _) {
      timer?.cancel();
      stream.removeListener(listener);
      completer.complete(info.image);
    });

    timer = Timer(Duration(seconds: 15), () {
      stream.removeListener(listener);
      completer.completeError(TimeoutException('Timeout loading from ${widget.imageProvider}'));
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
    setState(() {
      _cropRect = rect;
      _boxSizeAtCrop = size;
    });

    // scale crop rect, relative to render object box, to be relative to image size
    var scaleX = _image.width / size.width;
    var scaleY = _image.height / size.height;
    widget.onCrop(ImageCropDetails()
      ..image = _image
      ..rect = scaleRect(_cropRect, scaleX, scaleY)
      ..bgColor = _bgColor);
  }

  @override
  Widget build(BuildContext context) => Container(
        color: _bgColor,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(10),
          // GestureDetector is used to handle the selection rectangle
          child: GestureDetector(
            onPanDown: _onPanDown,
            onPanUpdate: _onPanUpdate,
            onPanCancel: _onPanCancel,
            onPanEnd: _onPanEnd,
            child: CustomPaint(
              foregroundPainter: _dragRect != null
                  ? CropRectPainter(_dragRect)
                  : _cropRect != null
                      ? CropRectPainter(_cropRect, scaleSize: _boxSizeAtCrop)
                      : null,
              child: Image(key: _imageKey, image: widget.imageProvider),
            ),
          ),
        ),
      );
}
