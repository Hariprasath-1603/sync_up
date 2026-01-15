import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import '../config/supabase_config.dart';

/// Supabase Storage Service - File Upload Management
/// 
/// Handles all file upload operations to Supabase Storage buckets.
/// Provides type-safe methods for uploading different content types.
/// 
/// Supported Content Types:
/// - Profile Photos (avatars)
/// - Cover Photos (profile banners)
/// - Post Media (images/videos)
/// - Story Media (24-hour content)
/// - Reel Videos (short-form vertical videos)
/// 
/// Features:
/// - Automatic file naming with timestamps
/// - User-specific folder organization
/// - Public URL generation
/// - Cache control headers
/// - Upsert support (replace existing files)
/// - File extension preservation
/// - Comprehensive error handling
/// 
/// Storage Structure:
/// ```
/// profile-photos/
///   └── {userId}.jpg
/// posts/
///   └── {userId}/
///       └── {timestamp}.{ext}
/// stories/
///   └── {userId}/
///       └── {timestamp}.{ext}
/// reels/
///   └── {userId}/
///       └── {timestamp}.mp4
/// ```
/// 
/// Usage Example:
/// ```dart
/// final service = SupabaseStorageService();
/// final url = await service.uploadProfilePhoto(imageFile, userId);
/// if (url != null) {
///   // Update user profile with new photo URL
/// }
/// ```
/// 
/// Note: All methods return null on failure and log errors for debugging.
/// Always check for null before using returned URLs.
class SupabaseStorageService {
  /// Singleton Supabase storage client
  /// Provides access to all storage buckets configured in Supabase
  static final _storage = Supabase.instance.client.storage;

  /// Upload Profile Photo to Supabase Storage
  /// 
  /// Uploads a user's profile picture (avatar) to the profile-photos bucket.
  /// Each user has exactly one profile photo identified by their userId.
  /// 
  /// Implementation Details:
  /// - Files are named using userId to ensure uniqueness
  /// - Uses .jpg extension for consistency
  /// - Upsert mode enabled: automatically replaces old profile photo
  /// - 1-hour cache control for CDN optimization
  /// - Returns public URL for immediate use
  /// 
  /// Parameters:
  ///   [imageFile] - The image file to upload (should be pre-processed/cropped)
  ///   [userId] - Unique identifier for the user (from Supabase auth)
  /// 
  /// Returns:
  ///   - Public URL string if successful
  ///   - null if upload fails (check console logs for errors)
  /// 
  /// Example:
  /// ```dart
  /// final url = await SupabaseStorageService.uploadProfilePhoto(
  ///   croppedImage,
  ///   currentUser.uid
  /// );
  /// if (url != null) {
  ///   await databaseService.updateUserProfilePhoto(userId, url);
  /// }
  /// ```
  static Future<String?> uploadProfilePhoto(
    File imageFile,
    String userId,
  ) async {
    try {
      final fileName = '$userId.jpg';
      final bytes = await imageFile.readAsBytes();

      print('DEBUG: Uploading profile photo for user: $userId');

      // Upload to Supabase Storage
      await _storage
          .from(SupabaseConfig.profilePhotosBucket)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true, // Replace existing photo
            ),
          );

      // Get public URL
      final publicUrl = _storage
          .from(SupabaseConfig.profilePhotosBucket)
          .getPublicUrl(fileName);

