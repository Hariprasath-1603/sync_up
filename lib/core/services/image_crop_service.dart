import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';

/// Service for cropping images to specific aspect ratios
class ImageCropService {
  static final ImageCropService _instance = ImageCropService._internal();
  factory ImageCropService() => _instance;
  ImageCropService._internal();

  /// Crop image to specific aspect ratio with interactive editor
  Future<File?> cropImageToAspectRatio({
    required File imageFile,
    required double aspectRatioX,
    required double aspectRatioY,
    String title = 'Crop Image',
  }) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: CropAspectRatio(
          ratioX: aspectRatioX,
          ratioY: aspectRatioY,
        ),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: title,
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            hideBottomControls: false,
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: title,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        debugPrint('✅ Image cropped successfully');
        return File(croppedFile.path);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error cropping image: $e');
      return null;
    }
  }

  /// Crop image for Instagram post (1:1 square)
  Future<File?> cropForPost(File imageFile) async {
    return await cropImageToAspectRatio(
      imageFile: imageFile,
      aspectRatioX: 1,
      aspectRatioY: 1,
      title: 'Crop for Post',
    );
  }

  /// Crop image for Instagram feed (4:5 portrait)
  Future<File?> cropForFeed(File imageFile) async {
    return await cropImageToAspectRatio(
      imageFile: imageFile,
      aspectRatioX: 4,
      aspectRatioY: 5,
      title: 'Crop for Feed',
    );
  }

  /// Crop image for Reels/Stories (9:16 vertical)
  Future<File?> cropForReel(File imageFile) async {
    return await cropImageToAspectRatio(
      imageFile: imageFile,
      aspectRatioX: 9,
      aspectRatioY: 16,
      title: 'Crop for Reel',
    );
  }

  /// Crop with custom aspect ratio
  Future<File?> cropWithCustomRatio({
    required File imageFile,
    required double aspectRatioX,
    required double aspectRatioY,
    String title = 'Crop Image',
  }) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: CropAspectRatio(
          ratioX: aspectRatioX,
          ratioY: aspectRatioY,
        ),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: title,
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            hideBottomControls: false,
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: title,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error cropping with custom ratio: $e');
      return null;
    }
  }

  /// Free crop (no aspect ratio lock)
  Future<File?> freeCrop({
    required File imageFile,
    String title = 'Crop Image',
  }) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: title,
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
            hideBottomControls: false,
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: title,
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error free cropping: $e');
      return null;
    }
  }
}
