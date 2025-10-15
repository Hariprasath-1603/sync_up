import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class CategoryPage extends StatefulWidget {
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;

  const CategoryPage({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0; // 0 = Posts, 1 = Reels

  // Sample posts for each category
  final Map<String, List<Map<String, String>>> _categoryPosts = {
    'Trending': [
      {
        'imageUrl': 'https://picsum.photos/seed/trend1/600/800',
        'likes': '245K',
        'comments': '1.2K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/trend2/600/800',
        'likes': '189K',
        'comments': '856',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/trend3/600/800',
        'likes': '312K',
        'comments': '2.1K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/trend4/600/800',
        'likes': '428K',
        'comments': '3.5K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/trend5/600/800',
        'likes': '156K',
        'comments': '942',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/trend6/600/800',
        'likes': '278K',
        'comments': '1.8K',
      },
    ],
    'Music': [
      {
        'imageUrl': 'https://picsum.photos/seed/music1/600/800',
        'likes': '167K',
        'comments': '723',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/music2/600/800',
        'likes': '234K',
        'comments': '1.4K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/music3/600/800',
        'likes': '189K',
        'comments': '892',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/music4/600/800',
        'likes': '312K',
        'comments': '2.3K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/music5/600/800',
        'likes': '145K',
        'comments': '634',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/music6/600/800',
        'likes': '298K',
        'comments': '1.9K',
      },
    ],
    'Learn': [
      {
        'imageUrl': 'https://picsum.photos/seed/learn1/600/800',
        'likes': '123K',
        'comments': '567',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/learn2/600/800',
        'likes': '198K',
        'comments': '1.1K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/learn3/600/800',
        'likes': '156K',
        'comments': '823',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/learn4/600/800',
        'likes': '267K',
        'comments': '1.7K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/learn5/600/800',
        'likes': '134K',
        'comments': '692',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/learn6/600/800',
        'likes': '245K',
        'comments': '1.5K',
      },
    ],
    'Gaming': [
      {
        'imageUrl': 'https://picsum.photos/seed/game1/600/800',
        'likes': '356K',
        'comments': '2.8K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/game2/600/800',
        'likes': '412K',
        'comments': '3.2K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/game3/600/800',
        'likes': '289K',
        'comments': '1.9K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/game4/600/800',
        'likes': '534K',
        'comments': '4.1K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/game5/600/800',
        'likes': '298K',
        'comments': '2.3K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/game6/600/800',
        'likes': '445K',
        'comments': '3.6K',
      },
    ],
    'Sports': [
      {
        'imageUrl': 'https://picsum.photos/seed/sport1/600/800',
        'likes': '278K',
        'comments': '1.8K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/sport2/600/800',
        'likes': '345K',
        'comments': '2.4K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/sport3/600/800',
        'likes': '412K',
        'comments': '3.1K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/sport4/600/800',
        'likes': '198K',
        'comments': '1.2K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/sport5/600/800',
        'likes': '389K',
        'comments': '2.7K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/sport6/600/800',
        'likes': '456K',
        'comments': '3.5K',
      },
    ],
    'Fashion': [
      {
        'imageUrl': 'https://picsum.photos/seed/fashion1/600/800',
        'likes': '234K',
        'comments': '1.6K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/fashion2/600/800',
        'likes': '389K',
        'comments': '2.9K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/fashion3/600/800',
        'likes': '312K',
        'comments': '2.1K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/fashion4/600/800',
        'likes': '456K',
        'comments': '3.4K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/fashion5/600/800',
        'likes': '267K',
        'comments': '1.8K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/fashion6/600/800',
        'likes': '398K',
        'comments': '2.6K',
      },
    ],
  };

  // Sample reels for each category
  final Map<String, List<Map<String, String>>> _categoryReels = {
    'Trending': [
      {
        'imageUrl': 'https://picsum.photos/seed/treel1/400/700',
        'views': '1.2M',
        'duration': '0:15',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/treel2/400/700',
        'views': '856K',
        'duration': '0:23',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/treel3/400/700',
        'views': '2.3M',
        'duration': '0:18',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/treel4/400/700',
        'views': '3.1M',
        'duration': '0:30',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/treel5/400/700',
        'views': '945K',
        'duration': '0:12',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/treel6/400/700',
        'views': '1.8M',
        'duration': '0:25',
      },
    ],
    'Music': [
      {
        'imageUrl': 'https://picsum.photos/seed/mreel1/400/700',
        'views': '678K',
        'duration': '0:20',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/mreel2/400/700',
        'views': '1.4M',
        'duration': '0:28',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/mreel3/400/700',
        'views': '892K',
        'duration': '0:16',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/mreel4/400/700',
        'views': '2.1M',
        'duration': '0:32',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/mreel5/400/700',
        'views': '723K',
        'duration': '0:14',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/mreel6/400/700',
        'views': '1.6M',
        'duration': '0:24',
      },
    ],
    'Learn': [
      {
        'imageUrl': 'https://picsum.photos/seed/lreel1/400/700',
        'views': '567K',
        'duration': '0:45',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/lreel2/400/700',
        'views': '1.1M',
        'duration': '0:38',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/lreel3/400/700',
        'views': '823K',
        'duration': '0:52',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/lreel4/400/700',
        'views': '1.7M',
        'duration': '0:41',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/lreel5/400/700',
        'views': '692K',
        'duration': '0:48',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/lreel6/400/700',
        'views': '1.3M',
        'duration': '0:55',
      },
    ],
    'Gaming': [
      {
        'imageUrl': 'https://picsum.photos/seed/greel1/400/700',
        'views': '2.8M',
        'duration': '0:22',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/greel2/400/700',
        'views': '3.5M',
        'duration': '0:27',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/greel3/400/700',
        'views': '1.9M',
        'duration': '0:19',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/greel4/400/700',
        'views': '4.2M',
        'duration': '0:35',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/greel5/400/700',
        'views': '2.4M',
        'duration': '0:21',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/greel6/400/700',
        'views': '3.8M',
        'duration': '0:29',
      },
    ],
    'Sports': [
      {
        'imageUrl': 'https://picsum.photos/seed/sreel1/400/700',
        'views': '1.8M',
        'duration': '0:17',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/sreel2/400/700',
        'views': '2.6M',
        'duration': '0:24',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/sreel3/400/700',
        'views': '3.2M',
        'duration': '0:31',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/sreel4/400/700',
        'views': '1.5M',
        'duration': '0:19',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/sreel5/400/700',
        'views': '2.9M',
        'duration': '0:26',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/sreel6/400/700',
        'views': '3.7M',
        'duration': '0:33',
      },
    ],
    'Fashion': [
      {
        'imageUrl': 'https://picsum.photos/seed/freel1/400/700',
        'views': '1.6M',
        'duration': '0:20',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/freel2/400/700',
        'views': '2.9M',
        'duration': '0:28',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/freel3/400/700',
        'views': '2.1M',
        'duration': '0:23',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/freel4/400/700',
        'views': '3.4M',
        'duration': '0:35',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/freel5/400/700',
        'views': '1.8M',
        'duration': '0:18',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/freel6/400/700',
        'views': '2.6M',
        'duration': '0:25',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get currentPosts =>
      _categoryPosts[widget.categoryName] ?? [];
  List<Map<String, String>> get currentReels =>
      _categoryReels[widget.categoryName] ?? [];

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
              // Tab Bar
              _buildTabBar(isDark),
              const SizedBox(height: 16),
              // Content Grid
              Expanded(
                child: _selectedTab == 0
                    ? _buildPostsGrid(isDark)
                    : _buildReelsGrid(isDark),
              ),
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
                // Category Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.categoryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.categoryIcon,
                    color: widget.categoryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.categoryName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${currentPosts.length + currentReels.length} items',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Search Button
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.08),
                      ]
                    : [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.7),
                      ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [kPrimary, kPrimary.withOpacity(0.8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              padding: const EdgeInsets.all(4),
              tabs: [
                Tab(text: '${currentPosts.length} Posts'),
                Tab(text: '${currentReels.length} Reels'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostsGrid(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: currentPosts.length,
      itemBuilder: (context, index) {
        final post = currentPosts[index];
        return _buildPostCard(post, isDark);
      },
    );
  }

  Widget _buildReelsGrid(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.6,
      ),
      itemCount: currentReels.length,
      itemBuilder: (context, index) {
        final reel = currentReels[index];
        return _buildReelCard(reel, isDark);
      },
    );
  }

  Widget _buildPostCard(Map<String, String> post, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          Image.network(post['imageUrl']!, fit: BoxFit.cover),
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
          // Stats
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      post['likes']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.comment, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      post['comments']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  Widget _buildReelCard(Map<String, String> reel, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          Image.network(reel['imageUrl']!, fit: BoxFit.cover),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          // Play Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          // Duration Badge
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                reel['duration']!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Views
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                const Icon(
                  Icons.play_circle_outline_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  reel['views']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
