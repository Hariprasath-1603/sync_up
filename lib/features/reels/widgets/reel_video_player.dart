import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Video player widget for reels with auto-play and pause functionality
class ReelVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isCurrentReel;
  final VoidCallback? onVideoEnd;
  final Function(Duration)? onProgressUpdate;

  const ReelVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.isCurrentReel,
    this.onVideoEnd,
    this.onProgressUpdate,
  });

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(ReelVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle play/pause when switching reels
    if (widget.isCurrentReel != oldWidget.isCurrentReel) {
      if (widget.isCurrentReel) {
        _controller.play();
      } else {
        _controller.pause();
      }
    }

    // Reinitialize if video URL changes
    if (widget.videoUrl != oldWidget.videoUrl) {
      _disposeController();
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      debugPrint('🎬 Initializing video: ${widget.videoUrl}');

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      debugPrint('⏳ Waiting for video to initialize...');
      await _controller.initialize();

      if (!mounted) return;

      debugPrint('✅ Video initialized successfully');
      debugPrint('   Duration: ${_controller.value.duration}');
      debugPrint('   Size: ${_controller.value.size}');

      setState(() {
        _isInitialized = true;
        _hasError = false;
      });

      // Set looping
      _controller.setLooping(true);

      // Add listener for progress updates
      _controller.addListener(() {
        if (_controller.value.hasError) {
          debugPrint(
            '❌ Video player error: ${_controller.value.errorDescription}',
          );
          setState(() {
            _hasError = true;
            _errorMessage = _controller.value.errorDescription;
          });
        }

        if (widget.onProgressUpdate != null &&
            _controller.value.isInitialized) {
          widget.onProgressUpdate!(_controller.value.position);
        }
      });

      // Auto-play if this is the current reel
      if (widget.isCurrentReel) {
        debugPrint('▶️ Auto-playing video...');
        await _controller.play();
        debugPrint('✅ Video playing: ${_controller.value.isPlaying}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing video: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _disposeController() {
    _controller.removeListener(() {});
    _controller.pause();
    _controller.dispose();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Handle visibility changes (pause when not visible)
    return VisibilityDetector(
      key: Key('reel_video_${widget.videoUrl}'),
      onVisibilityChanged: (info) {
        if (!mounted || !_isInitialized) return;

        // Pause when less than 50% visible
        if (info.visibleFraction < 0.5) {
          if (_controller.value.isPlaying) {
            _controller.pause();
          }
        } else if (widget.isCurrentReel && !_controller.value.isPlaying) {
          _controller.play();
        }
      },
      child: GestureDetector(
        onTap: _isInitialized ? _togglePlayPause : null,
        onLongPressStart: _isInitialized
            ? (_) {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                }
              }
            : null,
        onLongPressEnd: _isInitialized
            ? (_) {
                if (widget.isCurrentReel && !_controller.value.isPlaying) {
                  _controller.play();
                }
              }
            : null,
        child: Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video player
              if (_isInitialized && !_hasError)
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                )
              else if (_hasError)
                _buildErrorWidget()
              else
                _buildLoadingWidget(),

              // Play/Pause indicator
              if (_isInitialized && !_hasError)
                AnimatedOpacity(
                  opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Video progress indicator
              if (_isInitialized && !_hasError)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: VideoProgressIndicator(
                    _controller,
                    allowScrubbing: false,
                    colors: VideoProgressColors(
                      playedColor: Colors.white,
                      bufferedColor: Colors.white.withOpacity(0.3),
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 8,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isInitialized = false;
                });
                _initializeVideo();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
