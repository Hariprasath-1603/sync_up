import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

/// Service for handling video operations:
/// - Compression
/// - Thumbnail generation
/// - Duration extraction
/// - Validation
class VideoService {
  /// Compress video file
  /// Returns compressed file path or null if failed
  static Future<String?> compressVideo(
    String videoPath, {
    VideoQuality quality = VideoQuality.MediumQuality,
    bool deleteOrigin = false,
    int frameRate = 30,
  }) async {
    try {
      print('🎥 Starting video compression...');

      final MediaInfo? info = await VideoCompress.compressVideo(
        videoPath,
        quality: quality,
        deleteOrigin: deleteOrigin,
        includeAudio: true,
        frameRate: frameRate,
      );

      if (info != null) {
        print('✅ Video compressed successfully');
        print(
          '   Original size: ${File(videoPath).lengthSync() / 1024 / 1024} MB',
        );
        print(
          '   Compressed size: ${info.filesize != null ? info.filesize! / 1024 / 1024 : 0} MB',
        );
        return info.path;
      }

      return null;
    } catch (e) {
      print('❌ Video compression failed: $e');
      return null;
    }
  }

  /// Generate thumbnail from video
  /// Returns thumbnail file path or null if failed
  static Future<String?> generateThumbnail(
    String videoPath, {
    int timeMs = 0,
    int quality = 75,
  }) async {
    try {
      print('📸 Generating video thumbnail...');

      final String? thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 1080,
        maxWidth: 1920,
        timeMs: timeMs,
        quality: quality,
      );

      if (thumbnailPath != null) {
        print('✅ Thumbnail generated: $thumbnailPath');
        return thumbnailPath;
      }

      return null;
    } catch (e) {
      print('❌ Thumbnail generation failed: $e');
      return null;
    }
  }

  /// Get video duration in seconds
  static Future<int> getVideoDuration(String videoPath) async {
    try {
      final VideoPlayerController controller = VideoPlayerController.file(
        File(videoPath),
      );

      await controller.initialize();
      final duration = controller.value.duration.inSeconds;
      await controller.dispose();

      print('⏱️ Video duration: $duration seconds');
      return duration;
    } catch (e) {
      print('❌ Failed to get video duration: $e');
      return 0;
    }
  }

  /// Validate video file
  /// Returns true if valid, false otherwise
  static Future<bool> validateVideo(
    String videoPath, {
    int maxDurationSeconds = 60,
    int maxSizeMB = 100,
  }) async {
    try {
      final File videoFile = File(videoPath);

      // Check if file exists
      if (!await videoFile.exists()) {
        print('❌ Video file does not exist');
        return false;
      }

      // Check file size
      final int fileSizeInBytes = await videoFile.length();
      final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMB > maxSizeMB) {
        print(
          '❌ Video too large: ${fileSizeInMB.toStringAsFixed(2)} MB (max: $maxSizeMB MB)',
        );
        return false;
      }

      // Check duration
      final int duration = await getVideoDuration(videoPath);
      if (duration > maxDurationSeconds) {
        print(
          '❌ Video too long: $duration seconds (max: $maxDurationSeconds seconds)',
        );
        return false;
      }

      // Check file extension
      final String extension = videoPath.split('.').last.toLowerCase();
      if (!['mp4', 'mov', 'webm', 'avi'].contains(extension)) {
        print('❌ Unsupported video format: $extension');
        return false;
      }

      print('✅ Video validation passed');
      return true;
    } catch (e) {
      print('❌ Video validation failed: $e');
      return false;
    }
  }

  /// Get video metadata
  static Future<Map<String, dynamic>> getVideoMetadata(String videoPath) async {
    try {
      final VideoPlayerController controller = VideoPlayerController.file(
        File(videoPath),
      );

      await controller.initialize();

      final metadata = {
        'duration': controller.value.duration.inSeconds,
        'width': controller.value.size.width,
        'height': controller.value.size.height,
        'aspectRatio': controller.value.aspectRatio,
        'file_size': await File(videoPath).length(),
        'format': videoPath.split('.').last.toLowerCase(),
      };

      await controller.dispose();

      print('📊 Video metadata: $metadata');
      return metadata;
    } catch (e) {
      print('❌ Failed to get video metadata: $e');
      return {};
    }
  }

  /// Get thumbnail as Uint8List for preview
  static Future<Uint8List?> getThumbnailData(
    String videoPath, {
    int timeMs = 0,
    int quality = 75,
  }) async {
    try {
      final Uint8List? thumbnailData = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 720,
        maxWidth: 1280,
        timeMs: timeMs,
        quality: quality,
      );

      return thumbnailData;
    } catch (e) {
      print('❌ Failed to get thumbnail data: $e');
      return null;
    }
  }

  /// Cancel video compression
  static void cancelCompression() {
    VideoCompress.cancelCompression();
    print('🛑 Video compression cancelled');
  }

  /// Delete temporary files
  static Future<void> deleteAllCache() async {
    try {
      await VideoCompress.deleteAllCache();
      print('🗑️ Video cache cleared');
    } catch (e) {
      print('❌ Failed to clear video cache: $e');
    }
  }

  /// Subscribe to compression progress
  static Subscription subscribeCompressionProgress(
    void Function(double) onProgress,
  ) {
    return VideoCompress.compressProgress$.subscribe((progress) {
      print('📊 Compression progress: ${progress.toStringAsFixed(2)}%');
      onProgress(progress);
    });
  }
}
