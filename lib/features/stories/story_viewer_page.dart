import 'dart:async';
import 'package:flutter/material.dart';
import 'models/story_model.dart';

class StoryViewerPage extends StatefulWidget {
  final String userId;
  final List<StoryModel> stories;
  final int initialStoryIndex;
  final bool isOwnStory;

  const StoryViewerPage({
    super.key,
    required this.userId,
    required this.stories,
    this.initialStoryIndex = 0,
    this.isOwnStory = false,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with TickerProviderStateMixin {
  int _currentStoryIndex = 0;
  Timer? _storyTimer;
  
  final List<AnimationController> _progressControllers = [];
  final List<Animation<double>> _progressAnimations = [];

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialStoryIndex;
    _initializeProgressBars();
    _startStory();
    _markStoryAsViewed();
  }

  void _initializeProgressBars() {
    for (var i = 0; i < widget.stories.length; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(
          milliseconds: _getStoryDuration(widget.stories[i]).inMilliseconds,
        ),
      );
      _progressControllers.add(controller);
      _progressAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(controller),
      );

      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed && i == _currentStoryIndex) {
          _nextStory();
        }
      });
    }
  }

  Duration _getStoryDuration(StoryModel story) {
    if (story.mediaType == StoryMediaType.video && story.duration != null) {
      return Duration(seconds: story.duration!.toInt());
    }
    return const Duration(seconds: 5); // Default for images
  }

  void _startStory() {
    // Complete all previous progress bars
    for (var i = 0; i < _currentStoryIndex; i++) {
      _progressControllers[i].value = 1.0;
    }
    
    // Start current story
    _progressControllers[_currentStoryIndex].forward();
  }

  void _pauseStory() {
    if (_currentStoryIndex < _progressControllers.length) {
      _progressControllers[_currentStoryIndex].stop();
    }
  }

  void _resumeStory() {
    if (_currentStoryIndex < _progressControllers.length) {
      _progressControllers[_currentStoryIndex].forward();
    }
  }

  void _nextStory() {
    if (_currentStoryIndex < widget.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
      _startStory();
      _markStoryAsViewed();
    } else {
      // End of stories, close viewer
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      _progressControllers[_currentStoryIndex].reset();
      setState(() {
        _currentStoryIndex--;
      });
      _progressControllers[_currentStoryIndex].reset();
      _startStory();
    }
  }

  void _markStoryAsViewed() {
    final story = widget.stories[_currentStoryIndex];
    // TODO: Call API to mark as viewed
    print('Story ${story.id} viewed');
  }

  void _showReactions() {
    final reactions = ['❤️', '😂', '😮', '😍', '😢', '😡', '👏', '🔥'];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quick Reactions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: reactions.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    _sendReaction(emoji);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _sendReaction(String emoji) {
    final story = widget.stories[_currentStoryIndex];
    // TODO: Call API to send reaction
    print('Sent reaction $emoji to story ${story.id}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sent $emoji'),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showReplyDialog() {
    _pauseStory();
    final controller = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Send Message',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write a reply...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _resumeStory();
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          _sendReply(controller.text);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A6CF7),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Send'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((_) => _resumeStory());
  }

  void _sendReply(String message) {
    final story = widget.stories[_currentStoryIndex];
    // TODO: Call API to send reply as DM
    print('Sent reply "$message" to story ${story.id}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reply sent'),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showViewersList() {
    _pauseStory();
    final story = widget.stories[_currentStoryIndex];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Viewers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A6CF7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${story.viewCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 10, // TODO: Replace with actual viewers
                itemBuilder: (context, index) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF4A6CF7),
                      child: Text(
                        'U${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text('User ${index + 1}'),
                    subtitle: Text('2${index}m ago'),
                    trailing: index < 3
                        ? const Text(
                            '❤️',
                            style: TextStyle(fontSize: 20),
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).then((_) => _resumeStory());
  }

  void _showOptionsMenu() {
    _pauseStory();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (!widget.isOwnStory) ...[
              _buildOptionTile(Icons.report, 'Report Story', Colors.red, () {
                Navigator.pop(context);
                _showSnackBar('Story reported', Colors.red);
              }),
              _buildOptionTile(Icons.volume_off, 'Mute ${widget.stories[0].username}', Colors.black87, () {
                Navigator.pop(context);
                _showSnackBar('User muted', Colors.orange);
              }),
              _buildOptionTile(Icons.visibility_off, 'Hide Story', Colors.black87, () {
                Navigator.pop(context);
                Navigator.pop(context); // Close viewer
              }),
            ],
            _buildOptionTile(Icons.share, 'Share Story', Colors.black87, () {
              Navigator.pop(context);
              _showSnackBar('Share feature coming soon', Colors.blue);
            }),
            _buildOptionTile(Icons.link, 'Copy Link', Colors.black87, () {
              Navigator.pop(context);
              _showSnackBar('Link copied', Colors.green);
            }),
          ],
        ),
      ),
    ).then((_) => _resumeStory());
  }

  Widget _buildOptionTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _storyTimer?.cancel();
    for (var controller in _progressControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentStoryIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            // Left third: previous story
            _previousStory();
          } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
            // Right third: next story
            _nextStory();
          }
        },
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            // Swipe down: close viewer
            Navigator.pop(context);
          } else if (details.primaryVelocity! < 0 && widget.isOwnStory) {
            // Swipe up: show viewers (only for own story)
            _showViewersList();
          }
        },
        child: Stack(
          children: [
            // Story content
            Positioned.fill(
              child: Center(
                child: story.mediaType == StoryMediaType.video
                    ? _buildVideoPreview(story)
                    : _buildImagePreview(story),
              ),
            ),

            // Progress bars
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(
                  widget.stories.length,
                  (index) => Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: AnimatedBuilder(
                        animation: _progressAnimations[index],
                        builder: (context, child) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: index < _currentStoryIndex
                                ? 1.0
                                : index == _currentStoryIndex
                                    ? _progressAnimations[index].value
                                    : 0.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Top bar (user info, close)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF4A6CF7),
                      child: story.userAvatarUrl != null
                          ? ClipOval(
                              child: Image.network(
                                story.userAvatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildAvatarText(story.username);
                                },
                              ),
                            )
                          : _buildAvatarText(story.username),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                story.username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (story.isUserVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  color: Color(0xFF4A6CF7),
                                  size: 14,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            _getTimeAgo(story.createdAt),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: _showOptionsMenu,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),

            // Caption and metadata
            if (story.caption != null && story.caption!.isNotEmpty)
              Positioned(
                bottom: 120,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    story.caption!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

            // Music overlay
            if (story.musicTrack != null)
              Positioned(
                bottom: 180,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        story.musicTrack!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom actions (reactions, reply)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _showReplyDialog,
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
                            ),
                          ),
                          child: Text(
                            'Send message...',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _showReactions,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Swipe up indicator (for own story)
            if (widget.isOwnStory)
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.white,
                        size: 32,
                      ),
                      Text(
                        'Swipe up to see viewers',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(StoryModel story) {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 100,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Image Story',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview(StoryModel story) {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 100,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Video Story',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarText(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
