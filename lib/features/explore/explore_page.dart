import 'package:flutter/material.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            toolbarHeight: 120, // Adjusted height for search and top padding
            backgroundColor: Colors.transparent, // Make it transparent to let the body background show
            elevation: 0,
            title: Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16), // Padding from top of safe area
                  _SearchBar(),
                  SizedBox(height: 16),
                  _CategoryChips(),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Trending Video',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          _TrendingVideoGrid(),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Explore',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          _ExploreGrid(),
          SliverToBoxAdapter(
            child: SizedBox(height: 100), // Padding for nav bar
          ),
        ],
      ),
    );
  }
}

// --- Helper Widgets for ExplorePage ---

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: isDark ? Colors.white70 : Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Snapbox',
                hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                border: InputBorder.none,
                isDense: true, // Reduces vertical padding
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips();

  final List<Map<String, dynamic>> categories = const [
    {'label': 'Trending', 'icon': Icons.local_fire_department, 'color': Colors.redAccent},
    {'label': 'Music', 'icon': Icons.music_note, 'color': Colors.blueAccent},
    {'label': 'Learn', 'icon': Icons.lightbulb, 'color': Colors.orangeAccent},
    {'label': 'Gaming', 'icon': Icons.gamepad, 'color': Colors.greenAccent},
    {'label': 'Sports', 'icon': Icons.sports_basketball, 'color': Colors.purpleAccent},
    {'label': 'Fashion', 'icon': Icons.checkroom, 'color': Colors.pinkAccent},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          return ActionChip(
            avatar: Icon(category['icon'], color: category['color'], size: 18),
            label: Text(category['label']),
            labelStyle: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onPressed: () {
              // Handle category tap
              print('Tapped ${category['label']}');
            },
          );
        },
      ),
    );
  }
}

class _TrendingVideoGrid extends StatelessWidget {
  const _TrendingVideoGrid();

  final List<Map<String, String>> trendingVideos = const [
    {
      'imageUrl': 'https://picsum.photos/seed/trending1/400/600',
      'title': 'Create a 3D Scene from a ...',
      'userName': 'maria.roze',
      'userAvatarUrl': 'https://i.pravatar.cc/100?img=1',
    },
    {
      'imageUrl': 'https://picsum.photos/seed/trending2/400/600',
      'title': 'Apple event, Macbook pro',
      'userName': 'andokkk2',
      'userAvatarUrl': 'https://i.pravatar.cc/100?img=2',
    },
    {
      'imageUrl': 'https://picsum.photos/seed/trending3/400/600',
      'title': 'Designing the future of UI',
      'userName': 'jason.designer',
      'userAvatarUrl': 'https://i.pravatar.cc/100?img=3',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 250, // Height for the horizontal list
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: trendingVideos.length,
          separatorBuilder: (context, index) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            final video = trendingVideos[index];
            return _VideoCard(
              imageUrl: video['imageUrl']!,
              title: video['title']!,
              userName: video['userName']!,
              userAvatarUrl: video['userAvatarUrl']!,
            );
          },
        ),
      ),
    );
  }
}

class _ExploreGrid extends StatelessWidget {
  const _ExploreGrid();

  final List<String> exploreImages = const [
    'https://picsum.photos/seed/explore1/400/400',
    'https://picsum.photos/seed/explore2/400/400',
    'https://picsum.photos/seed/explore3/400/400',
    'https://picsum.photos/seed/explore4/400/400',
    'https://picsum.photos/seed/explore5/400/400',
    'https://picsum.photos/seed/explore6/400/400',
  ];

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0, // Square items
      ),
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              exploreImages[index],
              fit: BoxFit.cover,
            ),
          );
        },
        childCount: exploreImages.length,
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({
    required this.imageUrl,
    required this.title,
    required this.userName,
    required this.userAvatarUrl,
  });

  final String imageUrl;
  final String title;
  final String userName;
  final String userAvatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180, // Fixed width for horizontal scrolling
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.2), // Darken background slightly
            BlendMode.darken,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Play button in the center
          const Center(
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white,
              size: 48,
            ),
          ),
          // User info at the bottom
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(userAvatarUrl),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      userName,
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
        ],
      ),
    );
  }
}