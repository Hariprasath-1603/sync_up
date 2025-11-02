import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/post_provider.dart';
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
import 'highlight_viewer.dart';
import '../settings/settings_home_page.dart';
import 'widgets/unified_post_options_sheet.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load user posts from Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final postProvider = context.read<PostProvider>();
      final userId = authProvider.currentUserId;

      if (userId != null) {
        postProvider.loadUserPosts(userId);
      }
    });
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
                    _buildPostGridFromFirestore(context, isDark),
                    _buildPostGridFromFirestore(context, isDark),
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
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final avatarUrl =
        currentUser?.photoURL ?? 'https://i.pravatar.cc/300?img=13';
    final displayName =
        currentUser?.displayName ?? currentUser?.username ?? 'Your Name';
    final heroTag =
        'profile_photo_${authProvider.currentUserId ?? displayName}';

    return SizedBox(
      height: 280,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Image with Gradient Overlay - Make it tappable
          GestureDetector(
            onTap: () {
              // TODO: Open cover photo viewer/editor
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cover photo clicked')),
              );
            },
            child: Container(
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
          ),
          // Edit Cover Photo Button (Top Left)
          Positioned(
            top: 16,
            left: 16,
            child: _buildGlassIconButton(Icons.edit, isDark, () {
              // TODO: Implement cover photo edit
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Edit cover photo')));
            }),
          ),
          // Settings Button (Top Right)
          Positioned(
            top: 16,
            right: 16,
            child: _buildGlassIconButton(Icons.settings_outlined, isDark, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsHomePage(),
                ),
              );
            }),
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
                    onTap: () => _openProfilePhotoViewer(context, avatarUrl),
                    child: Hero(
                      tag: heroTag,
                      child: CircleAvatar(
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
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final displayName =
        currentUser?.displayName ?? currentUser?.username ?? 'You';
    final isOwn = true; // since this is MyProfilePage

    Navigator.of(context)
        .push(
          PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.black87,
            pageBuilder: (context, animation, secondaryAnimation) {
              return ProfilePhotoViewer(
                photoUrl: photoUrl,
                username: displayName,
                isOwnProfile: isOwn,
                onFollow: () {},
                onShare: () {},
                onCopyLink: () {},
                onQRCode: () {},
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
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final displayName =
        currentUser?.displayName ?? currentUser?.username ?? 'Your Name';

    return Column(
      children: [
        Text(
          displayName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          currentUser?.bio ?? 'Add a short bio about yourself',
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
            // Build a safe profile link fallback from username or displayName
            (currentUser != null
                ? 'bio.link.io/${currentUser.username}'
                : 'bio.link.io/yourprofile'),
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
            _buildStatItem(
              (currentUser?.postsCount ?? 0).toString(),
              'Posts',
              isDark,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserPostsPage(),
                  ),
                );
              },
            ),
            Container(
              width: 1,
              height: 40,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            ),
            _buildStatItem(
              (currentUser?.followingCount ?? 0).toString(),
              'Following',
              isDark,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const FollowersFollowingPage(initialTab: 1),
                  ),
                );
              },
            ),
            Container(
              width: 1,
              height: 40,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            ),
            _buildStatItem(
              (currentUser?.followersCount ?? 0).toString(),
              'Followers',
              isDark,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const FollowersFollowingPage(initialTab: 0),
                  ),
                );
              },
            ),
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

  Widget _buildPostGridFromFirestore(BuildContext context, bool isDark) {
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final bottomPadding = bottomSafeArea + 210;

    final authProvider = context.watch<AuthProvider>();
    final postProvider = context.watch<PostProvider>();
    final userId = authProvider.currentUserId;

    if (userId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Please sign in to view your posts',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final userPosts = postProvider.getUserPosts(userId);

    if (userPosts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: isDark ? Colors.white24 : Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No posts yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share your first photo or video',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      itemCount: userPosts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final post = userPosts[index];
        return GestureDetector(
          onTap: () => _openFirestorePostViewer(context, userPosts, index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  post.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 48,
                      color: isDark ? Colors.white24 : Colors.grey[400],
                    ),
                  ),
                ),
                // Glass overlay
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
                // Post stats overlay
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatCount(post.likes),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Three-dot menu button (own posts)
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: () {
                      UnifiedPostOptionsSheet.show(
                        context,
                        post: post,
                        isOwnPost: true,
                        onPostUpdated: () {
                          final postProvider = context.read<PostProvider>();
                          final authProvider = context.read<AuthProvider>();
                          if (authProvider.currentUserId != null) {
                            postProvider.loadUserPosts(
                              authProvider.currentUserId!,
                            );
                          }
                        },
                        onPostDeleted: () {
                          final postProvider = context.read<PostProvider>();
                          final authProvider = context.read<AuthProvider>();
                          if (authProvider.currentUserId != null) {
                            postProvider.loadUserPosts(
                              authProvider.currentUserId!,
                            );
                          }
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.more_vert,
                        size: 18,
                        color: Colors.white,
                      ),
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

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _openFirestorePostViewer(
    BuildContext context,
    List<dynamic> posts,
    int initialIndex,
  ) {
    // Convert Firestore PostModel to profile PostModel
    final profilePosts = posts.map((post) {
      return profile_post.PostModel(
        id: post.id,
        userId: post.userId,
        type: profile_post.PostType.image,
        mediaUrls: post.mediaUrls,
        thumbnailUrl: post.thumbnailUrl,
        username: post.username,
        userAvatar: post.userAvatar,
        timestamp: post.timestamp,
        caption: post.caption,
        likes: post.likes,
        comments: post.comments,
        shares: post.shares,
        views: post.views,
        tags: post.tags,
        location: post.location,
        musicName: post.musicName,
        musicArtist: post.musicArtist,
        isLiked: post.isLiked,
        isSaved: post.isSaved,
        isFollowing: post.isFollowing,
      );
    }).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PostViewerInstagramStyle(
          initialPost: profilePosts[initialIndex],
          allPosts: profilePosts,
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
