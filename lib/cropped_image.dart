import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ImageCropDetails {
  final ui.Image image;
  final Rect cropRect;
  final Color bgColor;
  ImageCropDetails({@required this.image, @required this.cropRect, @required this.bgColor});
}

class CroppedImage extends StatelessWidget {
  final ImageCropDetails cropDetails;
  CroppedImage(this.cropDetails);

  @override
  Widget build(BuildContext context) => cropDetails == null
      ? Container()
      : Container(
          color: cropDetails.bgColor,
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.all(10),
            child: AspectRatio(
              aspectRatio: cropDetails.cropRect.width / cropDetails.cropRect.height,
              child: CustomPaint(
                painter: CroppedImagePainter(cropDetails),
                child: Container(), // cause CustomPaint to take up entire available space
              ),
            ),
          ),
        );
}

class CroppedImagePainter extends CustomPainter {
  final ImageCropDetails crop;
  CroppedImagePainter(this.crop) : assert(crop != null);

  @override
  void paint(Canvas canvas, Size size) => canvas.drawImageRect(crop.image, crop.cropRect, Offset.zero & size, Paint());

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
