import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/scaffold_with_nav_bar.dart';
import 'edit_profile_page.dart';
import 'followers_following_page.dart';
import 'user_posts_page.dart';
import 'stories_archive_page.dart';
import '../stories/storyverse_page.dart';
import 'models/post_model.dart' as profile_post;
import 'pages/post_viewer_instagram_style.dart';
import 'pages/profile_photo_viewer.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _posts = List.generate(
    8,
    (index) => 'https://picsum.photos/seed/post$index/400/600',
  );
  final List<String> _media = List.generate(
    6,
    (index) => 'https://picsum.photos/seed/media$index/600/400',
  );

  // User's story collections grouped by category
  final Map<String, List<StoryVerseStory>> _userStoryCollections = {
    'Travel': [
      StoryVerseStory(
        id: 'travel_1',
        ownerName: 'Jane Cooper',
        ownerAvatar: 'https://i.pravatar.cc/150?img=1',
        mood: '✈️ Wanderlust',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        clips: [
          StoryVerseClip(
            id: 'clip_travel_1',
            mode: StoryVerseMode.photo,
            duration: const Duration(seconds: 5),
            caption: 'Beautiful sunset at the beach! 🌅',
            mood: '✈️ Wanderlust',
          ),
          StoryVerseClip(
            id: 'clip_travel_2',
            mode: StoryVerseMode.photo,
            duration: const Duration(seconds: 5),
            caption: 'Mountain views 🏔️',
          ),
        ],
      ),
    ],
    'Food': [
      StoryVerseStory(
        id: 'food_1',
        ownerName: 'Jane Cooper',
        ownerAvatar: 'https://i.pravatar.cc/150?img=1',
        mood: '🍕 Foodie',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        clips: [
          StoryVerseClip(
            id: 'clip_food_1',
            mode: StoryVerseMode.photo,
            duration: const Duration(seconds: 5),
            caption: 'Delicious pasta! 🍝',
            mood: '🍕 Foodie',
          ),
        ],
      ),
    ],
    'Friends': [
      StoryVerseStory(
        id: 'friends_1',
        ownerName: 'Jane Cooper',
        ownerAvatar: 'https://i.pravatar.cc/150?img=1',
        mood: '👥 Squad',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        clips: [
          StoryVerseClip(
            id: 'clip_friends_1',
            mode: StoryVerseMode.photo,
            duration: const Duration(seconds: 5),
            caption: 'Best day with the squad! 💙',
            mood: '👥 Squad',
          ),
        ],
      ),
    ],
    'Hangout': [
      StoryVerseStory(
        id: 'hangout_1',
        ownerName: 'Jane Cooper',
        ownerAvatar: 'https://i.pravatar.cc/150?img=1',
        mood: '🎉 Party',
        timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        clips: [
          StoryVerseClip(
            id: 'clip_hangout_1',
            mode: StoryVerseMode.photo,
            duration: const Duration(seconds: 5),
            caption: 'Fun times! 🎊',
            mood: '🎉 Party',
          ),
        ],
      ),
    ],
  };

  final List<Map<String, String?>> _stories = [
    {'title': 'Add', 'url': null},
    {'title': 'Travel', 'url': 'https://picsum.photos/seed/s1/200'},
    {'title': 'Food', 'url': 'https://picsum.photos/seed/s2/200'},
    {'title': 'Friends', 'url': 'https://picsum.photos/seed/s3/200'},
    {'title': 'Hangout', 'url': 'https://picsum.photos/seed/s4/200'},
  ];

  void _openStoryCollection(String category) {
    final stories = _userStoryCollections[category];
    if (stories != null && stories.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryVerseExperience(
            initialStage: StoryVerseStage.viewer,
            initialStory: stories.first,
            feedStories: stories,
            showEntryStage: false,
          ),
        ),
      );
    }
  }

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
          bottom: false,
          child: CustomScrollView(
            slivers: [
              // Glassmorphism Header
              SliverToBoxAdapter(
                child: _buildGlassmorphicHeader(context, isDark),
              ),
              // Stats and Bio in Glass Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildGlassCard(
                    child: _buildStatsAndBio(context, isDark),
                    isDark: isDark,
                  ),
                ),
              ),
              // Stories Section
              SliverToBoxAdapter(child: _buildStories(context, isDark)),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              // Tab Bar in Glass
              SliverPersistentHeader(
                delegate: _GlassmorphicTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: kPrimary,
                    unselectedLabelColor: isDark ? Colors.white60 : Colors.grey,
                    indicatorColor: kPrimary,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    tabs: const [
                      Tab(text: 'Posts'),
                      Tab(text: 'Media'),
                    ],
                  ),
                  isDark,
                ),
                pinned: true,
              ),
              // Grid Content
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPostGrid(_posts, isDark),
                    _buildPostGrid(_media, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Glassmorphic Header with Avatar and Actions
  Widget _buildGlassmorphicHeader(BuildContext context, bool isDark) {
    const coverUrl = 'https://picsum.photos/seed/cover/1200/400';
    const avatarUrl = 'https://i.pravatar.cc/300?img=13';

    return SizedBox(
      height: 280,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Image with Gradient Overlay
          Container(
            height: 200,
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: NetworkImage(coverUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    (isDark ? kDarkBackground : kLightBackground).withOpacity(
                      0.3,
                    ),
                    (isDark ? kDarkBackground : kLightBackground).withOpacity(
                      0.95,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Settings Button (Top Right)
          Positioned(
            top: 16,
            right: 16,
            child: _buildGlassIconButton(
              Icons.settings_outlined,
              isDark,
              () {},
            ),
          ),
          // Avatar with Glass Effect
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      kPrimary.withOpacity(0.8),
                      kPrimary.withOpacity(0.4),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? kDarkBackground : Colors.white,
                  ),
                  child: GestureDetector(
                    onLongPress: () =>
                        _openProfilePhotoViewer(context, avatarUrl),
                    child: Hero(
                      tag: 'profile_photo_Jane Cooper',
                      child: const CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(avatarUrl),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Open Profile Photo Viewer
  void _openProfilePhotoViewer(BuildContext context, String photoUrl) {
    final navVisibility = NavBarVisibilityScope.maybeOf(context);
    navVisibility?.value = false; // Hide navigation bar

    Navigator.of(context)
        .push(
          PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.black87,
            pageBuilder: (context, animation, secondaryAnimation) {
              return ProfilePhotoViewer(
                photoUrl: photoUrl,
                username: 'Jane Cooper',
                isOwnProfile: true, // Set based on your logic
                onFollow: () {
                  // Handle follow action
                },
                onShare: () {
                  // Handle share action
                },
                onCopyLink: () {
                  // Handle copy link action
                },
                onQRCode: () {
                  // Handle QR code action
                },
              );
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        )
        .whenComplete(() {
          navVisibility?.value = true; // Show navigation bar when closed
        });
  }

  // Glass Icon Button
  Widget _buildGlassIconButton(
    IconData icon,
    bool isDark,
    VoidCallback onPressed,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.15),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: isDark ? Colors.white : Colors.black87,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  // Reusable Glass Card
  Widget _buildGlassCard({required Widget child, required bool isDark}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                (isDark ? Colors.white : Colors.black).withOpacity(0.02),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStatsAndBio(BuildContext context, bool isDark) {
    return Column(
      children: [
        const Text(
          'Jane Cooper',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Apple CEO, Auburn buke, National parks',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'bio.link.io/j.copr',
            style: TextStyle(
              color: kPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Edit Profile Button with Glass Effect
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimary.withOpacity(0.8), kPrimary],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfilePage(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 14,
                    ),
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Stats Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('103', 'Posts', isDark, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserPostsPage()),
              );
            }),
            Container(
              width: 1,
              height: 40,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            ),
            _buildStatItem('870', 'Following', isDark, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const FollowersFollowingPage(initialTab: 1),
                ),
              );
            }),
            Container(
              width: 1,
              height: 40,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            ),
            _buildStatItem('120k', 'Followers', isDark, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const FollowersFollowingPage(initialTab: 0),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String count,
    String label,
    bool isDark,
    VoidCallback? onTap,
  ) {
    final statWidget = Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.grey[600],
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: statWidget,
        ),
      );
    }

    return statWidget;
  }

  Widget _buildStories(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Stories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoriesArchivePage(
                        storyCollections: _userStoryCollections,
                      ),
                    ),
                  );
                },
                child: Text(
                  'View all',
                  style: TextStyle(
                    color: kPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _stories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final s = _stories[index];
                return _buildStoryItem(s, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryItem(Map<String, String?> story, bool isDark) {
    return Column(
      children: [
        if (story['url'] == null)
          // Add Story Button - Now opens Stories Archive
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoriesArchivePage(
                    storyCollections: _userStoryCollections,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kPrimary.withOpacity(0.6),
                        kPrimary.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: kPrimary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 32),
                ),
              ),
            ),
          )
        else
          // Story with Glass Border - Clickable
          GestureDetector(
            onTap: () {
              final category = story['title']!;
              _openStoryCollection(category);
            },
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    kPrimary.withOpacity(0.8),
                    kPrimary.withOpacity(0.4),
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Image.network(
                  story['url']!,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        Text(
          story['title']!,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPostGrid(List<String> images, bool isDark) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _openPostViewer(context, images, index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(images[index], fit: BoxFit.cover),
                // Glass overlay on hover effect
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPostViewer(
    BuildContext context,
    List<String> images,
    int initialIndex,
  ) {
    // Convert image URLs to PostModel list
    final posts = images.map((imageUrl) {
      return profile_post.PostModel(
        id: imageUrl,
        type: profile_post.PostType.image,
        mediaUrls: [imageUrl],
        thumbnailUrl: imageUrl,
        username: 'Jane Cooper', // Current user
        userAvatar: 'https://i.pravatar.cc/150?img=1',
        timestamp: DateTime.now(),
        caption: '',
        likes: 1234,
        comments: 56,
        shares: 12,
        views: 10000,
      );
    }).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PostViewerInstagramStyle(
          initialPost: posts[initialIndex],
          allPosts: posts,
        ),
      ),
    );
  }
}

// Glassmorphic Tab Bar Delegate
class _GlassmorphicTabBarDelegate extends SliverPersistentHeaderDelegate {
  _GlassmorphicTabBarDelegate(this._tabBar, this.isDark);
  final TabBar _tabBar;
  final bool isDark;

  @override
  double get minExtent => _tabBar.preferredSize.height + 10;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 10;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: _tabBar,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_GlassmorphicTabBarDelegate oldDelegate) => false;
}
