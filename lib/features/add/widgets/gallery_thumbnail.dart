import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class GalleryThumbnail extends StatefulWidget {
  final VoidCallback onTap;

  const GalleryThumbnail({super.key, required this.onTap});

  @override
  State<GalleryThumbnail> createState() => _GalleryThumbnailState();
}

class _GalleryThumbnailState extends State<GalleryThumbnail> {
  XFile? _latestMedia;
  // TODO: Add ImagePicker usage for loading media

  @override
  void initState() {
    super.initState();
    _loadLatestMedia();
  }

  Future<void> _loadLatestMedia() async {
    try {
      // Try to get latest image from gallery
      // Note: This is a placeholder - actual implementation would need
      // photo_manager package or similar for gallery access
    } catch (e) {
      // Ignore error
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: _latestMedia != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(File(_latestMedia!.path), fit: BoxFit.cover),
              )
            : const Icon(
                Icons.photo_library_rounded,
                color: Colors.white,
                size: 24,
              ),
      ),
    );
  }
}
