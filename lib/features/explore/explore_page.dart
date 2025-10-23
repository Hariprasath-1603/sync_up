import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/scaffold_with_nav_bar.dart';
import '../profile/pages/post_viewer_instagram_style.dart';
import '../profile/models/post_model.dart' as profile_post;
import '../reels/reels_page_new.dart';
import 'explore_search_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with SingleTickerProviderStateMixin {
  String? _selectedCategory;
  IconData? _selectedCategoryIcon;
  Color? _selectedCategoryColor;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String? category, IconData? icon, Color? color) {
    setState(() {
      _selectedCategory = category;
      _selectedCategoryIcon = icon;
      _selectedCategoryColor = color;
    });
  }

  // Category posts data
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
        'likes': '145K',
        'comments': '732',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/learn4/600/800',
        'likes': '267K',
        'comments': '1.7K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/learn5/600/800',
        'likes': '112K',
        'comments': '489',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/learn6/600/800',
        'likes': '223K',
        'comments': '1.3K',
      },
    ],
    'Gaming': [
      {
        'imageUrl': 'https://picsum.photos/seed/game1/600/800',
        'likes': '334K',
        'comments': '2.4K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/game2/600/800',
        'likes': '289K',
        'comments': '1.9K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/game3/600/800',
        'likes': '412K',
        'comments': '3.1K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/game4/600/800',
        'likes': '156K',
        'comments': '876',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/game5/600/800',
        'likes': '298K',
        'comments': '2.2K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/game6/600/800',
        'likes': '378K',
        'comments': '2.8K',
      },
    ],
    'Sports': [
      {
        'imageUrl': 'https://picsum.photos/seed/sport1/600/800',
        'likes': '445K',
        'comments': '3.2K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/sport2/600/800',
        'likes': '289K',
        'comments': '1.8K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/sport3/600/800',
        'likes': '367K',
        'comments': '2.5K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/sport4/600/800',
        'likes': '198K',
        'comments': '1.1K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/sport5/600/800',
        'likes': '423K',
        'comments': '3.4K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/sport6/600/800',
        'likes': '312K',
        'comments': '2.3K',
      },
    ],
    'Fashion': [
      {
        'imageUrl': 'https://picsum.photos/seed/fashion1/600/800',
        'likes': '256K',
        'comments': '1.5K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/fashion2/600/800',
        'likes': '334K',
        'comments': '2.1K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/fashion3/600/800',
        'likes': '189K',
        'comments': '967',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/fashion4/600/800',
        'likes': '412K',
        'comments': '3.0K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/fashion5/600/800',
        'likes': '223K',
        'comments': '1.3K',
      },
      {
        'imageUrl': 'https://picsum.photos/seed/fashion6/600/800',
        'likes': '367K',
        'comments': '2.6K',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0B0E13),
                  const Color(0xFF1A1D29),
                  const Color(0xFF0B0E13),
                ]
              : [
                  const Color(0xFFF6F7FB),
                  const Color(0xFFE8ECFF),
                  const Color(0xFFF6F7FB),
                ],
        ),
      ),
      child: SafeArea(
        child: _selectedCategory == null
            ? CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    pinned: false,
                    toolbarHeight: 140,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const _SearchBar(),
                          const SizedBox(height: 16),
                          _CategoryChips(
                            onCategorySelected: _onCategorySelected,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _SectionTitle(title: 'Trending Videos'),
                    ),
                  ),
                  const _TrendingVideoGrid(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _SectionTitle(title: 'Explore'),
                    ),
                  ),
                  const _ExploreGrid(),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              )
            : _buildCategoryView(isDark),
      ),
    );
  }

  Widget _buildCategoryView(bool isDark) {
    final posts = _categoryPosts[_selectedCategory] ?? [];
    final reels = posts; // Using same data for reels demonstration

    return Column(
      children: [
        // Header with back button and category info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () => _onCategorySelected(null, null, null),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedCategoryColor?.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _selectedCategoryIcon,
                  color: _selectedCategoryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _selectedCategory!,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        // Tabs with glassmorphic design
        Padding(
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
                  unselectedLabelColor: isDark
                      ? Colors.white70
                      : Colors.black54,
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
                    Tab(text: '${posts.length} Posts'),
                    Tab(text: '${reels.length} Reels'),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Posts Grid
              GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 0.75,
                ),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _CategoryPostCard(
                    imageUrl: post['imageUrl']!,
                    likes: post['likes']!,
                    comments: post['comments']!,
                  );
                },
              ),
              // Reels Grid
              GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 0.75,
                ),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _CategoryPostCard(
                    imageUrl: post['imageUrl']!,
                    likes: post['likes']!,
                    comments: post['comments']!,
                    isReel: true,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Helper Widgets for ExplorePage ---

// Section Title Widget
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ExploreSearchPage()),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                    ? Colors.white.withOpacity(0.25)
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
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: isDark
                      ? Colors.white70
                      : Colors.black.withOpacity(0.6),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search Syncup',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white60
                          : Colors.black.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.mic_rounded,
                  color: isDark
                      ? Colors.white60
                      : Colors.black.withOpacity(0.5),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.onCategorySelected});

  final void Function(String?, IconData?, Color?) onCategorySelected;

  final List<Map<String, dynamic>> categories = const [
    {
      'label': 'Trending',
      'icon': Icons.local_fire_department,
      'color': Colors.redAccent,
    },
    {'label': 'Music', 'icon': Icons.music_note, 'color': Colors.blueAccent},
    {'label': 'Learn', 'icon': Icons.lightbulb, 'color': Colors.orangeAccent},
    {'label': 'Gaming', 'icon': Icons.gamepad, 'color': Colors.greenAccent},
    {
      'label': 'Sports',
      'icon': Icons.sports_basketball,
      'color': Colors.purpleAccent,
    },
    {'label': 'Fashion', 'icon': Icons.checkroom, 'color': Colors.pinkAccent},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () {
              onCategorySelected(
                category['label'],
                category['icon'],
                category['color'],
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              Colors.white.withOpacity(0.12),
                              Colors.white.withOpacity(0.06),
                            ]
                          : [
                              Colors.white.withOpacity(0.85),
                              Colors.white.withOpacity(0.65),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.white.withOpacity(0.5),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category['icon'],
                        color: category['color'],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category['label'],
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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

  void _openPostViewer(BuildContext context, String imageUrl) {
    final navVisibility = NavBarVisibilityScope.maybeOf(context);
    navVisibility?.value = false;

    // Create a mock post model
    final post = profile_post.PostModel(
      id: imageUrl,
      type: profile_post.PostType.image,
      mediaUrls: [imageUrl],
      thumbnailUrl: imageUrl,
      username: '@explorer',
      userAvatar: 'https://i.pravatar.cc/150?img=10',
      timestamp: DateTime.now(),
      caption: 'Explore post',
      likes: 1234,
      comments: 56,
      shares: 10,
      views: 10000,
    );

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                PostViewerInstagramStyle(initialPost: post, allPosts: [post]),
          ),
        )
        .whenComplete(() {
          navVisibility?.value = true;
        });
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          return GestureDetector(
            onTap: () => _openPostViewer(context, exploreImages[index]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Background image
                  Positioned.fill(
                    child: Image.network(
                      exploreImages[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Glass overlay on hover effect
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }, childCount: exploreImages.length),
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

  void _openReelPage(BuildContext context) {
    // Create a ReelData object from the video data
    final reelData = ReelData(
      id: 'explore_${imageUrl.hashCode}',
      userId: 'user_${userName.replaceAll('.', '_')}',
      username: '@$userName',
      profilePic: userAvatarUrl,
      caption: title,
      musicName: 'Original Audio',
      musicArtist: '@$userName',
      videoUrl: imageUrl,
      likes: 12400,
      comments: 856,
      shares: 234,
      views: 98000,
      isLiked: false,
      isSaved: false,
      isFollowing: false,
      location: null,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ReelsPageNew(initialReel: reelData, initialIndex: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openReelPage(context),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Image.network(imageUrl, fit: BoxFit.cover),
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Play button in the center
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.15),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              // Glass user info at the bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              shadows: [
                                Shadow(color: Colors.black45, blurRadius: 4),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 10,
                                  backgroundImage: NetworkImage(userAvatarUrl),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
}

class _CategoryPostCard extends StatelessWidget {
  const _CategoryPostCard({
    required this.imageUrl,
    required this.likes,
    required this.comments,
    this.isReel = false,
  });

  final String imageUrl;
  final String likes;
  final String comments;
  final bool isReel;

  void _openPostViewer(BuildContext context) {
    final navVisibility = NavBarVisibilityScope.maybeOf(context);
    navVisibility?.value = false;

    // Create a mock post model
    final post = profile_post.PostModel(
      id: imageUrl,
      type: profile_post.PostType.image,
      mediaUrls: [imageUrl],
      thumbnailUrl: imageUrl,
      username: '@explorer',
      userAvatar: 'https://i.pravatar.cc/150?img=10',
      timestamp: DateTime.now(),
      caption: 'Explore post',
      likes: int.tryParse(likes.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      comments: int.tryParse(comments.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      shares: 10,
      views: 1000,
    );

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                PostViewerInstagramStyle(initialPost: post, allPosts: [post]),
          ),
        )
        .whenComplete(() {
          navVisibility?.value = true;
        });
  }

  void _openReelPage(BuildContext context) {
    // Create a ReelData object from the category post data
    final reelData = ReelData(
      id: 'category_${imageUrl.hashCode}',
      userId: 'user_explorer_${imageUrl.hashCode}',
      username: '@explorer',
      profilePic: 'https://i.pravatar.cc/150?img=10',
      caption: 'Amazing content! 🔥',
      musicName: 'Trending Audio',
      musicArtist: '@TrendingMusic',
      videoUrl: imageUrl,
      likes: int.tryParse(likes.replaceAll(RegExp(r'[^0-9]'), '')) ?? 12400,
      comments: int.tryParse(comments.replaceAll(RegExp(r'[^0-9]'), '')) ?? 856,
      shares: 234,
      views: 98000,
      isLiked: false,
      isSaved: false,
      isFollowing: false,
      location: null,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ReelsPageNew(initialReel: reelData, initialIndex: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isReel) {
          _openReelPage(context);
        } else {
          _openPostViewer(context);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(imageUrl, fit: BoxFit.cover),
            // Dark gradient overlay
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
            // Reel icon if it's a reel
            if (isReel)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 24,
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
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
