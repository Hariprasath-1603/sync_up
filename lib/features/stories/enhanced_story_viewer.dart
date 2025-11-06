import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme.dart';
import '../../core/services/story_service.dart';
import '../../core/scaffold_with_nav_bar.dart';

/// Enhanced full-screen story viewer with auto-progress, gestures, and modern UI
class EnhancedStoryViewer extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final int initialIndex;
  final String userName;
  final String userAvatar;
  final VoidCallback? onClose;

  const EnhancedStoryViewer({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    required this.userName,
    required this.userAvatar,
    this.onClose,
  });

  @override
  State<EnhancedStoryViewer> createState() => _EnhancedStoryViewerState();
}

class _EnhancedStoryViewerState extends State<EnhancedStoryViewer>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _fadeController;
  VideoPlayerController? _videoController;
  final _storyService = StoryService();

  int _currentIndex = 0;
  bool _isPaused = false;
  double _dragOffset = 0;
  int _viewCount = 0;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // Hide navbar for full immersion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navVisibility = NavBarVisibilityScope.maybeOf(context);
      navVisibility?.value = false;
    });

    // Hide system UI for full immersion
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Progress animation controller
    _progressController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && !_isPaused) {
              _nextStory();
            }
          });

    // Fade animation for transitions
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _loadStory();
  }

  Future<void> _loadStory() async {
    _fadeController.forward(from: 0);
    _progressController.reset();

    final story = widget.stories[_currentIndex];
    final mediaType = story['media_type'] ?? 'image';

    // Dispose previous video
    _videoController?.dispose();
    _videoController = null;

    if (mediaType == 'video') {
      final videoUrl = story['media_url'];
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize()
            .then((_) {
              if (mounted) {
                setState(() {});
                _videoController!.play();
                _videoController!.setLooping(false);

                // Sync progress with video duration
                final duration = _videoController!.value.duration;
                _progressController.duration = duration;
                _progressController.forward();

                // Listen for video completion
                _videoController!.addListener(() {
                  if (_videoController!.value.position >=
                          _videoController!.value.duration &&
                      !_isPaused) {
                    _nextStory();
                  }
                });
              }
            })
            .catchError((error) {
              print('❌ Video load error: $error');
            });
    } else {
      // Image story - use default 5 second duration
      _progressController.duration = const Duration(seconds: 5);
      _progressController.forward();
    }

    // Increment view count
    _incrementViewCount();
    _loadViewCount();

    print('📖 Story loaded: ${_currentIndex + 1}/${widget.stories.length}');
  }

  Future<void> _incrementViewCount() async {
    try {
      final storyId = widget.stories[_currentIndex]['id'];
      await _storyService.incrementStoryViews(storyId);
    } catch (e) {
      print('❌ Failed to increment view: $e');
    }
  }

  Future<void> _loadViewCount() async {
    try {
      final storyId = widget.stories[_currentIndex]['id'];
      final story = await _storyService.getStoryById(storyId);
      if (mounted) {
        setState(() {
          _viewCount = story?['views_count'] ?? 0;
        });
      }
    } catch (e) {
      print('❌ Failed to load view count: $e');
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentIndex++;
        _isPaused = false;
      });
      _loadStory();
    } else {
      _closeViewer();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentIndex--;
        _isPaused = false;
      });
      _loadStory();
    } else {
      _closeViewer();
    }
  }

  void _pauseStory() {
    if (!_isPaused) {
      setState(() => _isPaused = true);
      _progressController.stop();
      _videoController?.pause();
      print('⏸️ Story paused');
    }
  }

  void _resumeStory() {
    if (_isPaused) {
      setState(() => _isPaused = false);
      _progressController.forward();
      _videoController?.play();
      print('▶️ Story resumed');
    }
  }

  void _closeViewer() {
    HapticFeedback.mediumImpact();

    // Restore navbar
    final navVisibility = NavBarVisibilityScope.maybeOf(context);
    navVisibility?.value = true;

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    widget.onClose?.call();
    Navigator.of(context).pop();
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.primaryDelta ?? 0;
    });

    // Swipe down to close (threshold: 100px)
    if (_dragOffset > 100) {
      _closeViewer();
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _dragOffset = 0;
    });
  }

  void _toggleLike() {
    HapticFeedback.selectionClick();
    setState(() {
      _isLiked = !_isLiked;
    });
    print(_isLiked ? '❤️ Story liked' : '💔 Story unliked');
  }

  @override
  void dispose() {
    // Restore navbar
    final navVisibility = NavBarVisibilityScope.maybeOf(context);
    navVisibility?.value = true;

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _progressController.dispose();
    _fadeController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    final mediaType = story['media_type'] ?? 'image';
    final mediaUrl = story['media_url'] ?? '';
    final caption = story['caption'];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTapDown: (details) {
            final screenWidth = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < screenWidth / 3) {
              _previousStory();
            } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
              _nextStory();
            }
          },
          onLongPressStart: (_) => _pauseStory(),
          onLongPressEnd: (_) => _resumeStory(),
          onVerticalDragUpdate: _handleVerticalDrag,
          onVerticalDragEnd: _handleDragEnd,
          child: AnimatedOpacity(
            opacity: _dragOffset > 0 ? 1 - (_dragOffset / 300).clamp(0, 1) : 1,
            duration: const Duration(milliseconds: 100),
            child: Transform.translate(
              offset: Offset(0, _dragOffset.clamp(0, 300)),
              child: Stack(
                children: [
                  // Story Media Background
                  _buildMediaViewer(mediaType, mediaUrl),

                  // Progress Indicators (Top)
                  _buildProgressIndicators(),

                  // Top Bar (User Info + Close)
                  _buildTopBar(),

                  // Caption Overlay
                  if (caption != null && caption.toString().isNotEmpty)
                    _buildCaptionOverlay(caption),

                  // Bottom Actions
                  _buildBottomActions(),

                  // Pause Indicator
                  if (_isPaused) _buildPauseIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaViewer(String mediaType, String mediaUrl) {
    return Positioned.fill(
      child: FadeTransition(
        opacity: _fadeController,
        child: mediaType == 'video'
            ? _videoController != null && _videoController!.value.isInitialized
                  ? FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
                  : Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
            : Image.network(
                mediaUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.black,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.black,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load story',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildProgressIndicators() {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          return Row(
            children: List.generate(widget.stories.length, (index) {
              double progress;
              if (index < _currentIndex) {
                progress = 1.0;
              } else if (index == _currentIndex) {
                progress = _progressController.value;
              } else {
                progress = 0.0;
              }

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.white24,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 20,
      left: 12,
      right: 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // User Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: widget.userAvatar.isNotEmpty
                        ? Image.network(
                            widget.userAvatar,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: kPrimary,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          )
                        : Container(
                            color: kPrimary,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),

                // Username and Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          shadows: [
                            Shadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                      ),
                      Text(
                        _getTimeAgo(
                          widget.stories[_currentIndex]['created_at'],
                        ),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          shadows: [
                            Shadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Close Button
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _closeViewer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptionOverlay(String caption) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 120,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Text(
              caption,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
                shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Views
                _buildActionButton(
                  icon: Icons.remove_red_eye_outlined,
                  label: '$_viewCount',
                  onTap: () {},
                ),

                // Like
                _buildActionButton(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  label: 'Like',
                  color: _isLiked ? Colors.red : Colors.white,
                  onTap: _toggleLike,
                ),

                // Share
                _buildActionButton(
                  icon: Icons.reply_outlined,
                  label: 'Share',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    print('📤 Share story');
                  },
                ),

                // More Options
                _buildActionButton(
                  icon: Icons.more_horiz,
                  label: '',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    print('⚙️ More options');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color ?? Colors.white,
              size: 28,
              shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPauseIndicator() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Icon(Icons.pause, color: Colors.white, size: 48),
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Just now';

    try {
      final DateTime dateTime = timestamp is DateTime
          ? timestamp
          : DateTime.parse(timestamp.toString());

      final difference = DateTime.now().difference(dateTime);

      if (difference.inSeconds < 60) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      return '${difference.inDays}d ago';
    } catch (e) {
      return 'Just now';
    }
  }
}
