import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../theme.dart';

enum PhotoType { profile, cover }

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoadingDialogVisible = false;

  /// Show bottom sheet to choose image source
  Future<void> showImageSourceBottomSheet({
    required BuildContext context,
    required PhotoType photoType,
    required String userId,
    required Function(String url) onImageUploaded,
    String? currentImageUrl,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                photoType == PhotoType.profile
                    ? 'Update Profile Photo'
                    : 'Update Cover Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              _buildOptionTile(
                context: context,
                icon: Icons.photo_library_rounded,
                title: 'Pick from Gallery',
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndCropImage(
                    context: context,
                    source: ImageSource.gallery,
                    photoType: photoType,
                    userId: userId,
                    onImageUploaded: onImageUploaded,
                  );
                },
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildOptionTile(
                context: context,
                icon: Icons.camera_alt_rounded,
                title: 'Take a Photo',
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndCropImage(
                    context: context,
                    source: ImageSource.camera,
                    photoType: photoType,
                    userId: userId,
                    onImageUploaded: onImageUploaded,
                  );
                },
                isDark: isDark,
              ),
              if (currentImageUrl != null && currentImageUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildOptionTile(
                  context: context,
                  icon: Icons.delete_outline_rounded,
                  title: 'Remove Photo',
                  onTap: () async {
                    Navigator.pop(context);
                    await _removePhoto(
                      context: context,
                      photoType: photoType,
                      userId: userId,
                      onImageUploaded: onImageUploaded,
                    );
                  },
                  isDark: isDark,
                  isDestructive: true,
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withOpacity(0.1)
                    : kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : kPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDestructive
                      ? Colors.red
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) {
    if (!context.mounted || _isLoadingDialogVisible) {
      debugPrint(
        '⚠️ Cannot show loading dialog: mounted=${context.mounted}, visible=$_isLoadingDialogVisible',
      );
      return;
    }

    debugPrint('🔄 Showing loading dialog...');
    _isLoadingDialogVisible = true;
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) {
        debugPrint('✅ Loading dialog built');
        return const Center(child: CircularProgressIndicator(color: kPrimary));
      },
    );
  }

  void _hideLoadingDialog(BuildContext context) {
    if (!_isLoadingDialogVisible) {
      debugPrint('⚠️ Loading dialog already hidden or not visible');
      return;
    }

    debugPrint('🔄 Hiding loading dialog...');
    _isLoadingDialogVisible = false;

    try {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        debugPrint('✅ Loading dialog hidden successfully');
      } else {
        debugPrint('⚠️ Context not mounted, cannot hide dialog');
      }
    } catch (e) {
      debugPrint('❌ Failed to hide loading dialog: $e');
      // If pop fails, try to find and remove any dialogs
      try {
        if (context.mounted) {
          while (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
            debugPrint('✅ Force popped dialog');
            break; // Only pop once
          }
        }
      } catch (e2) {
        debugPrint('❌ Failed to force close dialog: $e2');
      }
    }
  }

  /// Pick image and open cropper
  Future<void> _pickAndCropImage({
    required BuildContext context,
    required ImageSource source,
    required PhotoType photoType,
    required String userId,
    required Function(String url) onImageUploaded,
  }) async {
    try {
      // Pick image (NO loading dialog during picker)
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (pickedFile == null) {
        debugPrint('⚠️ Image picker cancelled by user');
        // Ensure no loading dialog is showing
        _isLoadingDialogVisible = false;
        return;
      }

      debugPrint('✅ Image picked: ${pickedFile.path}');

      // Verify file exists before processing
      final file = File(pickedFile.path);
      if (!file.existsSync()) {
        debugPrint('⚠️ Image file not found: ${pickedFile.path}');
        _isLoadingDialogVisible = false;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image file not found. Please try again.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Crop image (NO loading dialog during crop)
      final croppedFile = await _cropImage(
        context: context,
        imagePath: pickedFile.path,
        photoType: photoType,
      );

      if (croppedFile == null) {
        debugPrint('Image cropper cancelled by user or failed');
        // Ensure no loading dialog is showing
        _isLoadingDialogVisible = false;
        return;
      }

      debugPrint('Image cropped: ${croppedFile.path}');

      // Show loading dialog if context is available
      if (context.mounted) {
        try {
          _showLoadingDialog(context);
          debugPrint('Loading dialog shown');
        } catch (e) {
          debugPrint('⚠️ Could not show loading dialog: $e');
        }
      } else {
        debugPrint('⚠️ Context not mounted, skipping loading dialog');
      }

      // Upload to Supabase - this should ALWAYS happen regardless of context
      debugPrint('🚀 Starting upload to Supabase...');
      String? imageUrl;
      try {
        imageUrl = await _uploadToSupabase(
          croppedFile: croppedFile,
          userId: userId,
          photoType: photoType,
        );
        debugPrint('✅ Upload completed, imageUrl: $imageUrl');
      } catch (uploadError, uploadStackTrace) {
        debugPrint('❌ Upload error: $uploadError');
        debugPrint('Upload stack trace: $uploadStackTrace');
        imageUrl = null;
      }

      // Hide loading dialog
      if (_isLoadingDialogVisible && context.mounted) {
        try {
          _hideLoadingDialog(context);
        } catch (e) {
          debugPrint('⚠️ Error hiding dialog: $e');
          _isLoadingDialogVisible = false;
        }
      } else {
        _isLoadingDialogVisible = false;
      }

      // Handle upload result
      if (imageUrl != null) {
        debugPrint('✅ Upload successful: $imageUrl');

        if (context.mounted) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  photoType == PhotoType.profile
                      ? 'Profile photo updated successfully'
                      : 'Cover photo updated successfully',
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          } catch (e) {
            debugPrint('⚠️ Could not show success snackbar: $e');
          }
        }

        // Call callback AFTER UI updates
        await Future.delayed(const Duration(milliseconds: 100));
        debugPrint('🔄 Calling onImageUploaded callback...');
        try {
          onImageUploaded(imageUrl);
          debugPrint('✅ Callback completed');
        } catch (e) {
          debugPrint('❌ Callback error: $e');
        }
      } else {
        debugPrint('❌ Upload failed - imageUrl is null');
        if (context.mounted) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload photo'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          } catch (e) {
            debugPrint('⚠️ Could not show error snackbar: $e');
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in _pickAndCropImage: $e');
      debugPrint('Stack trace: $stackTrace');

      // CRITICAL: Always try to hide loading dialog on error
      _isLoadingDialogVisible = false; // Force reset flag FIRST

      try {
        if (context.mounted) {
          // Try to pop any open dialogs
          while (Navigator.of(context, rootNavigator: true).canPop()) {
            try {
              Navigator.of(context, rootNavigator: true).pop();
              debugPrint('✅ Popped a dialog during error cleanup');
            } catch (popError) {
              debugPrint('⚠️ Error popping dialog: $popError');
              break;
            }
          }
        }
      } catch (dialogError) {
        debugPrint('❌ Error hiding dialog: $dialogError');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // FINAL SAFETY: Ensure flag is always reset
      debugPrint('🔒 Finally block: Ensuring loading dialog flag is reset');
      _isLoadingDialogVisible = false;
    }
  }

  /// Crop image with appropriate aspect ratio
  Future<CroppedFile?> _cropImage({
    required BuildContext context,
    required String imagePath,
    required PhotoType photoType,
  }) async {
    try {
      debugPrint('Starting crop for image: $imagePath');
      debugPrint('Photo type: $photoType');

      final isProfilePhoto = photoType == PhotoType.profile;

      final result = await ImageCropper().cropImage(
        sourcePath: imagePath,
        compressQuality: 90,
        maxWidth: isProfilePhoto ? 1080 : 1920,
        maxHeight: isProfilePhoto ? 1080 : 1080,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: photoType == PhotoType.profile
                ? 'Crop Profile Photo'
                : 'Crop Cover Photo',
            toolbarColor: kPrimary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: photoType == PhotoType.profile
                ? CropAspectRatioPreset.square
                : CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: isProfilePhoto, // Lock to square for profile
            hideBottomControls: false,
            showCropGrid: !isProfilePhoto, // Hide grid for circular preview
            cropStyle: isProfilePhoto
                ? CropStyle
                      .circle // Circular crop for profile photos
                : CropStyle.rectangle, // Rectangle for cover photos
            activeControlsWidgetColor: kPrimary,
          ),
          IOSUiSettings(
            title: photoType == PhotoType.profile
                ? 'Crop Profile Photo'
                : 'Crop Cover Photo',
            aspectRatioLockEnabled: isProfilePhoto, // Lock square ratio
            cropStyle: isProfilePhoto
                ? CropStyle
                      .circle // Circular crop for profile photos
                : CropStyle.rectangle, // Rectangle for cover photos
          ),
        ],
      );

      debugPrint('Crop result: ${result?.path ?? "null (cancelled)"}');
      return result;
    } catch (e) {
      debugPrint('Error in _cropImage: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Crop error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Upload to Supabase Storage
  Future<String?> _uploadToSupabase({
    required CroppedFile croppedFile,
    required String userId,
    required PhotoType photoType,
  }) async {
    try {
      debugPrint('Reading cropped file...');
      final file = File(croppedFile.path);
      final bytes = await file.readAsBytes();
      debugPrint('File size: ${bytes.length} bytes');

      final bucket = photoType == PhotoType.profile
          ? SupabaseConfig.profilePhotosBucket
          : SupabaseConfig.coverPhotosBucket;
      final path = photoType == PhotoType.profile
          ? '$userId.jpg'
          : '${userId}_cover.jpg';

      debugPrint('Uploading to bucket: $bucket, path: $path');

      // Upload to Supabase Storage
      await _supabase.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      debugPrint('Upload to storage successful');

      // Get public URL
      final url = _supabase.storage.from(bucket).getPublicUrl(path);
      final bustedUrl = '$url?v=${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('Public URL: $bustedUrl');

      // Update users table (NOT profiles table)
      final fieldName = photoType == PhotoType.profile
          ? 'photo_url'
          : 'cover_photo_url';

      debugPrint(
        'Updating users table: $fieldName = $bustedUrl for uid: $userId',
      );
      await _supabase
          .from('users')
          .update({fieldName: bustedUrl})
          .eq('uid', userId);

      debugPrint('Database update successful');
      return bustedUrl;
    } catch (e, stackTrace) {
      debugPrint('Error uploading to Supabase: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Remove photo
  Future<void> _removePhoto({
    required BuildContext context,
    required PhotoType photoType,
    required String userId,
    required Function(String url) onImageUploaded,
  }) async {
    try {
      // Show loading
      _showLoadingDialog(context);

      final bucket = photoType == PhotoType.profile
          ? SupabaseConfig.profilePhotosBucket
          : SupabaseConfig.coverPhotosBucket;
      final path = photoType == PhotoType.profile
          ? '$userId.jpg'
          : '${userId}_cover.jpg';

      // Remove from storage (ignore errors to keep UX smooth)
      try {
        await _supabase.storage.from(bucket).remove([path]);
        debugPrint('Removed $path from $bucket');
      } catch (storageError) {
        debugPrint('Failed to remove $path from $bucket: $storageError');
      }

      // Update database to remove photo reference
      final fieldName = photoType == PhotoType.profile
          ? 'photo_url'
          : 'cover_photo_url';

      await _supabase.from('users').update({fieldName: null}).eq('uid', userId);

      // Hide loading dialog BEFORE callback
      _hideLoadingDialog(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              photoType == PhotoType.profile
                  ? 'Profile photo removed'
                  : 'Cover photo removed',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Call callback AFTER UI updates
      await Future.delayed(const Duration(milliseconds: 100));
      onImageUploaded('');
    } catch (e) {
      debugPrint('❌ Error removing photo: $e');
      _isLoadingDialogVisible = false; // Reset flag

      if (context.mounted) {
        _hideLoadingDialog(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // Ensure flag is reset
      _isLoadingDialogVisible = false;
    }
  }
}
