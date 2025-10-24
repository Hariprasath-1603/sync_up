import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import '../config/supabase_config.dart';

/// Service for handling file uploads to Supabase Storage
class SupabaseStorageService {
  static final _storage = Supabase.instance.client.storage;

  /// Upload profile photo
  /// Returns the public URL of the uploaded image
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

  /// Upload post image/video
  /// Returns the public URL of the uploaded file
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

  /// Upload story image/video
  /// Returns the public URL of the uploaded file
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
}
