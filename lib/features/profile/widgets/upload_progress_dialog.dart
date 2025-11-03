import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';

/// Enhanced upload progress dialog with preview and actions
class UploadProgressDialog extends StatelessWidget {
  final double progress;
  final String? statusText;
  final bool isComplete;
  final File? previewFile;
  final bool isVideo;
  final VoidCallback? onView;
  final VoidCallback? onDone;

  const UploadProgressDialog({
    super.key,
    required this.progress,
    this.statusText,
    this.isComplete = false,
    this.previewFile,
    this.isVideo = false,
    this.onView,
    this.onDone,
  });

  /// Show upload dialog
  static Future<void> show(
    BuildContext context, {
    required double progress,
    String? statusText,
    bool isComplete = false,
    File? previewFile,
    bool isVideo = false,
    VoidCallback? onView,
    VoidCallback? onDone,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UploadProgressDialog(
        progress: progress,
        statusText: statusText,
        isComplete: isComplete,
        previewFile: previewFile,
        isVideo: isVideo,
        onView: onView,
        onDone: onDone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview or Icon
            if (isComplete && previewFile != null)
              _buildPreview(previewFile!, isVideo, isDark)
            else
              _buildUploadingIcon(isDark),

            const SizedBox(height: 24),

            // Status Text
            Text(
              statusText ??
                  (isComplete
                      ? '${isVideo ? 'Video' : 'Post'} uploaded successfully!'
                      : 'Uploading...'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Progress Bar (only show when uploading)
            if (!isComplete) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kPrimary,
                ),
              ),
            ],

            // Action Buttons (only show when complete)
            if (isComplete) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      label: 'Done',
                      icon: Icons.check_circle,
                      onTap: onDone ?? () => Navigator.pop(context),
                      isPrimary: false,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      label: 'View',
                      icon: Icons.visibility,
                      onTap: onView,
                      isPrimary: true,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(File file, bool isVideo, bool isDark) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.grey[850] : Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                isVideo ? Icons.video_library : Icons.image,
                size: 64,
                color: isDark ? Colors.white24 : Colors.grey[400],
              ),
            ),
            if (isVideo)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingIcon(bool isDark) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kPrimary.withOpacity(0.1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
            ),
          ),
          Icon(
            isVideo ? Icons.videocam : Icons.cloud_upload,
            size: 32,
            color: kPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required bool isPrimary,
    required bool isDark,
  }) {
    return Material(
      color: isPrimary
          ? kPrimary
          : isDark
          ? Colors.grey[800]
          : Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isPrimary
                    ? Colors.white
                    : isDark
                    ? Colors.white
                    : Colors.black87,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isPrimary
                      ? Colors.white
                      : isDark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
