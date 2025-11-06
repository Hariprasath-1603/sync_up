import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/story_view_controller.dart';
import '../widgets/story_progress_bars.dart';
import '../models/story_model.dart';
import '../../../core/theme.dart';

/// Fullscreen story viewer with gesture controls and dual modes
class StoryViewerPage extends StatefulWidget {
  const StoryViewerPage({
    super.key,
    required this.stories,
    required this.initialIndex,
    required this.currentUserId,
  });

  final List<StoryItem> stories;
  final int initialIndex;
  final String currentUserId;

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage> {
  late StoryViewController _controller;
  bool _showPauseOverlay = false;
  double _dragStartX = 0;
  double _dragOffsetX = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = StoryViewController(
      stories: widget.stories,
      initialStoryIndex: widget.initialIndex,
      currentUserId: widget.currentUserId,
    );
    _controller.initialize();
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    // Don't navigate if dragging or paused
    if (_isDragging || _showPauseOverlay) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;

    // Haptic feedback on tap
    HapticFeedback.lightImpact();

    if (tapX < screenWidth * 0.3) {
      // Left 30% - previous segment
      _controller.previous();
    } else {
      // Right 70% - next segment
      _controller.next();
    }
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    setState(() {
      _isDragging = true;
    });
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffsetX = details.globalPosition.dx - _dragStartX;
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final threshold = MediaQuery.of(context).size.width * 0.3;

    setState(() {
      _isDragging = false;
      _dragOffsetX = 0;
    });

    // Swipe right - previous user
    if (velocity > 500 || _dragOffsetX > threshold) {
      if (_controller.currentStoryIndex > 0) {
        HapticFeedback.mediumImpact();
        _controller.jumpTo(_controller.currentStoryIndex - 1, 0);
      } else {
        // Edge bounce feedback
        HapticFeedback.lightImpact();
        _showEdgeBounce();
      }
    }
    // Swipe left - next user
    else if (velocity < -500 || _dragOffsetX < -threshold) {
      if (_controller.currentStoryIndex < widget.stories.length - 1) {
        HapticFeedback.mediumImpact();
        _controller.jumpTo(_controller.currentStoryIndex + 1, 0);
      } else {
        // Last user - close viewer
        HapticFeedback.lightImpact();
        Navigator.of(context).pop();
      }
    }
  }

  void _showEdgeBounce() {
    // Visual feedback for reaching first user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('First story'),
        duration: const Duration(milliseconds: 500),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    HapticFeedback.mediumImpact();
    setState(() {
      _showPauseOverlay = true;
    });
    _controller.pause();
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    setState(() {
      _showPauseOverlay = false;
    });
    _controller.resume();
  }

