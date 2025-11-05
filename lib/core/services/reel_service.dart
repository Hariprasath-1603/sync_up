import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import '../models/reel_model.dart';
import 'video_service.dart';

/// Reel Service
///
/// Handles all reel-related operations:
/// - Upload reels with video and thumbnail
/// - Delete reels from storage and database
/// - Fetch reels (user reels, feed reels, trending reels)
/// - Like/unlike reels
/// - Record reel views
/// - Generate thumbnails for videos
///
/// Uses Supabase for backend storage and database
class ReelService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _storageBucket = 'reels';
  static const String _tableName = 'reels';
  static const String _likesTableName = 'reel_likes';
  static const String _viewsTableName = 'reel_views';
  static const String _commentsTableName = 'reel_comments';
  static const String _sharesTableName = 'reel_shares';

  // ========================================
  // UPLOAD REEL
  // ========================================

  /// Upload a new reel with video and thumbnail
  ///
  /// Parameters:
  /// - videoFile: The video file to upload
  /// - caption: Optional caption for the reel
  /// - onProgress: Optional callback for upload progress (0.0 to 1.0)
  ///
  /// Returns: ReelModel of the uploaded reel
  ///
  /// Throws: Exception if upload fails
  Future<ReelModel> uploadReel({
    required File videoFile,
    String? caption,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      debugPrint('🎬 Starting reel upload...');

      // Step 1: Generate thumbnail
      debugPrint('🖼️ Generating thumbnail...');
      final thumbnailFile = await _generateThumbnail(videoFile);
      if (thumbnailFile == null) {
        throw Exception('Failed to generate thumbnail');
      }

      // Step 2: Get video duration
      debugPrint('⏱️ Getting video duration...');
      final duration = await VideoService.getVideoDuration(videoFile.path);

      // Step 3: Upload video to Supabase Storage
      debugPrint('☁️ Uploading video to storage...');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final videoPath = '${user.id}/reel_$timestamp.mp4';

      onProgress?.call(0.3); // 30% - video upload started

      final videoUploadResponse = await _supabase.storage
          .from(_storageBucket)
          .upload(
            videoPath,
            videoFile,
            fileOptions: const FileOptions(
              contentType: 'video/mp4',
              upsert: false,
            ),
          );

      debugPrint('✅ Video uploaded: $videoUploadResponse');
      onProgress?.call(0.6); // 60% - video uploaded

      // Step 4: Upload thumbnail to Supabase Storage
      debugPrint('🖼️ Uploading thumbnail to storage...');
      final thumbPath = '${user.id}/thumb_$timestamp.jpg';

      final thumbUploadResponse = await _supabase.storage
          .from(_storageBucket)
          .upload(
            thumbPath,
            thumbnailFile,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      debugPrint('✅ Thumbnail uploaded: $thumbUploadResponse');
      onProgress?.call(0.8); // 80% - thumbnail uploaded

      // Step 5: Get public URLs
      final videoUrl = _supabase.storage
          .from(_storageBucket)
          .getPublicUrl(videoPath);
      final thumbUrl = _supabase.storage
          .from(_storageBucket)
          .getPublicUrl(thumbPath);

      // Step 6: Insert reel metadata into database
      debugPrint('💾 Inserting reel metadata to database...');
      final reelData = CreateReelRequest(
        userId: user.id,
        videoUrl: videoUrl,
        thumbnailUrl: thumbUrl,
        caption: caption,
        duration: duration,
      );

      final response = await _supabase
          .from(_tableName)
          .insert(reelData.toJson())
          .select()
          .single();

      onProgress?.call(1.0); // 100% - complete

      debugPrint('✅ Reel uploaded successfully: ${response['id']}');

      // Clean up temporary thumbnail file
      try {
        await thumbnailFile.delete();
      } catch (e) {
        debugPrint('⚠️ Failed to delete temp thumbnail: $e');
      }

      return ReelModel.fromJson(response);
    } catch (e, stackTrace) {
      debugPrint('❌ Error uploading reel: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Generate thumbnail from video file
  Future<File?> _generateThumbnail(File videoFile) async {
    try {
      // Verify video file exists and is readable
      if (!await videoFile.exists()) {
        debugPrint('❌ Video file does not exist: ${videoFile.path}');
        return null;
      }

      final fileSize = await videoFile.length();
      debugPrint('📹 Video file size: ${fileSize / 1024 / 1024} MB');

      // Wait a moment for file to be fully written (especially after compression)
      await Future.delayed(const Duration(milliseconds: 500));

      final tempDir = await getTemporaryDirectory();

      // Try to generate thumbnail with retry logic
      int attempts = 0;
      const maxAttempts = 3;
      String? thumbnailPath;

      while (attempts < maxAttempts && thumbnailPath == null) {
        attempts++;
        debugPrint('🖼️ Thumbnail generation attempt $attempts/$maxAttempts');

        try {
          thumbnailPath = await VideoThumbnail.thumbnailFile(
            video: videoFile.path,
            thumbnailPath: tempDir.path,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 1080,
            maxHeight: 1920,
            quality: 75,
            timeMs: 1000, // Get frame at 1 second (more reliable than 0)
          );
        } catch (e) {
          debugPrint('⚠️ Attempt $attempts failed: $e');
          if (attempts < maxAttempts) {
            await Future.delayed(
              Duration(seconds: attempts),
            ); // Progressive delay
          }
        }
      }

      if (thumbnailPath == null) {
        debugPrint(
          '❌ Thumbnail generation returned null after $maxAttempts attempts',
        );
        return null;
      }

      final thumbnailFile = File(thumbnailPath);
      if (!await thumbnailFile.exists()) {
        debugPrint('❌ Thumbnail file was not created at: $thumbnailPath');
        return null;
      }

      final thumbSize = await thumbnailFile.length();
      debugPrint('✅ Thumbnail generated: ${thumbSize / 1024} KB');

      return thumbnailFile;
    } catch (e, stackTrace) {
      debugPrint('❌ Error generating thumbnail: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  // ========================================
  // DELETE REEL
  // ========================================

  /// Delete a reel (video, thumbnail, and database entry)
  ///
  /// Parameters:
  /// - reelId: The ID of the reel to delete
  ///
  /// Returns: true if deletion was successful
  ///
  /// Throws: Exception if deletion fails
  Future<bool> deleteReel(String reelId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      debugPrint('🗑️ Deleting reel: $reelId');

      // Step 1: Get reel data to find file paths
      final reelData = await _supabase
          .from(_tableName)
          .select()
          .eq('id', reelId)
          .eq('user_id', user.id)
          .single();

      final videoUrl = reelData['video_url'] as String;
      final thumbnailUrl = reelData['thumbnail_url'] as String?;

      // Step 2: Extract file paths from URLs
      final videoPath = _extractStoragePath(videoUrl);
      final thumbPath = thumbnailUrl != null
          ? _extractStoragePath(thumbnailUrl)
          : null;

      // Step 3: Delete files from storage
      final filesToDelete = <String>[];
      if (videoPath != null) filesToDelete.add(videoPath);
      if (thumbPath != null) filesToDelete.add(thumbPath);

      if (filesToDelete.isNotEmpty) {
        await _supabase.storage.from(_storageBucket).remove(filesToDelete);
        debugPrint('✅ Deleted ${filesToDelete.length} files from storage');
      }

      // Step 4: Delete database entry (cascades to likes and views)
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', reelId)
          .eq('user_id', user.id);

      debugPrint('✅ Reel deleted successfully: $reelId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting reel: $e');
      rethrow;
    }
  }

  /// Extract storage path from public URL
  String? _extractStoragePath(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      // URL format: .../storage/v1/object/public/reels/{user_id}/{filename}
      final bucketIndex = pathSegments.indexOf(_storageBucket);
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        return pathSegments.sublist(bucketIndex + 1).join('/');
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error extracting storage path: $e');
      return null;
    }
  }

  // ========================================
  // FETCH REELS
  // ========================================

  /// Fetch reels for a specific user
  ///
  /// Parameters:
  /// - userId: The user ID to fetch reels for
  /// - limit: Maximum number of reels to fetch (default: 20)
  /// - offset: Number of reels to skip (for pagination)
  ///
  /// Returns: List of ReelModel
  Future<List<ReelModel>> fetchUserReels({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      debugPrint('📥 Fetching reels for user: $userId');

      // Try with foreign key first
      try {
        final response = await _supabase
            .from(_tableName)
            .select('''
              *,
              users!reels_user_id_fkey (
                uid,
                username,
                photo_url,
                full_name
              )
            ''')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        final reels = (response as List)
            .map((json) => _parseReelWithUser(json))
            .toList();

        debugPrint('✅ Fetched ${reels.length} reels');
        return reels;
      } catch (fkError) {
        debugPrint(
          '⚠️ Foreign key constraint missing, fetching without join: $fkError',
        );

        // Fallback: Fetch reels without user join
        final reelsResponse = await _supabase
            .from(_tableName)
            .select('*')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        final reels = <ReelModel>[];

        // Fetch user info once (since all reels are from same user)
        Map<String, dynamic>? userInfo;
        try {
          userInfo = await _supabase
              .from('users')
              .select('uid, username, photo_url, full_name')
              .eq('uid', userId)
              .single();
        } catch (e) {
          debugPrint('⚠️ Could not fetch user $userId: $e');
          userInfo = {
            'uid': userId,
            'username': 'Unknown',
            'photo_url': null,
            'full_name': 'Unknown User',
          };
        }

        for (final reelJson in reelsResponse as List) {
          reelJson['users'] = userInfo;
          reels.add(_parseReelWithUser(reelJson));
        }

        debugPrint('✅ Fetched ${reels.length} reels (fallback mode)');
        return reels;
      }
    } catch (e) {
      debugPrint('❌ Error fetching user reels: $e');
      return [];
    }
  }

  /// Fetch feed reels (for home feed - all reels from followed users)
  ///
  /// Parameters:
  /// - limit: Maximum number of reels to fetch (default: 20)
  /// - offset: Number of reels to skip (for pagination)
  ///
  /// Returns: List of ReelModel
  Future<List<ReelModel>> fetchFeedReels({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      debugPrint('📥 Fetching feed reels...');

      // Try with foreign key first
      try {
        final response = await _supabase
            .from(_tableName)
            .select('''
              *,
              users!reels_user_id_fkey (
                uid,
                username,
                photo_url,
                full_name
              )
            ''')
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        final reels = (response as List)
            .map((json) => _parseReelWithUser(json))
            .toList();

        debugPrint('✅ Fetched ${reels.length} feed reels');
        return reels;
      } catch (fkError) {
        debugPrint(
          '⚠️ Foreign key constraint missing, fetching without join: $fkError',
        );

        // Fallback: Fetch reels without user join
        final reelsResponse = await _supabase
            .from(_tableName)
            .select('*')
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        final reels = <ReelModel>[];
        for (final reelJson in reelsResponse as List) {
          // Fetch user separately for each reel
          final userId = reelJson['user_id'] as String;
          try {
            final userResponse = await _supabase
                .from('users')
                .select('uid, username, photo_url, full_name')
                .eq('uid', userId)
                .single();

            reelJson['users'] = userResponse;
          } catch (e) {
            debugPrint('⚠️ Could not fetch user $userId: $e');
            // Create minimal user object
            reelJson['users'] = {
              'uid': userId,
              'username': 'Unknown',
              'photo_url': null,
              'full_name': 'Unknown User',
            };
          }

          reels.add(_parseReelWithUser(reelJson));
        }

        debugPrint('✅ Fetched ${reels.length} feed reels (fallback mode)');
        return reels;
      }
    } catch (e) {
      debugPrint('❌ Error fetching feed reels: $e');
      return [];
    }
  }

  /// Fetch trending reels (sorted by engagement)
  ///
  /// Parameters:
  /// - limit: Maximum number of reels to fetch (default: 20)
  /// - offset: Number of reels to skip (for pagination)
  ///
  /// Returns: List of ReelModel
  Future<List<ReelModel>> fetchTrendingReels({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      debugPrint('📥 Fetching trending reels...');

      final response = await _supabase
          .from(_tableName)
          .select('''
            *,
            users!reels_user_id_fkey (
              uid,
              username,
              photo_url,
              full_name
            )
          ''')
          .order('likes_count', ascending: false)
          .order('views_count', ascending: false)
          .range(offset, offset + limit - 1);

      final reels = (response as List)
          .map((json) => _parseReelWithUser(json))
          .toList();

      debugPrint('✅ Fetched ${reels.length} trending reels');
      return reels;
    } catch (e) {
      debugPrint('❌ Error fetching trending reels: $e');
      return [];
    }
  }

  /// Parse reel JSON with user information
  ReelModel _parseReelWithUser(Map<String, dynamic> json) {
    final userData = json['users'] as Map<String, dynamic>?;
    return ReelModel.fromJson({
      ...json,
      'username': userData?['username'],
      'user_photo_url': userData?['photo_url'],
      'user_full_name': userData?['full_name'],
    });
  }

  // ========================================
  // LIKE / UNLIKE
  // ========================================

  /// Like a reel
  ///
  /// Parameters:
  /// - reelId: The ID of the reel to like
  ///
  /// Returns: true if like was successful
  Future<bool> likeReel(String reelId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      debugPrint('❤️ Liking reel: $reelId');

      await _supabase.from(_likesTableName).insert({
        'reel_id': reelId,
        'user_id': user.id,
      });

      debugPrint('✅ Reel liked successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error liking reel: $e');
      return false;
    }
  }

  /// Unlike a reel
  ///
  /// Parameters:
  /// - reelId: The ID of the reel to unlike
  ///
  /// Returns: true if unlike was successful
  Future<bool> unlikeReel(String reelId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      debugPrint('💔 Unliking reel: $reelId');

      await _supabase
          .from(_likesTableName)
          .delete()
          .eq('reel_id', reelId)
          .eq('user_id', user.id);

      debugPrint('✅ Reel unliked successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error unliking reel: $e');
      return false;
    }
  }

  /// Check if user has liked a reel
  Future<bool> hasLikedReel(String reelId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from(_likesTableName)
          .select()
          .eq('reel_id', reelId)
          .eq('user_id', user.id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('❌ Error checking like status: $e');
      return false;
    }
  }

  // ========================================
  // VIEWS
  // ========================================

  /// Record a view for a reel
  ///
  /// Parameters:
  /// - reelId: The ID of the reel to record view for
  ///
  /// Returns: true if view was recorded
  Future<bool> recordView(String reelId) async {
    try {
      final user = _supabase.auth.currentUser;

      debugPrint('👁️ Recording view for reel: $reelId');

      // Insert view (will be ignored if already exists due to UNIQUE constraint)
      await _supabase.from(_viewsTableName).insert({
        'reel_id': reelId,
        'user_id': user?.id, // Nullable for anonymous views
      });

      debugPrint('✅ View recorded successfully');
      return true;
    } catch (e) {
      // Ignore duplicate key errors (user already viewed this reel)
      if (e.toString().contains('duplicate') ||
          e.toString().contains('unique')) {
        debugPrint('ℹ️ View already recorded');
        return true;
      }
      debugPrint('❌ Error recording view: $e');
      return false;
    }
  }

  // ========================================
  // UPDATE REEL
  // ========================================

  /// Update reel caption
  ///
  /// Parameters:
  /// - reelId: The ID of the reel to update
  /// - caption: New caption
  ///
  /// Returns: Updated ReelModel
  Future<ReelModel?> updateReelCaption({
    required String reelId,
    required String caption,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      debugPrint('✏️ Updating reel caption: $reelId');

      final response = await _supabase
          .from(_tableName)
          .update({'caption': caption})
          .eq('id', reelId)
          .eq('user_id', user.id)
          .select()
          .single();

      debugPrint('✅ Reel caption updated successfully');
      return ReelModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error updating reel caption: $e');
      return null;
    }
  }

  // ========================================
  // COUNT
  // ========================================

  /// Get total reel count for a user
  Future<int> getUserReelCount(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      debugPrint('❌ Error getting reel count: $e');
      return 0;
    }
  }

  // ========================================
  // COMMENTS
  // ========================================

  /// Add a comment to a reel
  Future<bool> addComment({
    required String reelId,
    required String text,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      debugPrint('💬 Adding comment to reel: $reelId');

      await _supabase.from(_commentsTableName).insert({
        'reel_id': reelId,
        'user_id': user.id,
        'text': text,
      });

      debugPrint('✅ Comment added successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error adding comment: $e');
      return false;
    }
  }

  /// Get comments for a reel
  Future<List<Map<String, dynamic>>> getComments(String reelId) async {
    try {
      debugPrint('📥 Fetching comments for reel: $reelId');

      final response = await _supabase
          .from(_commentsTableName)
          .select('''
            *,
            users!reel_comments_user_id_fkey (
              uid,
              username,
              photo_url,
              full_name
            )
          ''')
          .eq('reel_id', reelId)
          .order('created_at', ascending: false);

      debugPrint('✅ Fetched ${(response as List).length} comments');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching comments: $e');
      return [];
    }
  }

  /// Delete a comment
  Future<bool> deleteComment(String commentId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      debugPrint('🗑️ Deleting comment: $commentId');

      await _supabase
          .from(_commentsTableName)
          .delete()
          .eq('id', commentId)
          .eq('user_id', user.id);

      debugPrint('✅ Comment deleted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting comment: $e');
      return false;
    }
  }

  // ========================================
  // SHARES
  // ========================================

  /// Record a share for a reel
  Future<bool> shareReel({
    required String reelId,
    required String sharedTo, // 'story', 'message', 'external'
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      debugPrint('↗️ Recording share for reel: $reelId');

      await _supabase.from(_sharesTableName).insert({
        'reel_id': reelId,
        'user_id': user.id,
        'shared_to': sharedTo,
      });

      debugPrint('✅ Share recorded successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error recording share: $e');
      return false;
    }
  }
}
