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
              child: Container(), // TODO: needed?
            ),
          ),
        ],
      );

  void onImageCrop(ImageCropDetails details) => setState(() => _crop = details);
}

class CroppedImagePainter extends CustomPainter {
  final ImageCropDetails crop;
  CroppedImagePainter(this.crop) {
    debugPrint('size= ${crop?.image?.width}x${crop?.image?.height}, rect: ${crop?.rect}');
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (crop == null) return;
    var paint = Paint();
    canvas.drawImageRect(crop.image, crop.rect, Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

typedef ImageCropCallback = void Function(ImageCropDetails info);

class ImageCropper extends StatefulWidget {
  final ImageProvider imageProvider;
  final ImageCropCallback onCrop;
  ImageCropper(this.imageProvider, this.onCrop);

  @override
  _ImageCropperState createState() => _ImageCropperState();
}

class _ImageCropperState extends State<ImageCropper> {
  static Color selectionRectangleBackgroundColor = Color(0x15000000);
  static Color selectionRectangleBorderColor = Color(0x80000000);
  Color backgroundColor;
  final crop = ImageCropDetails(); // TODO: how to scale this as the image size scales?
  Rect dragRect;
  Offset startDrag;
  Offset currentDrag;
  final GlobalKey imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    asyncInit();
  }

  void asyncInit() async {
    crop.image = await _getImage();
    var paletteGenerator = await PaletteGenerator.fromImage(crop.image);
    setState(() => backgroundColor = paletteGenerator.dominantColor.color);
  }

  Future<ui.Image> _getImage() async {
    Timer timer;
    final stream = widget.imageProvider.resolve(ImageConfiguration(devicePixelRatio: 1.0));
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
    var box = imageKey.currentContext.findRenderObject() as RenderBox;
    var localPosition = box.globalToLocal(details.globalPosition);
    debugPrint('${imageKey.currentWidget.runtimeType}');

    setState(() {
      startDrag = localPosition;
      currentDrag = startDrag;
      dragRect = Rect.fromPoints(startDrag, currentDrag);
      //crop.size = imageKey.currentContext.size;
    });
  }

  // Called as the user drags
  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      currentDrag += details.delta;
      dragRect = Rect.fromPoints(startDrag, currentDrag);
    });
  }

  // Called if the drag is canceled (e.g. by rotating the device or switching apps)
  void _onPanCancel() {
    setState(() {
      dragRect = null;
      startDrag = null;
    });
  }

  // Called when the drag ends
  void _onPanEnd(DragEndDetails details) async {
    var newRect = (Offset.zero & imageKey.currentContext.size).intersect(dragRect);
    if (newRect.size.width < 4 && newRect.size.height < 4) {
      newRect = Offset.zero & imageKey.currentContext.size;
    }
    setState(() {
      crop.rect = newRect;
      dragRect = null;
      startDrag = null;
    });

    widget.onCrop(crop);
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
                Image(key: imageKey, image: widget.imageProvider),
                // selection rectangle
                Positioned.fromRect(
                  rect: dragRect ?? crop.rect ?? Rect.zero,
                  child: Container(
                    decoration: BoxDecoration(
                      color: selectionRectangleBackgroundColor,
                      border: Border.all(
                        width: 2,
                        color: selectionRectangleBorderColor,
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
