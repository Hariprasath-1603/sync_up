import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post_model.dart';
import 'post_viewer_page_v2.dart';
import 'widgets/long_press_menu.dart';

/// Example: Enhanced profile grid with post interactions
/// This demonstrates how to integrate the post interaction system
class ProfilePostsGridDemo extends StatefulWidget {
  const ProfilePostsGridDemo({super.key});

  @override
  State<ProfilePostsGridDemo> createState() => _ProfilePostsGridDemoState();
}

class _ProfilePostsGridDemoState extends State<ProfilePostsGridDemo> {
  late List<PostModel> _posts;
  bool _showLongPressMenu = false;
  PostModel? _selectedPost;

  @override
  void initState() {
    super.initState();
    _generateSamplePosts();
  }

  void _generateSamplePosts() {
    final random = Random();
    _posts = List.generate(12, (i) {
      final isVideo = i % 3 == 0;
      final isCarousel = !isVideo && i % 5 == 0;

      return PostModel(
        id: 'post_$i',
        type: isVideo
            ? PostType.reel
            : isCarousel
            ? PostType.carousel
            : PostType.image,
        mediaUrls: isCarousel
            ? List.generate(
                3,
                (j) => 'https://picsum.photos/seed/post${i}_$j/1080/1920',
              )
            : ['https://picsum.photos/seed/post$i/1080/1920'],
        thumbnailUrl: 'https://picsum.photos/seed/post$i/400/600',
        username: '@you',
        userAvatar: 'https://i.pravatar.cc/150?img=1',
        timestamp: DateTime.now().subtract(
          Duration(days: i, hours: random.nextInt(24)),
        ),
        caption: _generateCaption(i),
        location: i % 4 == 0 ? _getRandomLocation() : null,
        musicName: isVideo ? _getRandomMusicName() : null,
        musicArtist: isVideo ? '@artist${random.nextInt(10)}' : null,
        likes: random.nextInt(50000),
        comments: random.nextInt(2000),
        shares: random.nextInt(1000),
        saves: random.nextInt(5000),
        views: isVideo ? random.nextInt(200000) : 0,
        isLiked: random.nextBool(),
        isSaved: random.nextBool(),
      );
    });
  }

  String _generateCaption(int index) {
    final captions = [
      'Living my best life! ✨',
      'Chasing dreams and sunsets 🌅',
      'Good vibes only 🌟',
      'Making memories that last forever 📸',
      'Adventure awaits! 🗺️',
      'Blessed and grateful 🙏',
      'Just another magic Monday ✨',
      'Stay wild, moon child 🌙',
      'Creating my own sunshine ☀️',
      'Life is beautiful 🌸',
    ];
    return captions[index % captions.length];
  }

  String _getRandomLocation() {
    final locations = [
      'New York, USA',
      'Paris, France',
      'Tokyo, Japan',
      'London, UK',
      'Dubai, UAE',
      'Sydney, Australia',
    ];
    return locations[Random().nextInt(locations.length)];
  }

  String _getRandomMusicName() {
    final songs = [
      'Blinding Lights',
      'Levitating',
      'Stay',
      'Good 4 U',
      'Heat Waves',
      'Save Your Tears',
    ];
    return songs[Random().nextInt(songs.length)];
  }

  void _openPostViewer(int index) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return PostViewerPageV2(
            initialPost: _posts[index],
            allPosts: _posts,
            onPostChanged: (post) {
              // Handle post changes if needed
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _showLongPressMenuForPost(PostModel post) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedPost = post;
      _showLongPressMenu = true;
    });
  }

  void _dismissLongPressMenu() {
    setState(() {
      _showLongPressMenu = false;
      _selectedPost = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Posts grid
        GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 0.75,
          ),
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            return _buildPostThumbnail(_posts[index], index);
          },
        ),

        // Long press menu overlay
        if (_showLongPressMenu && _selectedPost != null)
          LongPressPostMenu(
            post: _selectedPost!,
            onDismiss: _dismissLongPressMenu,
            onPreview: () {
              // Preview post without full navigation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preview mode coming soon!')),
              );
            },
            onEdit: () {
              // Open edit page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit post coming soon!')),
              );
            },
            onDelete: () {
              // Show delete confirmation
              _showDeleteConfirmation(_selectedPost!);
            },
            onSave: () {
              // Toggle save
              setState(() {
                _selectedPost!.isSaved = !_selectedPost!.isSaved;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _selectedPost!.isSaved
                        ? 'Saved to collection'
                        : 'Removed from saved',
                  ),
                ),
              );
            },
            onShare: () {
              // Open share sheet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share options coming soon!')),
              );
            },
            onInsights: () {
              // Open insights page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Insights page coming soon!')),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPostThumbnail(PostModel post, int index) {
    return GestureDetector(
      onTap: () => _openPostViewer(index),
      onLongPress: () => _showLongPressMenuForPost(post),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail image
          Image.network(
            post.thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[800],
              child: const Icon(Icons.broken_image, color: Colors.white54),
            ),
          ),

          // Video indicator
          if (post.isVideo)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),

          // Carousel indicator
          if (post.isCarousel)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.collections_outlined,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),

          // Saved indicator
          if (post.isSaved)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bookmark,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(PostModel post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _posts.removeWhere((p) => p.id == post.id);
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Post deleted')));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
