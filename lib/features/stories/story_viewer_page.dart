import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme.dart';
import '../home/models/story_model.dart';

class StoryViewerPage extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;
  final bool isMyStory;

  const StoryViewerPage({
    super.key,
    required this.stories,
    required this.initialIndex,
    this.isMyStory = false,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with SingleTickerProviderStateMixin {
  late int _currentStoryIndex;
  late int _currentSegmentIndex;
  double _progress = 0.0;
  Timer? _progressTimer;
  bool _isPaused = false;
  late PageController _pageController;
  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;
  bool _isTransitioning = false;

  final List<Map<String, String>> _viewers = [
    {'name': 'Alex Johnson', 'reaction': '❤️', 'time': '2m ago'},
    {'name': 'Priya Sharma', 'reaction': '😂', 'time': '5m ago'},
    {'name': 'John Doe', 'reaction': '', 'time': '10m ago'},
    {'name': 'Meera Patel', 'reaction': '😮', 'time': '15m ago'},
  ];

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialIndex;
    _currentSegmentIndex = 0;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Initialize transition animation controller
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeInOut),
    );

    _transitionController.forward();
    _startProgress();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _pageController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  void _startProgress() {
    _progressTimer?.cancel();
    _progress = 0.0;

    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isPaused && mounted) {
        setState(() {
          _progress += 0.01;
          if (_progress >= 1.0) {
            _nextSegment();
          }
        });
      }
    });
  }

  void _nextSegment() {
    _progressTimer?.cancel();
    if (_currentSegmentIndex < 0) {
      // Assuming 1 segment per story for now
      setState(() {
        _currentSegmentIndex++;
        _startProgress();
      });
    } else {
      _nextStory();
    }
  }

  void _previousSegment() {
    _progressTimer?.cancel();
    if (_currentSegmentIndex > 0) {
      setState(() {
        _currentSegmentIndex--;
        _startProgress();
      });
    } else if (_currentStoryIndex > 0) {
      _previousStory();
    }
  }

  void _nextStory() async {
    if (_currentStoryIndex < widget.stories.length - 1) {
      setState(() {
        _isTransitioning = true;
      });

      // Fade out animation
      await _transitionController.reverse();

      // Move to next page
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      setState(() {
        _currentStoryIndex++;
        _currentSegmentIndex = 0;
        _isTransitioning = false;
      });

      // Fade in animation
      await _transitionController.forward();
      _startProgress();
    } else {
      // All stories completed, exit with fade out
      await _transitionController.reverse();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _previousStory() async {
    if (_currentStoryIndex > 0) {
      setState(() {
        _isTransitioning = true;
      });

      // Fade out animation
      await _transitionController.reverse();

      // Move to previous page
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      setState(() {
        _currentStoryIndex--;
        _currentSegmentIndex = 0;
        _isTransitioning = false;
      });

      // Fade in animation
      await _transitionController.forward();
      _startProgress();
    }
  }

  void _showViewersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1D24) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.visibility, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Viewed by ${_viewers.length}',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _viewers.length,
                  itemBuilder: (context, index) {
                    final viewer = _viewers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: kPrimary.withOpacity(0.2),
                        child: Text(
                          viewer['name']![0],
                          style: const TextStyle(color: kPrimary),
                        ),
                      ),
                      title: Text(
                        viewer['name']!,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        viewer['time']!,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      trailing: viewer['reaction']!.isNotEmpty
                          ? Text(
                              viewer['reaction']!,
                              style: const TextStyle(fontSize: 24),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1D24) : Colors.white,
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
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              if (widget.isMyStory) ...[
                _buildOptionTile(
                  Icons.delete_outline,
                  'Delete Story',
                  Colors.red,
                  () {
                    Navigator.pop(context);
                    _deleteStory();
                  },
                  isDark,
                ),
                _buildOptionTile(
                  Icons.download,
                  'Save to Gallery',
                  isDark ? Colors.white : Colors.black87,
                  () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved to gallery')),
                    );
                  },
                  isDark,
                ),
                _buildOptionTile(
                  Icons.bookmark_border,
                  'Add to Highlights',
                  isDark ? Colors.white : Colors.black87,
                  () {
                    Navigator.pop(context);
                    _showHighlightsDialog();
                  },
                  isDark,
                ),
                _buildOptionTile(
                  Icons.settings,
                  'Story Settings',
                  isDark ? Colors.white : Colors.black87,
                  () {
                    Navigator.pop(context);
                  },
                  isDark,
                ),
              ] else ...[
                _buildOptionTile(
                  Icons.volume_off,
                  'Mute User',
                  isDark ? Colors.white : Colors.black87,
                  () {
                    Navigator.pop(context);
                  },
                  isDark,
                ),
                _buildOptionTile(
                  Icons.report_outlined,
                  'Report Story',
                  Colors.red,
                  () {
                    Navigator.pop(context);
                  },
                  isDark,
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isDark ? const Color(0xFF0B0E13) : Colors.grey[100],
    );
  }

  void _deleteStory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Story?'),
        content: const Text('This story will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Story deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showHighlightsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Highlights'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.add)),
              title: const Text('New Highlight'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.bookmark)),
              title: const Text('Travel 2025'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendReaction(String emoji) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reaction sent $emoji'),
        duration: const Duration(seconds: 1),
        backgroundColor: kPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return Scaffold(body: Center(child: Text('No stories available')));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Disable swipe, use animation instead
        itemCount: widget.stories.length,
        onPageChanged: (index) {
          setState(() {
            _currentStoryIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final story = widget.stories[index];
          return FadeTransition(
            opacity: _fadeAnimation,
            child: _buildStoryContent(context, story),
          );
        },
      ),
    );
  }

  Widget _buildStoryContent(BuildContext context, Story story) {
    return GestureDetector(
      onTapDown: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (details.globalPosition.dx < screenWidth / 3) {
          _previousSegment();
        } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
          _nextSegment();
        }
      },
      onLongPressStart: (_) {
        setState(() {
          _isPaused = true;
        });
      },
      onLongPressEnd: (_) {
        setState(() {
          _isPaused = false;
        });
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          if (widget.isMyStory) {
            _showViewersSheet();
          }
        }
      },
      child: Stack(
        children: [
          // Story Content
          Positioned.fill(
            child: Image.network(
              story.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(Icons.error, color: Colors.white, size: 50),
                  ),
                );
              },
            ),
          ),

          // Progress bars
          Positioned(
            top: 50,
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
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: index < _currentStoryIndex
                          ? 1.0
                          : (index == _currentStoryIndex ? _progress : 0.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Header
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(story.userAvatarUrl),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '2h ago',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
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

          // Bottom actions
          if (!widget.isMyStory)
            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
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
                        'Send message',
                        style: TextStyle(color: Colors.white.withOpacity(0.9)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildReactionButton('❤️'),
                  const SizedBox(width: 8),
                  _buildReactionButton('😂'),
                  const SizedBox(width: 8),
                  _buildReactionButton('😍'),
                  const SizedBox(width: 8),
                  _buildReactionButton('👍'),
                ],
              ),
            ),

          // My Story - Swipe up hint
          if (widget.isMyStory)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.white.withOpacity(0.7),
                    size: 32,
                  ),
                  Text(
                    'Swipe up to see viewers',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReactionButton(String emoji) {
    return GestureDetector(
      onTap: () => _sendReaction(emoji),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
