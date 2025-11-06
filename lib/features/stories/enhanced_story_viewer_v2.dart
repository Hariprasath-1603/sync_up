import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme.dart';
import '../../core/services/story_service.dart';
import '../../core/scaffold_with_nav_bar.dart';

/// Enhanced Story Viewer with Dual Modes: Own Story vs Other User Story
/// Features: Swipe-down animation, adaptive layouts, glassmorphic overlays
class EnhancedStoryViewerV2 extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final int initialIndex;
  final String userName;
  final String userAvatar;
  final String userId;
  final VoidCallback? onClose;

  const EnhancedStoryViewerV2({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    required this.userName,
    required this.userAvatar,
    required this.userId,
    this.onClose,
  });

  @override
  State<EnhancedStoryViewerV2> createState() => _EnhancedStoryViewerV2State();
}

class _EnhancedStoryViewerV2State extends State<EnhancedStoryViewerV2>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late AnimationController _swipeController;
  VideoPlayerController? _videoController;
  final _storyService = StoryService();
  final _replyController = TextEditingController();

  int _currentIndex = 0;
  bool _isPaused = false;
  double _dragOffset = 0;
  int _viewCount = 0;
  bool _isLiked = false;
  bool _isOwner = false;
  List<Map<String, dynamic>> _viewers = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _checkOwnership();

    // Hide navbar for full immersion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navVisibility = NavBarVisibilityScope.maybeOf(context);
      navVisibility?.value = false;
    });

    // Hide system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Progress animation
    _progressController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && !_isPaused) {
              _nextStory();
            }
          });

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Swipe animation
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _loadStory();
  }

  void _checkOwnership() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _isOwner = widget.userId == currentUserId;
    print(
      '👤 Story owner check: ${_isOwner ? "Own story" : "Other user story"}',
    );
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

                final duration = _videoController!.value.duration;
                _progressController.duration = duration;
                _progressController.forward();

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
      _progressController.duration = const Duration(seconds: 5);
      _progressController.forward();
    }

    // Increment view count
    _incrementViewCount();
    _loadViewCount();
    if (_isOwner) {
      _loadViewers();
    }

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

  Future<void> _loadViewers() async {
    try {
      final storyId = widget.stories[_currentIndex]['id'];
      final viewers = await _storyService.getStoryViewers(storyId);
      if (mounted) {
        setState(() {
          _viewers = viewers;
        });
      }
    } catch (e) {
      print('❌ Failed to load viewers: $e');
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
      _closeWithAnimation();
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
      _closeWithAnimation();
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

  void _closeWithAnimation() {
    HapticFeedback.mediumImpact();

    // Animate swipe down
    _swipeController.forward().then((_) {
      // Restore navbar and system UI
      final navVisibility = NavBarVisibilityScope.maybeOf(context);
      navVisibility?.value = true;
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      widget.onClose?.call();
      Navigator.of(context).pop();
    });
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
    if (details.primaryDelta! > 0) {
      setState(() {
        _dragOffset += details.primaryDelta!;
        _swipeController.value = (_dragOffset / 300).clamp(0.0, 1.0);
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragOffset > 100) {
      _closeWithAnimation();
    } else {
      // Spring back
      setState(() {
        _dragOffset = 0;
      });
      _swipeController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  void _toggleLike() {
    HapticFeedback.selectionClick();
    setState(() => _isLiked = !_isLiked);
    print(_isLiked ? '❤️ Story liked' : '💔 Story unliked');
  }

  void _sendReply() {
    if (_replyController.text.trim().isEmpty) return;

    HapticFeedback.lightImpact();
    final message = _replyController.text.trim();
    _replyController.clear();

    print('💬 Reply sent: $message');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reply sent to ${widget.userName}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    _resumeStory();
  }

  void _showOwnerMenu() {
    _pauseStory();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOwnerMenu(),
    ).then((_) => _resumeStory());
  }

  void _showViewerMenu() {
    _pauseStory();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildViewerMenu(),
    ).then((_) => _resumeStory());
  }

  void _showViewersModal() {
    _pauseStory();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildViewersModal(),
    ).then((_) => _resumeStory());
  }

  @override
  void dispose() {
    final navVisibility = NavBarVisibilityScope.maybeOf(context);
    navVisibility?.value = true;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _progressController.dispose();
    _fadeController.dispose();
    _swipeController.dispose();
    _videoController?.dispose();
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    final mediaType = story['media_type'] ?? 'image';
    final mediaUrl = story['media_url'] ?? '';
    final caption = story['caption'];

    return AnimatedBuilder(
      animation: _swipeController,
      builder: (context, child) {
        final offsetY = 300 * _swipeController.value;
        final opacity = 1 - (_swipeController.value * 0.5);

        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Opacity(
            opacity: opacity,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                bottom: false,
                child: GestureDetector(
                  onTapDown: (details) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    if (details.globalPosition.dx < screenWidth / 3) {
                      _previousStory();
                    } else if (details.globalPosition.dx >
                        screenWidth * 2 / 3) {
                      _nextStory();
                    }
                  },
                  onLongPressStart: (_) => _pauseStory(),
                  onLongPressEnd: (_) => _resumeStory(),
                  onVerticalDragUpdate: _handleVerticalDrag,
                  onVerticalDragEnd: _handleDragEnd,
                  child: Stack(
                    children: [
                      // Story Media
                      _buildMediaViewer(mediaType, mediaUrl),

                      // Progress Bars
                      _buildProgressIndicators(),

                      // Top Bar
                      _buildTopBar(),

                      // Caption
                      if (caption != null && caption.toString().isNotEmpty)
                        _buildCaptionOverlay(caption),

                      // Bottom Overlay (Different for owner vs viewer)
                      if (_isOwner)
                        _buildOwnerBottomOverlay()
                      else
                        _buildViewerBottomOverlay(),

                      // Pause Indicator
                      if (_isPaused) _buildPauseIndicator(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
                        gradient: LinearGradient(
                          colors: [Colors.white, kPrimary],
                        ),
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
                    border: Border.all(
                      color: _isOwner ? kPrimary : Colors.white,
                      width: 2,
                    ),
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
                      Row(
                        children: [
                          Text(
                            widget.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (_isOwner) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: kPrimary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'You',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        _getTimeAgo(
                          widget.stories[_currentIndex]['created_at'],
                        ),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // More Options Button
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
                      Icons.more_vert,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _isOwner ? _showOwnerMenu : _showViewerMenu,
                  ),
                ),

                const SizedBox(width: 8),

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
                    onPressed: _closeWithAnimation,
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
      bottom: _isOwner ? 140 : 180,
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  // OWNER BOTTOM OVERLAY
  Widget _buildOwnerBottomOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Swipe Indicator
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Views
                    _buildOwnerActionButton(
                      icon: Icons.remove_red_eye_outlined,
                      label: '$_viewCount',
                      sublabel: 'Views',
                      onTap: _showViewersModal,
                    ),

                    // Share
                    _buildOwnerActionButton(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        print('📤 Share story');
                      },
                    ),

                    // Archive
                    _buildOwnerActionButton(
                      icon: Icons.archive_outlined,
                      label: 'Archive',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        print('📦 Archive story');
                      },
                    ),

                    // Delete
                    _buildOwnerActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      color: Colors.red,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _showDeleteConfirmation();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerActionButton({
    required IconData icon,
    required String label,
    String? sublabel,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? Colors.white, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (sublabel != null) ...[
              Text(
                sublabel,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // VIEWER BOTTOM OVERLAY
  Widget _buildViewerBottomOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reply Input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Reply to ${widget.userName}...',
                            hintStyle: const TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                          onTap: _pauseStory,
                          onEditingComplete: _resumeStory,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                        onPressed: _sendReply,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Reaction Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildReactionButton(
                      icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                      label: 'Like',
                      color: _isLiked ? Colors.red : Colors.white,
                      onTap: _toggleLike,
                    ),
                    _buildReactionButton(
                      icon: Icons.emoji_emotions_outlined,
                      label: 'React',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        print('😊 Show reactions');
                      },
                    ),
                    _buildReactionButton(
                      icon: Icons.reply_outlined,
                      label: 'Share',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        print('📤 Share story');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReactionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
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

  // OWNER MENU
  Widget _buildOwnerMenu() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuOption(
                icon: Icons.bar_chart,
                title: 'View Insights',
                onTap: () {
                  Navigator.pop(context);
                  _showViewersModal();
                },
              ),
              _buildMenuOption(
                icon: Icons.edit_outlined,
                title: 'Edit Story',
                onTap: () {
                  Navigator.pop(context);
                  print('✏️ Edit story');
                },
              ),
              _buildMenuOption(
                icon: Icons.archive_outlined,
                title: 'Archive Story',
                onTap: () {
                  Navigator.pop(context);
                  print('📦 Archive story');
                },
              ),
              _buildMenuOption(
                icon: Icons.delete_outline,
                title: 'Delete Story',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // VIEWER MENU
  Widget _buildViewerMenu() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuOption(
                icon: Icons.report_outlined,
                title: 'Report Story',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  print('🚨 Report story');
                },
              ),
              _buildMenuOption(
                icon: Icons.not_interested,
                title: 'Not Interested',
                onTap: () {
                  Navigator.pop(context);
                  print('🚫 Not interested');
                },
              ),
              _buildMenuOption(
                icon: Icons.share_outlined,
                title: 'Share Story',
                onTap: () {
                  Navigator.pop(context);
                  print('📤 Share story');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white),
      title: Text(title, style: TextStyle(color: color ?? Colors.white)),
      onTap: onTap,
    );
  }

  // VIEWERS MODAL (for own stories)
  Widget _buildViewersModal() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Story Viewers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$_viewCount views',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Viewers List
              Expanded(
                child: _viewers.isEmpty
                    ? const Center(
                        child: Text(
                          'No views yet',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _viewers.length,
                        itemBuilder: (context, index) {
                          final viewer = _viewers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: viewer['photo_url'] != null
                                  ? NetworkImage(viewer['photo_url'])
                                  : null,
                              child: viewer['photo_url'] == null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(
                              viewer['username'] ?? 'Unknown',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              _getTimeAgo(viewer['viewed_at']),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Story?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This story will be permanently deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              print('🗑️ Story deleted');
              _closeWithAnimation();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
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
