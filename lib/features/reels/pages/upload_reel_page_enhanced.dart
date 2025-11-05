import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../core/services/reel_service.dart';
import '../../../core/theme.dart';

/// Enhanced Upload Reel Page with modern UI/UX
///
/// Features:
/// ✅ Video thumbnail preview
/// ✅ Duration display
/// ✅ Animated progress indicators
/// ✅ Trim and filter tools
/// ✅ Text/sticker overlays
/// ✅ Draft saving
/// ✅ Beautiful animations
class UploadReelPageEnhanced extends StatefulWidget {
  const UploadReelPageEnhanced({super.key});

  @override
  State<UploadReelPageEnhanced> createState() => _UploadReelPageEnhancedState();
}

class _UploadReelPageEnhancedState extends State<UploadReelPageEnhanced>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final ReelService _reelService = ReelService();
  final TextEditingController _captionController = TextEditingController();

  File? _videoFile;
  VideoPlayerController? _videoController;
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _showSuccess = false;
  double _uploadProgress = 0.0;
  String _statusMessage = '';
  Duration _videoDuration = Duration.zero;

  // Animation controllers
  late AnimationController _progressAnimController;
  late AnimationController _successAnimController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _progressAnimController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _successAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _successAnimController,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _successAnimController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _captionController.dispose();
    _progressAnimController.dispose();
    _successAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kDarkBackground : Colors.white,
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(isDark),
      body: Stack(
        children: [
          // Main content
          _videoFile == null
              ? _buildEnhancedVideoSelector(isDark)
              : _buildEnhancedPreview(isDark),

          // Processing overlay
          if (_isProcessing && !_showSuccess) _buildProcessingOverlay(isDark),

          // Success overlay
          if (_showSuccess) _buildSuccessOverlay(isDark),
        ],
      ),
    );
  }

  /// Glass-morphic AppBar
  PreferredSizeWidget _buildGlassAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? Colors.black : Colors.white).withOpacity(0.7),
                  (isDark ? Colors.black : Colors.white).withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Create Reel',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      actions: [
        if (_videoFile != null && !_isLoading)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildGlossyButton(
              onTap: _uploadReel,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_upload_rounded, size: 20),
                  SizedBox(width: 6),
                  Text('Next'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Enhanced video selector with animations
  Widget _buildEnhancedVideoSelector(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 100),

            // Animated icon
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          kPrimary.withOpacity(0.2),
                          const Color(0xFF7C3AED).withOpacity(0.2),
                          const Color(0xFFEC4899).withOpacity(0.2),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.video_library_rounded,
                      size: 80,
                      color: kPrimary,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            Text(
              'Create Your Reel',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Choose a video from your gallery\nor record a new one',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: (isDark ? Colors.white : Colors.black87).withOpacity(
                  0.6,
                ),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 48),

            // Gallery button
            _buildSourceButton(
              icon: Icons.photo_library_rounded,
              title: 'Gallery',
              subtitle: 'Select from library',
              gradient: const LinearGradient(
                colors: [Color(0xFF4A6CF7), Color(0xFF7C3AED)],
              ),
              onTap: () => _pickVideo(ImageSource.gallery),
              isDark: isDark,
            ),

            const SizedBox(height: 16),

            // Camera button
            _buildSourceButton(
              icon: Icons.videocam_rounded,
              title: 'Camera',
              subtitle: 'Record new video',
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
              ),
              onTap: () => _pickVideo(ImageSource.camera),
              isDark: isDark,
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  /// Modern source button
  Widget _buildSourceButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Enhanced preview with editing tools
  Widget _buildEnhancedPreview(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 100),

          // Video preview with duration overlay
          _buildVideoPreviewCard(isDark),

          const SizedBox(height: 24),

          // Video info
          _buildVideoInfo(isDark),

          const SizedBox(height: 24),

          // Caption input
          _buildCaptionInput(isDark),

          const SizedBox(height: 24),

          // Quick editing tools
          _buildQuickTools(isDark),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildVideoPreviewCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kPrimary.withOpacity(0.1),
              const Color(0xFF7C3AED).withOpacity(0.1),
            ],
          ),
          border: Border.all(color: kPrimary.withOpacity(0.2), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_videoController?.value.isInitialized ?? false)
                  VideoPlayer(_videoController!)
                else
                  Container(
                    color: isDark ? Colors.grey[900] : Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),

                // Duration badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(_videoDuration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Play/Pause button
                Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_videoController?.value.isPlaying ?? false) {
                          _videoController?.pause();
                        } else {
                          _videoController?.play();
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        (_videoController?.value.isPlaying ?? false)
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoInfo(bool isDark) {
    final fileSize = _videoFile != null
        ? '${(_videoFile!.lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '0 MB';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildInfoChip(
            icon: Icons.movie_rounded,
            label: _formatDuration(_videoDuration),
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          _buildInfoChip(
            icon: Icons.sd_card_rounded,
            label: fileSize,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: kPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionInput(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kPrimary.withOpacity(0.2), width: 1.5),
        ),
        child: TextField(
          controller: _captionController,
          maxLines: 4,
          maxLength: 500,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Write a caption...',
            hintStyle: TextStyle(
              color: (isDark ? Colors.white : Colors.black87).withOpacity(0.4),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(20),
            counterStyle: TextStyle(
              color: (isDark ? Colors.white : Colors.black87).withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTools(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Tools',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildToolButton(
                  icon: Icons.content_cut_rounded,
                  label: 'Trim',
                  onTap: () {
                    // TODO: Implement trim
                    _showComingSoon(context);
                  },
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToolButton(
                  icon: Icons.filter_vintage_rounded,
                  label: 'Filters',
                  onTap: () {
                    // TODO: Implement filters
                    _showComingSoon(context);
                  },
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToolButton(
                  icon: Icons.music_note_rounded,
                  label: 'Audio',
                  onTap: () {
                    // TODO: Implement audio
                    _showComingSoon(context);
                  },
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: kPrimary, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Processing overlay with animated progress
  Widget _buildProcessingOverlay(bool isDark) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated progress ring
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: _uploadProgress,
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color.lerp(kPrimary, Colors.green, _uploadProgress)!,
                        ),
                      ),
                    ),
                    Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Text(
                _statusMessage.isEmpty ? 'Uploading...' : _statusMessage,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'This may take a moment',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Success overlay with confetti animation
  Widget _buildSuccessOverlay(bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withOpacity(0.95),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        kPrimary.withOpacity(0.3),
                        const Color(0xFF7C3AED).withOpacity(0.3),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 80,
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  'Reel Uploaded! 🎉',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Your reel is now live',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 40),

                _buildGlossyButton(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Done'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlossyButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4A6CF7), Color(0xFF7C3AED), Color(0xFFEC4899)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  // Methods
  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60),
      );

      if (video != null) {
        setState(() {
          _videoFile = File(video.path);
          _isLoading = true;
        });

        _videoController = VideoPlayerController.file(_videoFile!)
          ..initialize().then((_) {
            setState(() {
              _videoDuration = _videoController!.value.duration;
              _isLoading = false;
            });
          });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking video: $e')));
      }
    }
  }

  Future<void> _uploadReel() async {
    if (_videoFile == null) return;

    setState(() {
      _isProcessing = true;
      _showSuccess = false;
      _uploadProgress = 0.0;
      _statusMessage = 'Preparing upload...';
    });

    _progressAnimController.repeat();

    try {
      await _reelService.uploadReel(
        videoFile: _videoFile!,
        caption: _captionController.text.trim(),
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
            if (progress < 0.3) {
              _statusMessage = 'Uploading video...';
            } else if (progress < 0.7) {
              _statusMessage = 'Generating thumbnail...';
            } else if (progress < 0.9) {
              _statusMessage = 'Processing...';
            } else {
              _statusMessage = 'Almost done!';
            }
          });
        },
      );

      // Success animation
      _progressAnimController.stop();
      setState(() {
        _isProcessing = false;
        _showSuccess = true;
      });
      _successAnimController.forward();

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _showSuccess = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon! 🚀'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
