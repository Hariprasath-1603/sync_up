import 'package:flutter/material.dart';

/// Placeholder for Create Reel feature
/// The full implementation with camera and video editing is in:
/// - reel_camera_page.dart.disabled
/// - reel_editing_page.dart.disabled
///
/// To enable:
/// 1. Ensure camera and video_player packages are properly installed
/// 2. Rename .disabled files back to .dart
/// 3. Add platform-specific permissions in AndroidManifest.xml and Info.plist
class CreateReelPlaceholder extends StatelessWidget {
  const CreateReelPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E13) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0B0E13) : Colors.white,
        title: Text(
          'Create Reel',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam_rounded,
                size: 100,
                color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey,
              ),
              const SizedBox(height: 24),
              Text(
                'Create Reel Feature',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Coming Soon!',
                style: TextStyle(
                  fontSize: 18,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Full camera and video editing features are being prepared.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1D24)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Ready Features:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      '• Camera recording with speed controls',
                      isDark,
                    ),
                    _buildFeatureItem('• Video trimming and editing', isDark),
                    _buildFeatureItem('• Text and sticker overlays', isDark),
                    _buildFeatureItem('• Filters and effects', isDark),
                    _buildFeatureItem('• Audio track selection', isDark),
                    _buildFeatureItem('• Preview and publishing', isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white70 : Colors.grey.shade700,
        ),
      ),
    );
  }
}
