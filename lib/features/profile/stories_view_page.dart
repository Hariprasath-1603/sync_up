import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'add_story_page.dart';

class StoriesViewPage extends StatefulWidget {
  const StoriesViewPage({super.key});

  @override
  State<StoriesViewPage> createState() => _StoriesViewPageState();
}

class _StoriesViewPageState extends State<StoriesViewPage> {
  // Extended stories list (without "Add" button)
  final List<Map<String, dynamic>> _allStories = [
    {
      'title': 'Travel',
      'url': 'https://picsum.photos/seed/s1/200',
      'date': '2 days ago',
      'views': 234,
    },
    {
      'title': 'Food',
      'url': 'https://picsum.photos/seed/s2/200',
      'date': '5 days ago',
      'views': 456,
    },
    {
      'title': 'Friends',
      'url': 'https://picsum.photos/seed/s3/200',
      'date': '1 week ago',
      'views': 789,
    },
    {
      'title': 'Hangout',
      'url': 'https://picsum.photos/seed/s4/200',
      'date': '1 week ago',
      'views': 321,
    },
    {
      'title': 'Workout',
      'url': 'https://picsum.photos/seed/s5/200',
      'date': '2 weeks ago',
      'views': 567,
    },
    {
      'title': 'Nature',
      'url': 'https://picsum.photos/seed/s6/200',
      'date': '2 weeks ago',
      'views': 890,
    },
    {
      'title': 'Party',
      'url': 'https://picsum.photos/seed/s7/200',
      'date': '3 weeks ago',
      'views': 1234,
    },
    {
      'title': 'Beach',
      'url': 'https://picsum.photos/seed/s8/200',
      'date': '3 weeks ago',
      'views': 678,
    },
    {
      'title': 'Concert',
      'url': 'https://picsum.photos/seed/s9/200',
      'date': '1 month ago',
      'views': 2345,
    },
    {
      'title': 'Family',
      'url': 'https://picsum.photos/seed/s10/200',
      'date': '1 month ago',
      'views': 543,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0B0E13),
                    const Color(0xFF1A1F2E),
                    kPrimary.withOpacity(0.15),
                  ]
                : [
                    const Color(0xFFF6F7FB),
                    kPrimary.withOpacity(0.08),
                    const Color(0xFFE8ECFF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context, isDark),
              const SizedBox(height: 16),
              // Stories Grid
              Expanded(child: _buildStoriesGrid(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                // Back Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: kPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Stories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'View all your archived stories',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                // Add New Story Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddStoryPage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kPrimary.withOpacity(0.8), kPrimary],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
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

  Widget _buildStoriesGrid(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _allStories.length,
      itemBuilder: (context, index) {
        return _buildStoryCard(_allStories[index], isDark);
      },
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> story, bool isDark) {
    return GestureDetector(
      onTap: () {
        // Navigate to full story view
        _showStoryFullScreen(story);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story Image
            Image.network(story['url'], fit: BoxFit.cover),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            // Story Info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      story['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          story['date'],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.visibility_rounded,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${story['views']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Menu Button
            Positioned(
              top: 8,
              right: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStoryFullScreen(Map<String, dynamic> story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _StoryFullScreenView(story: story),
      ),
    );
  }
}

// Full screen story viewer
class _StoryFullScreenView extends StatefulWidget {
  final Map<String, dynamic> story;

  const _StoryFullScreenView({required this.story});

  @override
  State<_StoryFullScreenView> createState() => _StoryFullScreenViewState();
}

class _StoryFullScreenViewState extends State<_StoryFullScreenView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story Image
            Center(
              child: Image.network(widget.story['url'], fit: BoxFit.contain),
            ),
            // Top Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Back Button
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Story Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.story['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.story['date'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // More Options
                      IconButton(
                        onPressed: () {
                          _showStoryOptions();
                        },
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom Info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.visibility_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.story['views']} views',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStoryOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.8)
                    : Colors.white.withOpacity(0.9),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildOptionItem(Icons.share_rounded, 'Share Story', () {}),
                  _buildOptionItem(Icons.download_rounded, 'Download', () {}),
                  _buildOptionItem(
                    Icons.delete_outline_rounded,
                    'Delete Story',
                    () {},
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : kPrimary),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