      print('DEBUG: Profile photo uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('ERROR: Supabase profile photo upload failed: $e');
      return null;
    }
  }

  /// Upload Post Media (Image or Video)
  /// 
  /// Uploads media files for regular posts to the posts bucket.
  /// Files are organized in user-specific folders for easy management.
  /// 
  /// Implementation Details:
  /// - Uses timestamp-based naming to prevent conflicts
  /// - Preserves original file extension (.jpg, .png, .mp4, etc.)
  /// - Files stored in user folders: posts/{userId}/{timestamp}.{ext}
  /// - 1-hour cache control for CDN
  /// - Supports both images and videos
  /// 
  /// Parameters:
  ///   [file] - The media file to upload
  ///   [userId] - User ID for folder organization
  /// 
  /// Returns:
  ///   - Public URL if successful
  ///   - null on failure
  /// 
  /// Example:
  /// ```dart
  /// final mediaUrl = await SupabaseStorageService.uploadPost(
  ///   mediaFile,
  ///   currentUser.uid
  /// );
  /// ```
  static Future<String?> uploadPost(File file, String userId) async {
    try {
      final extension = path.extension(file.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
      final filePath = '$userId/$fileName';
      final bytes = await file.readAsBytes();

      print('DEBUG: Uploading post for user: $userId');

      await _storage
          .from(SupabaseConfig.postsBucket)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600'),
          );

      final publicUrl = _storage
          .from(SupabaseConfig.postsBucket)
          .getPublicUrl(filePath);

      print('DEBUG: Post uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('ERROR: Supabase post upload failed: $e');
      return null;
    }
  }

  /// Upload Story Media (Image or Video)
  /// 
  /// Uploads media files for 24-hour stories to the stories bucket.
  /// Stories are temporary content that expires after 24 hours.
  /// 
  /// Implementation Details:
  /// - Similar structure to posts but in dedicated stories bucket
  /// - Timestamp-based naming for unique identification
  /// - User-specific folders for organization
  /// - Files can be manually deleted after 24 hours via cleanup job
  /// 
  /// Parameters:
  ///   [file] - The story media file to upload
  ///   [userId] - User ID for folder organization
  /// 
  /// Returns:
  ///   - Public URL if successful
  ///   - null on failure
  /// 
  /// Note: Consider implementing a background cleanup service to delete
  /// expired stories and free up storage space.
  static Future<String?> uploadStory(File file, String userId) async {
    try {
      final extension = path.extension(file.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
      final filePath = '$userId/$fileName';
      final bytes = await file.readAsBytes();

      print('DEBUG: Uploading story for user: $userId');

      await _storage
          .from(SupabaseConfig.storiesBucket)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600'),
          );

      final publicUrl = _storage
          .from(SupabaseConfig.storiesBucket)
          .getPublicUrl(filePath);

      print('DEBUG: Story uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('ERROR: Supabase story upload failed: $e');
      return null;
    }
  }

  /// Delete file from storage
  static Future<bool> deleteFile(String bucket, String filePath) async {
    try {
      await _storage.from(bucket).remove([filePath]);
      print('DEBUG: File deleted successfully: $filePath');
      return true;
    } catch (e) {
      print('ERROR: Delete failed: $e');
      return false;
    }
  }

  /// Delete profile photo
  static Future<bool> deleteProfilePhoto(String userId) async {
    return await deleteFile(SupabaseConfig.profilePhotosBucket, '$userId.jpg');
  }

  /// Upload cover photo
  /// Returns the public URL of the uploaded image
  static Future<String?> uploadCoverPhoto(File imageFile, String userId) async {
    try {
      final fileName = '${userId}_cover.jpg';
      final bytes = await imageFile.readAsBytes();

      print('DEBUG: Uploading cover photo for user: $userId');

      // Upload to Supabase Storage
      await _storage
          .from(SupabaseConfig.coverPhotosBucket)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true, // Replace existing cover photo
            ),
          );

      // Get public URL
      final publicUrl = _storage
          .from(SupabaseConfig.coverPhotosBucket)
          .getPublicUrl(fileName);

      print('DEBUG: Cover photo uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('ERROR: Supabase cover photo upload failed: $e');
      return null;
    }
  }

  /// Delete cover photo
  static Future<bool> deleteCoverPhoto(String userId) async {
    return await deleteFile(
      SupabaseConfig.coverPhotosBucket,
      '${userId}_cover.jpg',
    );
  }
}
