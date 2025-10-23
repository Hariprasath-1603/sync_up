import 'package:flutter/material.dart';
import '../../core/theme.dart';

class UserPostsPage extends StatelessWidget {
  const UserPostsPage({super.key});

  // Sample posts data - matches the profile page posts
  final List<Map<String, dynamic>> _posts = const [
    {
      'imageUrl': 'https://picsum.photos/seed/post0/400/600',
      'likes': '2.4K',
      'comments': '89',
    },
    {
      'imageUrl': 'https://picsum.photos/seed/post1/400/600',
      'likes': '3.1K',
      'comments': '124',
    },
    {
      'imageUrl': 'https://picsum.photos/seed/post2/400/600',
      'likes': '1.8K',
      'comments': '67',
    },
    {
      'imageUrl': 'https://picsum.photos/seed/post3/400/600',
      'likes': '4.2K',
      'comments': '203',
    },
    {
      'imageUrl': 'https://picsum.photos/seed/post4/400/600',
      'likes': '2.9K',
      'comments': '156',
    },
    {
      'imageUrl': 'https://picsum.photos/seed/post5/400/600',
      'likes': '3.7K',
      'comments': '178',
    },
    {
      'imageUrl': 'https://picsum.photos/seed/post6/400/600',
      'likes': '5.1K',
      'comments': '234',
    },
    {
      'imageUrl': 'https://picsum.photos/seed/post7/400/600',
      'likes': '2.3K',
      'comments': '91',
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Posts',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          '${_posts.length} posts',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Posts Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return _buildPostCard(
                      post['imageUrl']!,
                      post['likes']!,
                      post['comments']!,
                      isDark,
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

  Widget _buildPostCard(
    String imageUrl,
    String likes,
    String comments,
    bool isDark,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          Image.network(imageUrl, fit: BoxFit.cover),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
          ),
          // Stats at bottom
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      likes,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.comment, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      comments,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
