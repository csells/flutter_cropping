import 'package:flutter/material.dart';
import 'cropped_image.dart';
import 'image_cropper.dart';

class ImageBlock extends StatefulWidget {
  final ImageProvider image;
  ImageBlock(this.image);

  @override
  _ImageBlockState createState() => _ImageBlockState();
}

class _ImageBlockState extends State<ImageBlock> {
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
