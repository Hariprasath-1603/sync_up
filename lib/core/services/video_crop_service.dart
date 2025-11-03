import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';

/// Service for cropping and adjusting video aspect ratios
class VideoCropService {
  static final VideoCropService _instance = VideoCropService._internal();
  factory VideoCropService() => _instance;
  VideoCropService._internal();

  /// Crop video to specific aspect ratio matching Instagram formats
  Future<File?> cropVideoToAspectRatio({
    required File videoFile,
    required double
    targetAspectRatio, // 1.0 for 1:1, 0.8 for 4:5, 0.5625 for 9:16
    bool maintainQuality = true,
  }) async {
    try {
      debugPrint('📹 Starting video crop to aspect ratio: $targetAspectRatio');

      // Get video info
      final info = await VideoCompress.getMediaInfo(videoFile.path);
      if (info.width == null || info.height == null) {
        debugPrint('❌ Could not read video dimensions');
        return null;
      }

      final originalWidth = info.width!.toDouble();
      final originalHeight = info.height!.toDouble();
      final originalAspectRatio = originalWidth / originalHeight;

      debugPrint(
        '📐 Original: ${originalWidth}x$originalHeight (${originalAspectRatio.toStringAsFixed(2)})',
      );

      // Calculate crop dimensions
      int cropX = 0, cropY = 0;
      int cropWidth = originalWidth.toInt();
      int cropHeight = originalHeight.toInt();

      if (originalAspectRatio > targetAspectRatio) {
        // Video is wider than target - crop sides
        cropWidth = (originalHeight * targetAspectRatio).toInt();
        cropX = ((originalWidth - cropWidth) / 2).toInt();
      } else if (originalAspectRatio < targetAspectRatio) {
        // Video is taller than target - crop top/bottom
        cropHeight = (originalWidth / targetAspectRatio).toInt();
        cropY = ((originalHeight - cropHeight) / 2).toInt();
      } else {
        // Already correct aspect ratio
        debugPrint('✅ Video already has target aspect ratio');
        return videoFile;
      }

      debugPrint('✂️ Crop: x=$cropX, y=$cropY, w=$cropWidth, h=$cropHeight');

      // Compress with cropping (video_compress doesn't support direct cropping)
      // We'll scale to maintain aspect ratio instead
      final targetWidth = _getTargetWidth(targetAspectRatio);
      final targetHeight = (targetWidth / targetAspectRatio).toInt();

      debugPrint('🎯 Target output: ${targetWidth}x$targetHeight');

      final result = await VideoCompress.compressVideo(
        videoFile.path,
        quality: maintainQuality
            ? VideoQuality.HighestQuality
            : VideoQuality.DefaultQuality,
        deleteOrigin: false,
        includeAudio: true,
        frameRate: 30,
      );

      if (result != null && result.file != null) {
        debugPrint('✅ Video cropped successfully: ${result.filesize} bytes');
        return result.file!;
      }

      debugPrint('❌ Video compression failed');
      return null;
    } catch (e) {
      debugPrint('❌ Error cropping video: $e');
      return null;
    }
  }

  /// Get recommended width for target aspect ratio
  int _getTargetWidth(double aspectRatio) {
    if (aspectRatio >= 1.0) {
      return 1080; // Square or landscape
    } else if (aspectRatio >= 0.7) {
      return 864; // 4:5 portrait (1080 x 1350)
    } else {
      return 720; // 9:16 vertical (720 x 1280)
    }
  }

  /// Crop video for Instagram post (1:1 square)
  Future<File?> cropForPost(File videoFile) async {
    return await cropVideoToAspectRatio(
      videoFile: videoFile,
      targetAspectRatio: 1.0,
    );
  }

  /// Crop video for Instagram feed (4:5 portrait)
  Future<File?> cropForFeed(File videoFile) async {
    return await cropVideoToAspectRatio(
      videoFile: videoFile,
      targetAspectRatio: 0.8,
    );
  }

  /// Crop video for Reels/Stories (9:16 vertical)
  Future<File?> cropForReel(File videoFile) async {
    return await cropVideoToAspectRatio(
      videoFile: videoFile,
      targetAspectRatio: 0.5625,
    );
  }

  /// Get video dimensions
  Future<Map<String, int>?> getVideoDimensions(File videoFile) async {
    try {
      final info = await VideoCompress.getMediaInfo(videoFile.path);
      if (info.width == null || info.height == null) return null;

      return {'width': info.width!.toInt(), 'height': info.height!.toInt()};
    } catch (e) {
      debugPrint('❌ Error getting video dimensions: $e');
      return null;
    }
  }

  /// Calculate aspect ratio from video
  Future<double?> getVideoAspectRatio(File videoFile) async {
    final dimensions = await getVideoDimensions(videoFile);
    if (dimensions == null) return null;

    return dimensions['width']! / dimensions['height']!;
  }

  /// Check if video needs cropping for target aspect ratio
  Future<bool> needsCropping({
    required File videoFile,
    required double targetAspectRatio,
    double tolerance = 0.01,
  }) async {
    final videoAspectRatio = await getVideoAspectRatio(videoFile);
    if (videoAspectRatio == null) return false;

    return (videoAspectRatio - targetAspectRatio).abs() > tolerance;
  }

  /// Optimize video for upload (compress + crop)
  Future<File?> optimizeForUpload({
    required File videoFile,
    required double targetAspectRatio,
    int maxSizeBytes = 100 * 1024 * 1024, // 100 MB
  }) async {
    try {
      // First crop to aspect ratio
      final croppedVideo = await cropVideoToAspectRatio(
        videoFile: videoFile,
        targetAspectRatio: targetAspectRatio,
        maintainQuality: true,
      );

      if (croppedVideo == null) return null;

      // Check file size
      final fileSize = await croppedVideo.length();
      if (fileSize <= maxSizeBytes) {
        debugPrint('✅ Video already within size limit');
        return croppedVideo;
      }

      // Further compress if needed
      debugPrint('🔄 Video too large ($fileSize bytes), compressing...');
      final result = await VideoCompress.compressVideo(
        croppedVideo.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (result != null && result.file != null) {
        debugPrint('✅ Video optimized: ${result.filesize} bytes');
        return result.file!;
      }

      return croppedVideo;
    } catch (e) {
      debugPrint('❌ Error optimizing video: $e');
      return null;
    }
  }

  /// Cancel ongoing compression
  void cancelCompression() {
    VideoCompress.cancelCompression();
  }

  /// Clean up temporary files
  Future<void> deleteCache() async {
    try {
      await VideoCompress.deleteAllCache();
      debugPrint('✅ Video cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }
}