  void _handleVerticalDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity > 500) {
      // Swipe down - close viewer with haptic
      HapticFeedback.lightImpact();
      Navigator.of(context).pop();
    } else if (velocity < -500 && !_controller.isOwnStory) {
      // Swipe up - open reply sheet (viewer mode only)
      HapticFeedback.lightImpact();
      _showReplySheet();
    }
  }

  void _showReplySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReplyBottomSheet(
        story: _controller.currentStory,
        currentUserId: widget.currentUserId,
      ),
    );
  }

  void _showCreatorMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreatorMenuSheet(
        story: _controller.currentStory,
        onDelete: () {
          // TODO: Implement delete story
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
        onViewInsights: () {
          Navigator.of(context).pop();
          _showInsightsSheet();
        },
        onViewViewers: () {
          Navigator.of(context).pop();
          _showViewersSheet();
        },
      ),
    );
  }

  void _showInsightsSheet() {
    // TODO: Implement insights modal
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Insights coming soon')));
  }

  void _showViewersSheet() {
    // TODO: Implement viewers list
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Viewers list coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final currentStory = _controller.currentStory;
    final currentSegment = _controller.currentSegment;
    final isVideo = currentSegment.mediaType == StoryMediaType.video;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _handleTapDown,
        onLongPressStart: _handleLongPressStart,
        onLongPressEnd: _handleLongPressEnd,
        onVerticalDragEnd: _handleVerticalDrag,
        onHorizontalDragStart: _handleHorizontalDragStart,
        onHorizontalDragUpdate: _handleHorizontalDragUpdate,
        onHorizontalDragEnd: _handleHorizontalDragEnd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.translationValues(_dragOffsetX * 0.3, 0, 0),
          child: Stack(
            children: [
              // Media content
              _buildMediaContent(isVideo, currentSegment),

              // Pause overlay
              if (_showPauseOverlay)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: Icon(
                      Icons.pause_circle_outline,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Progress bars at top
              SafeArea(
                child: StoryProgressBars(
                  segmentCount: currentStory.segments.length,
                  currentIndex: _controller.currentSegmentIndex,
                  duration: const Duration(seconds: 5),
                  isPaused: _controller.isPaused,
                  onSegmentComplete: () => _controller.next(),
                  videoDuration: _controller.videoController?.value.duration,
                  videoPosition: _controller.videoController?.value.position,
                ),
              ),

              // User info and controls
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 60), // Space for progress bars
                    _buildTopBar(currentStory),
                    const Spacer(),
                    if (_controller.isOwnStory)
                      _buildCreatorBottomBar()
                    else
                      _buildViewerBottomBar(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Close button
              SafeArea(
                child: Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaContent(bool isVideo, StorySegment segment) {
    if (isVideo && _controller.videoController != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: _controller.videoController!.value.aspectRatio,
          child: VideoPlayer(_controller.videoController!),
        ),
      );
    } else {
      return Center(
        child: CachedNetworkImage(
          imageUrl: segment.mediaUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) =>
              const CircularProgressIndicator(color: Colors.white),
          errorWidget: (context, url, error) =>
              const Icon(Icons.error, color: Colors.white, size: 48),
        ),
      );
    }
  }

  Widget _buildTopBar(StoryItem story) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: story.userPhotoUrl.isNotEmpty
                ? CachedNetworkImageProvider(story.userPhotoUrl)
                : null,
            child: story.userPhotoUrl.isEmpty
                ? Text(
                    story.username[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  _formatTimestamp(story.lastUpdated),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewerBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _showReplySheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Send message',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildActionButton(Icons.favorite_border, () {
            // TODO: Add reaction
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Reaction sent!')));
          }),
          const SizedBox(width: 8),
          _buildActionButton(Icons.send, () {
            // TODO: Share story
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Share coming soon')));
          }),
        ],
      ),
    );
  }

  Widget _buildCreatorBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCreatorStat(
            Icons.visibility_outlined,
            '${_controller.currentSegment.viewsCount}',
            'Views',
          ),
          _buildCreatorStat(
            Icons.favorite_border,
            '0', // TODO: Get reactions count
            'Reactions',
          ),
          _buildCreatorStat(
            Icons.chat_bubble_outline,
            '0', // TODO: Get replies count
            'Replies',
          ),
          IconButton(
            onPressed: _showCreatorMenu,
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

// Reply bottom sheet widget
class _ReplyBottomSheet extends StatefulWidget {
  const _ReplyBottomSheet({required this.story, required this.currentUserId});

  final StoryItem story;
  final String currentUserId;

  @override
  State<_ReplyBottomSheet> createState() => _ReplyBottomSheetState();
}

class _ReplyBottomSheetState extends State<_ReplyBottomSheet> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _quickReactions = ['❤️', '😂', '😍', '🔥', '😢', '👏'];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendReply(String message) {
    if (message.trim().isEmpty) return;

    // TODO: Save reply to Supabase
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reply sent!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? kDarkBackground
            : kLightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Send a reply',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick reactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _quickReactions
                    .map(
                      (emoji) => GestureDetector(
                        onTap: () => _sendReply(emoji),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),

              // Message input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: kPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => _sendReply(_messageController.text),
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Creator menu sheet
class _CreatorMenuSheet extends StatelessWidget {
  const _CreatorMenuSheet({
    required this.story,
    required this.onDelete,
    required this.onViewInsights,
    required this.onViewViewers,
  });

  final StoryItem story;
  final VoidCallback onDelete;
  final VoidCallback onViewInsights;
  final VoidCallback onViewViewers;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? kDarkBackground
            : kLightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuItem(
              context,
              Icons.insights_outlined,
              'View Insights',
              onViewInsights,
            ),
            _buildMenuItem(
              context,
              Icons.people_outline,
              'View Viewers',
              onViewViewers,
            ),
            _buildMenuItem(context, Icons.share_outlined, 'Share Story', () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share coming soon')),
              );
            }),
            _buildMenuItem(
              context,
              Icons.archive_outlined,
              'Archive Story',
              () {
                Navigator.of(context).pop();
                // TODO: Archive story
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Story archived')));
              },
            ),
            _buildMenuItem(
              context,
              Icons.delete_outline,
              'Delete Story',
              onDelete,
              isDestructive: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : null),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
