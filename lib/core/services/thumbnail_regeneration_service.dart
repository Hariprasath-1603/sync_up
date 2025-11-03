import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'video_service.dart';
import 'supabase_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Service to regenerate thumbnails for existing video posts
class ThumbnailRegenerationService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Regenerate thumbnails for all video posts without thumbnails
  static Future<Map<String, dynamic>> regenerateAllMissingThumbnails() async {
    try {
      debugPrint('🔄 Starting thumbnail regeneration...');

      // Query all video posts without thumbnails
      final response = await _supabase
          .from('posts')
          .select('id, video_url, user_id, thumbnail_url')
          .eq('media_type', 'video')
          .or('thumbnail_url.is.null,thumbnail_url.eq.');

      if (response.isEmpty) {
        debugPrint('✅ No videos need thumbnail regeneration');
        return {
          'success': true,
          'message': 'No videos need thumbnail regeneration',
          'processed': 0,
          'failed': 0,
        };
      }

      final posts = response as List<dynamic>;
      debugPrint('📊 Found ${posts.length} videos without thumbnails');

      int processed = 0;
      int failed = 0;
      List<String> failedIds = [];

      for (var post in posts) {
        try {
          final postId = post['id'] as String;
          final videoUrl = post['video_url'] as String?;
          final userId = post['user_id'] as String;

          if (videoUrl == null || videoUrl.isEmpty) {
            debugPrint('⚠️ Post $postId has no video URL, skipping');
            failed++;
            failedIds.add(postId);
            continue;
          }

          debugPrint('🔄 Processing post $postId...');

          // Download video temporarily
          final videoFile = await _downloadVideo(videoUrl, postId);
          if (videoFile == null) {
            debugPrint('❌ Failed to download video for post $postId');
            failed++;
            failedIds.add(postId);
            continue;
          }

          // Generate thumbnail
          final thumbnailPath = await VideoService.generateThumbnail(
            videoFile.path,
          );
          if (thumbnailPath == null) {
            debugPrint('❌ Failed to generate thumbnail for post $postId');
            failed++;
            failedIds.add(postId);
            await videoFile.delete();
            continue;
          }

          // Upload thumbnail to Supabase
          final thumbnailFile = File(thumbnailPath);
          final thumbnailUrl = await SupabaseStorageService.uploadPost(
            thumbnailFile,
            userId,
          );

          if (thumbnailUrl == null) {
            debugPrint('❌ Failed to upload thumbnail for post $postId');
            failed++;
            failedIds.add(postId);
            await videoFile.delete();
            await thumbnailFile.delete();
            continue;
          }

          // Update post with thumbnail URL
          await _supabase
              .from('posts')
              .update({'thumbnail_url': thumbnailUrl})
              .eq('id', postId);

          debugPrint('✅ Successfully regenerated thumbnail for post $postId');
          processed++;

          // Cleanup
          await videoFile.delete();
          await thumbnailFile.delete();

          // Add small delay to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          debugPrint('❌ Error processing post ${post['id']}: $e');
          failed++;
          failedIds.add(post['id'] as String);
        }
      }

      final result = {
        'success': true,
        'message': 'Regeneration complete',
        'processed': processed,
        'failed': failed,
        'total': posts.length,
        'failedIds': failedIds,
      };

      debugPrint('✅ Thumbnail regeneration complete: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Fatal error during thumbnail regeneration: $e');
      return {
        'success': false,
        'error': e.toString(),
        'processed': 0,
        'failed': 0,
      };
    }
  }

  /// Regenerate thumbnail for a specific post
  static Future<bool> regenerateThumbnailForPost(String postId) async {
    try {
      debugPrint('🔄 Regenerating thumbnail for post $postId...');

      // Get post data
      final response = await _supabase
          .from('posts')
          .select('video_url, user_id')
          .eq('id', postId)
          .single();

      final videoUrl = response['video_url'] as String?;
      final userId = response['user_id'] as String;

      if (videoUrl == null || videoUrl.isEmpty) {
        debugPrint('⚠️ Post $postId has no video URL');
        return false;
      }

      // Download video temporarily
      final videoFile = await _downloadVideo(videoUrl, postId);
      if (videoFile == null) {
        debugPrint('❌ Failed to download video for post $postId');
        return false;
      }

      // Generate thumbnail
      final thumbnailPath = await VideoService.generateThumbnail(
        videoFile.path,
      );
      if (thumbnailPath == null) {
        debugPrint('❌ Failed to generate thumbnail for post $postId');
        await videoFile.delete();
        return false;
      }

      // Upload thumbnail to Supabase
      final thumbnailFile = File(thumbnailPath);
      final thumbnailUrl = await SupabaseStorageService.uploadPost(
        thumbnailFile,
        userId,
      );

      if (thumbnailUrl == null) {
        debugPrint('❌ Failed to upload thumbnail for post $postId');
        await videoFile.delete();
        await thumbnailFile.delete();
        return false;
      }

      // Update post with thumbnail URL
      await _supabase
          .from('posts')
          .update({'thumbnail_url': thumbnailUrl})
          .eq('id', postId);

      debugPrint('✅ Successfully regenerated thumbnail for post $postId');

      // Cleanup
      await videoFile.delete();
      await thumbnailFile.delete();

      return true;
    } catch (e) {
      debugPrint('❌ Error regenerating thumbnail for post $postId: $e');
      return false;
    }
  }

  /// Download video from URL to temporary file
  static Future<File?> _downloadVideo(String videoUrl, String postId) async {
    try {
      debugPrint('⬇️ Downloading video from $videoUrl...');

      final response = await http.get(Uri.parse(videoUrl));
      if (response.statusCode != 200) {
        debugPrint('❌ Failed to download video: ${response.statusCode}');
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final videoFile = File(
        '${tempDir.path}/video_${postId}_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      await videoFile.writeAsBytes(response.bodyBytes);

      debugPrint('✅ Video downloaded to ${videoFile.path}');
      return videoFile;
    } catch (e) {
      debugPrint('❌ Error downloading video: $e');
      return null;
    }
  }

  /// Check how many videos are missing thumbnails
  static Future<int> countMissingThumbnails() async {
    try {
      final response = await _supabase
          .from('posts')
          .select('id')
          .eq('media_type', 'video')
          .or('thumbnail_url.is.null,thumbnail_url.eq.');

      return response.length;
    } catch (e) {
      debugPrint('❌ Error counting missing thumbnails: $e');
      return 0;
    }
  }
}
