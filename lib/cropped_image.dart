import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// this would make an excellent extension method...
Rect scaleRect(Rect rect, double scaleX, double scaleY) =>
    Rect.fromLTWH(rect.left * scaleX, rect.top * scaleY, rect.width * scaleX, rect.height * scaleY);

class ImageCropDetails {
  ui.Image image;
  Rect rect = Offset.zero & Size.zero;
  Color bgColor;
}

class CroppedImage extends StatelessWidget {
  final ImageCropDetails cropDetails;
  const CroppedImage(this.cropDetails);

  @override
  Widget build(BuildContext context) => cropDetails == null
      ? Container()
      : Container(
          color: cropDetails.bgColor,
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(10),
            // GestureDetector is used to handle the selection rectangle
            child: AspectRatio(
              aspectRatio: cropDetails.rect.width / cropDetails.rect.height,
              child: CustomPaint(
                painter: CroppedImagePainter(cropDetails),
                child: Container(), // cause CustomPaint to take up entire available space
              ),
            ),
          ),
        );
}

class CropRectPainter extends CustomPainter {
  static Color _kSelectionRectangleBackground = Color(0x15000000);
  static Color _kSelectionRectangleBorder = Color(0x80000000);
  Rect rect;
  Size scaleSize;
  CropRectPainter(this.rect, {this.scaleSize}) : assert(rect != null);

  @override
  void paint(Canvas canvas, Size size) {
    var scaledRect = scaleSize == null
        ? rect
        : scaleRect(rect, size.width / scaleSize.width, size.height / scaleSize.height);
    Paint paint;

    // fill the box
    paint = Paint()
      ..style = PaintingStyle.fill
      ..color = _kSelectionRectangleBackground;
    canvas.drawRect(scaledRect, paint);

    // frame the box
    paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..color = _kSelectionRectangleBorder;
    canvas.drawRect(scaledRect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

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
