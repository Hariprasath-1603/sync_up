import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../core/services/reel_service.dart';
import '../../../core/services/video_service.dart';
import '../../../core/theme.dart';

/// Upload Reel Page
///
/// Allows users to:
/// 1. Pick a video from gallery or record new video
/// 2. Preview the selected video
/// 3. Add caption
/// 4. Upload reel with progress indicator
/// 5. View preview after upload
class UploadReelPage extends StatefulWidget {
  const UploadReelPage({super.key});

  @override
  State<UploadReelPage> createState() => _UploadReelPageState();
}

class _UploadReelPageState extends State<UploadReelPage> {
  final ImagePicker _picker = ImagePicker();
  final ReelService _reelService = ReelService();
  final TextEditingController _captionController = TextEditingController();

  File? _videoFile;
  VideoPlayerController? _videoController;
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String _statusMessage = '';

  @override
  void dispose() {
    _videoController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kDarkBackground : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? kDarkBackground : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Upload Reel',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_videoFile != null && !_isLoading)
            TextButton(
              onPressed: _uploadReel,
              child: Text(
                'Upload',
                style: TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _videoFile == null
          ? _buildVideoSourceSelector(isDark)
          : _buildVideoPreviewAndCaption(isDark),
    );
  }

  /// Video source selector (Camera or Gallery)
  Widget _buildVideoSourceSelector(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_rounded,
            size: 100,
            color: kPrimary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Select a Video',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Choose a video from your gallery\nor record a new one',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 48),
          // Gallery Button
          _buildSourceButton(
            icon: Icons.photo_library_rounded,
            label: 'Choose from Gallery',
            onTap: () => _pickVideo(ImageSource.gallery),
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          // Camera Button
          _buildSourceButton(
            icon: Icons.videocam_rounded,
            label: 'Record Video',
            onTap: () => _pickVideo(ImageSource.camera),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  /// Build source button (Gallery or Camera)
  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary, kPrimary.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
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

  /// Video preview and caption input
  Widget _buildVideoPreviewAndCaption(bool isDark) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Video Preview
              AspectRatio(
                aspectRatio: 9 / 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        _videoController != null &&
                            _videoController!.value.isInitialized
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoPlayer(_videoController!),
                              // Play/Pause button
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_videoController!.value.isPlaying) {
                                      _videoController!.pause();
                                    } else {
                                      _videoController!.play();
                                    }
                                  });
                                },
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _videoController!.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Change Video Button
              if (!_isLoading)
                OutlinedButton.icon(
                  onPressed: () => _pickVideo(ImageSource.gallery),
                  icon: const Icon(Icons.video_library_rounded),
                  label: const Text('Change Video'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: kPrimary),
                    foregroundColor: kPrimary,
                  ),
                ),
              const SizedBox(height: 24),
              // Caption Input
              Text(
                'Add Caption',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _captionController,
                maxLines: 3,
                maxLength: 500,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Write a caption for your reel...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: isDark ? kDarkBackground : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterText: '${_captionController.text.length}/500',
                ),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 100), // Space for upload button
            ],
          ),
        ),
        // Upload Progress Overlay
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? kDarkBackground : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Pick video from gallery or camera
  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 1), // Max 60 seconds
      );

      if (pickedFile != null) {
        final videoFile = File(pickedFile.path);

        // Validate video
        setState(() {
          _statusMessage = 'Validating video...';
          _isLoading = true;
        });

        final isValid = await VideoService.validateVideo(videoFile.path);

        setState(() {
          _isLoading = false;
        });

        if (!isValid) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Invalid video. Please select a video under 60 seconds and 100MB.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Initialize video controller
        final controller = VideoPlayerController.file(videoFile);
        await controller.initialize();
        controller.setLooping(true);

        setState(() {
          _videoFile = videoFile;
          _videoController = controller;
        });

        // Auto play
        _videoController?.play();
      }
    } catch (e) {
      debugPrint('❌ Error picking video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Upload reel to Supabase
  Future<void> _uploadReel() async {
    if (_videoFile == null) return;

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
      _statusMessage = 'Starting upload...';
    });

    // Show loading dialog with 15-second timeout
    final loadingCompleter = Future<void>.delayed(const Duration(seconds: 15));

    try {
      final caption = _captionController.text.trim();

      // Upload with progress callback
      final reel = await _reelService.uploadReel(
        videoFile: _videoFile!,
        caption: caption.isNotEmpty ? caption : null,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
              if (progress < 0.3) {
                _statusMessage = 'Preparing video...';
              } else if (progress < 0.6) {
                _statusMessage = 'Uploading video...';
              } else if (progress < 0.8) {
                _statusMessage = 'Uploading thumbnail...';
              } else {
                _statusMessage = 'Finalizing...';
              }
            });
          }
        },
      );

      // Wait for either upload to complete or timeout
      await Future.any([Future.value(reel), loadingCompleter]);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Reel uploaded successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back to previous screen
        Navigator.of(context).pop(reel);
      }
    } catch (e) {
      debugPrint('❌ Error uploading reel: $e');

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Upload failed: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // Ensure loader is hidden after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
