import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class ImageBlock extends StatefulWidget {
  final ImageProvider image;
  ImageBlock(this.image);

  @override
  _ImageBlockState createState() => _ImageBlockState();
}

class ImageCropDetails {
  ui.Image image;
  Rect rect = Offset.zero & Size.zero;
}

class _ImageBlockState extends State<ImageBlock> {
  ImageCropDetails _crop;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: ImageCropper(widget.image, onImageCrop)),
          Expanded(
            child: CustomPaint(
              painter: CroppedImagePainter(_crop),
              child: Container(), // cause CustomPaint to take up entire available space
            ),
          ),
        ],
      );

  void onImageCrop(ImageCropDetails details) => setState(() => _crop = details);
}

typedef ImageCropCallback = void Function(ImageCropDetails info);

class ImageCropper extends StatefulWidget {
  final ImageProvider imageProvider;
  final ImageCropCallback onCrop;
  ImageCropper(this.imageProvider, this.onCrop);

  @override
  _ImageCropperState createState() => _ImageCropperState();
}

// this would make an excellent extension method...
Rect scaleRect(Rect rect, double scale) =>
    Rect.fromLTWH(rect.left * scale, rect.top * scale, rect.width * scale, rect.height * scale);

class _ImageCropperState extends State<ImageCropper> {
  // static Color _kSelectionRectangleBackground = Color(0x15000000);
  // static Color _kSelectionRectangleBorder = Color(0x80000000);
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
    var paletteGenerator = await PaletteGenerator.fromImage(_image);
    setState(() => _bgColor = paletteGenerator.dominantColor.color);
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
    debugPrint('${_imageKey.currentWidget.runtimeType}');

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
      _cropRect = newRect;
      _boxSizeAtCrop = boxSize;
      _dragRect = null;
      _startDrag = null;
    });

    // scale crop rect, relative to render object box, to be relative to image size
    var ratio = _image.width / boxSize.width;
    assert(ratio == _image.height / boxSize.height); // uniform aspect ratio
    widget.onCrop(
      ImageCropDetails()
        ..image = _image
        ..rect = scaleRect(_cropRect, ratio),
    );
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

class CropRectPainter extends CustomPainter {
  Rect rect;
  Size scaleSize;
  CropRectPainter(this.rect, {this.scaleSize}) : assert(rect != null);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..color = Color(0x80000000);
    var scaledRect = scaleSize == null ? rect : scaleRect(rect, size.width / scaleSize.width);
    canvas.drawRect(scaledRect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// TODO: render this into the correct aspect ratio
class CroppedImagePainter extends CustomPainter {
  final ImageCropDetails crop;
  CroppedImagePainter(this.crop) : assert(crop != null);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    canvas.drawImageRect(crop.image, crop.rect, Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
