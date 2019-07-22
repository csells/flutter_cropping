import 'package:flutter/material.dart';
import 'cropped_image.dart';
import 'image_cropper.dart';

class ImageBeforeAfterCrop extends StatefulWidget {
  final ImageProvider image;
  ImageBeforeAfterCrop(this.image);

  @override
  _ImageBeforeAfterCropState createState() => _ImageBeforeAfterCropState();
}

class _ImageBeforeAfterCropState extends State<ImageBeforeAfterCrop> {
  ImageCropDetails _cropDetails;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: ImageCropper(widget.image, onImageCrop)),
          Expanded(child: CroppedImage(_cropDetails)),
        ],
      );

  void onImageCrop(ImageCropDetails cropDetails) => setState(() => _cropDetails = cropDetails);
}
