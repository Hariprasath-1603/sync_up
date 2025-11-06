import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme.dart';
import 'story_editor_page.dart';

/// Media Selection Page - Choose between camera and gallery
class StoryMediaSelectionPage extends StatefulWidget {
  const StoryMediaSelectionPage({super.key});

  @override
  State<StoryMediaSelectionPage> createState() =>
      _StoryMediaSelectionPageState();
}

class _StoryMediaSelectionPageState extends State<StoryMediaSelectionPage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _openCamera() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        _showPermissionDialog('Camera');
        return;
      }

      // Open camera
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null && mounted) {
        _navigateToEditor(File(photo.path), 'image');
      }
    } catch (e) {
      debugPrint('❌ Error opening camera: $e');
      _showErrorSnackbar('Failed to open camera');
    }
  }

  Future<void> _openGallery() async {
    try {
      // Show picker for both images and videos
      final XFile? media = await _picker.pickMedia();

      if (media != null && mounted) {
        final mediaType =
            media.path.toLowerCase().endsWith('.mp4') ||
                media.path.toLowerCase().endsWith('.mov')
            ? 'video'
            : 'image';
        _navigateToEditor(File(media.path), mediaType);
      }
    } catch (e) {
      debugPrint('❌ Error opening gallery: $e');
      _showErrorSnackbar('Failed to open gallery');
    }
  }

  Future<void> _selectRecentMedia(File file, String mediaType) async {
    try {
      if (mounted) {
        _navigateToEditor(file, mediaType);
      }
    } catch (e) {
      debugPrint('❌ Error selecting media: $e');
      _showErrorSnackbar('Failed to select media');
    }
  }

  void _navigateToEditor(File file, String mediaType) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            StoryEditorPage(mediaFile: file, mediaType: mediaType),
      ),
    );
  }

  void _showPermissionDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(
          'Please grant $permissionName permission in settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kDarkBackground : kLightBackground,
      appBar: AppBar(
        title: const Text(
          'Create Story',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Camera and Gallery Buttons
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    gradient: LinearGradient(
                      colors: [kPrimary, kPrimary.withOpacity(0.7)],
                    ),
                    onTap: _openCamera,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    gradient: LinearGradient(
                      colors: [
                        kPrimary.withOpacity(0.8),
                        kPrimary.withOpacity(0.6),
                      ],
                    ),
                    onTap: _openGallery,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Recent',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                ),
              ],
            ),
          ),

          // Info Text
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_camera_rounded,
                    size: 80,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(
                      0.1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Create Your Story',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Share a moment with your followers',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
