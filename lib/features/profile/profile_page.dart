import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/post_provider.dart';
import '../../core/theme.dart';
import '../../core/scaffold_with_nav_bar.dart';
import '../../core/services/image_picker_service.dart';
import '../../core/services/reel_service.dart';
import '../../core/models/reel_model.dart';
import '../../core/utils/responsive_utils.dart';
import 'edit_profile_page.dart';
import 'followers_following_page.dart';
import 'user_posts_page.dart';
import 'models/post_model.dart' as profile_post;
import 'pages/post_viewer_instagram_style.dart';
import 'pages/profile_photo_viewer.dart';
import '../settings/settings_home_page.dart';
import '../reels/pages/reel_feed_page.dart';
import 'widgets/unified_post_options_sheet.dart';
import 'widgets/shimmer_loading_grid.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReelService _reelService = ReelService();
  List<ReelModel> _userReels = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize profile with proper session handling
    _initializeProfile();
  }

  /// Initialize profile with Supabase session check
  Future<void> _initializeProfile() async {
    // Check if user is already authenticated
    final authProvider = context.read<AuthProvider>();

    // Wait a bit for AuthProvider to initialize if needed
    await Future.delayed(const Duration(milliseconds: 100));

    if (authProvider.currentUserId != null) {
      // User session is ready, load posts immediately
      await _loadProfileData();
    } else {
      // Wait for auth state to be ready
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Give AuthProvider time to complete initialization
        int attempts = 0;
        while (attempts < 20) {
          // Max 2 seconds wait
          await Future.delayed(const Duration(milliseconds: 100));
          final userId = context.read<AuthProvider>().currentUserId;
          if (userId != null) {
            await _loadProfileData();
            break;
          }
          attempts++;
        }
      });
    }
  }

  /// Load all profile data (user info + posts + reels)
  Future<void> _loadProfileData() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final postProvider = context.read<PostProvider>();
    final userId = authProvider.currentUserId;

    if (userId == null) return;

    // Reload user data to ensure latest stats (followers, following, posts count)
    await authProvider.reloadUserData(showLoading: false);

    // Load user posts
    postProvider.loadUserPosts(userId);

    // Load user reels
    try {
      final reels = await _reelService.fetchUserReels(userId: userId);
      if (mounted) {
        setState(() {
          _userReels = reels;
        });
      }
      debugPrint('📱 Loaded ${reels.length} reels for user profile');
    } catch (e) {
      debugPrint('❌ Error loading user reels: $e');
    }
  }

  /// Edit cover photo - show bottom sheet with gallery, camera, and cancel options
  Future<void> _editCoverPhoto() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUserId;
    final currentUser = authProvider.currentUser;

    if (userId == null) return;

    final imagePickerService = ImagePickerService();

    await imagePickerService.showImageSourceBottomSheet(
      context: context,
      photoType: PhotoType.cover,
      userId: userId,
      currentImageUrl: currentUser?.coverPhotoUrl,
      onImageUploaded: (url) async {
        // Clear image cache for old cover photo
        if (currentUser?.coverPhotoUrl != null &&
            currentUser!.coverPhotoUrl!.isNotEmpty) {
          final oldImage = NetworkImage(currentUser.coverPhotoUrl!);
          await oldImage.evict();
        }

        // Reload user data to get updated cover photo
        await authProvider.reloadUserData(showLoading: false);

        // Force UI update with smooth transition
        if (mounted) {
          setState(() {});
        }
      },
    );
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
          child: RefreshIndicator(
            onRefresh: _loadProfileData,
            color: kPrimary,
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
                      unselectedLabelColor: isDark
                          ? Colors.white60
                          : Colors.grey,
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
                        Tab(text: 'Reels'),
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
                      _buildPostGridFromFirestore(
                        context,
                        isDark,
                        showAllPosts: true,
                      ),
                      _buildReelsGrid(context, isDark),
                      _buildPostGridFromFirestore(
                        context,
                        isDark,
                        showAllPosts: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Glassmorphic Header with Avatar and Actions
  Widget _buildGlassmorphicHeader(BuildContext context, bool isDark) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final coverUrl =
        currentUser?.coverPhotoUrl ??
        'https://picsum.photos/seed/cover/1200/400';
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
          // Background Image with Gradient Overlay - Make it tappable with smooth fade transition
          GestureDetector(
            onTap: () {
              // View cover photo in full screen
              // TODO: Implement full screen cover photo viewer
            },
            child: SizedBox(
              height: 200,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Use CachedNetworkImage for smooth transitions
                  CachedNetworkImage(
                    imageUrl: coverUrl,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 300),
                    fadeOutDuration: const Duration(milliseconds: 200),
                    placeholder: (context, url) => Container(
                      color: isDark ? Colors.grey[850] : Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 48,
                        color: isDark ? Colors.white24 : Colors.grey[400],
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          (isDark ? kDarkBackground : kLightBackground)
                              .withOpacity(0.3),
                          (isDark ? kDarkBackground : kLightBackground)
                              .withOpacity(0.95),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Edit Cover Photo Button (Top Left)
          Positioned(
            top: 16,
            left: 16,
            child: _buildGlassIconButton(Icons.edit, isDark, _editCoverPhoto),
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
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: avatarUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 300),
                          fadeOutDuration: const Duration(milliseconds: 200),
                          placeholder: (context, url) => Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  kPrimary,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              size: 50,
                              color: kPrimary,
                            ),
                          ),
                        ),
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
          style: TextStyle(
            fontSize: context.rFontSize(20),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: context.rSpacing(4)),
        Text(
          label,
          style: TextStyle(
            fontSize: context.rFontSize(12),
            color: isDark ? Colors.white60 : Colors.grey[600],
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.rRadius(12)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.rSpacing(12),
            vertical: context.rSpacing(8),
          ),
          child: statWidget,
        ),
      );
    }

    return statWidget;
  }

  Widget _buildPostGridFromFirestore(
    BuildContext context,
    bool isDark, {
    bool showAllPosts = true,
  }) {
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

    // Get all user posts and filter based on tab
    var userPosts = postProvider.getUserPosts(userId);

    // If on Media tab, only show posts with images/videos
    if (!showAllPosts) {
      userPosts = userPosts
          .where(
            (post) =>
                post.mediaUrls.isNotEmpty &&
                (post.mediaUrls.first.contains('.jpg') ||
                    post.mediaUrls.first.contains('.jpeg') ||
                    post.mediaUrls.first.contains('.png') ||
                    post.mediaUrls.first.contains('.mp4') ||
                    post.mediaUrls.first.contains('.mov')),
          )
          .toList();
    }

    // Combine user posts and reels
    final totalItems = userPosts.length + _userReels.length;

    if (totalItems == 0) {
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

    // Show shimmer loading while posts are being fetched (when list is empty on first load)
    final hasNeverLoaded =
        userPosts.isEmpty && postProvider.getUserPosts(userId).isEmpty;
    if (hasNeverLoaded) {
      return const ShimmerLoadingGrid(itemCount: 6);
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      itemCount: totalItems,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.gridColumns,
        mainAxisSpacing: context.rSpacing(12),
        crossAxisSpacing: context.rSpacing(12),
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        // Show reels first, then posts
        if (index < _userReels.length) {
          // This is a reel
          final reel = _userReels[index];
          return _buildReelGridItem(context, reel, isDark);
        } else {
          // This is a post
          final postIndex = index - _userReels.length;
          final post = userPosts[postIndex];
          return _buildPostGridItem(
            context,
            post,
            userPosts,
            postIndex,
            isDark,
          );
        }
      },
    );
  }

  /// Build a grid item for a reel
  Widget _buildReelGridItem(BuildContext context, ReelModel reel, bool isDark) {
    final thumbnailUrl = reel.thumbnailUrl ?? reel.videoUrl;

    return GestureDetector(
      onTap: () {
        // Navigate to reel feed page with all user reels starting from this one
        final index = _userReels.indexWhere((r) => r.id == reel.id);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ReelFeedPage(
              initialReels: _userReels,
              initialIndex: index >= 0 ? index : 0,
            ),
          ),
        );
      },
      child: Hero(
        tag: 'reel_${reel.id}',
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.rRadius(20)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Thumbnail image
                CachedNetworkImage(
                  imageUrl: thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDark ? Colors.grey[850] : Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          isDark ? Colors.grey[850]! : Colors.grey[200]!,
                          isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.movie_outlined,
                        size: context.rIconSize(48),
                        color: isDark ? Colors.white24 : Colors.grey[400],
                      ),
                    ),
                  ),
                  fadeInDuration: const Duration(milliseconds: 300),
                  fadeOutDuration: const Duration(milliseconds: 100),
                ),
                // Glass overlay
                Container(
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
                // Play icon (top-left)
                Positioned(
                  top: context.rSpacing(8),
                  left: context.rSpacing(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.rSpacing(8),
                      vertical: context.rSpacing(4),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(context.rRadius(12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: context.rIconSize(16),
                          color: Colors.white,
                        ),
                        if (reel.duration != null) ...[
                          SizedBox(width: context.rSpacing(4)),
                          Text(
                            _formatDuration(reel.duration!),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.rFontSize(11),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // REEL indicator badge (bottom-center) - THIS IS THE KEY FEATURE
                Positioned(
                  bottom: context.rSpacing(8),
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.rSpacing(12),
                        vertical: context.rSpacing(6),
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF4A6CF7),
                            Color(0xFF7C3AED),
                            Color(0xFFEC4899),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                          context.rRadius(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4A6CF7).withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.movie_filter_rounded,
                            size: context.rIconSize(14),
                            color: Colors.white,
                          ),
                          SizedBox(width: context.rSpacing(4)),
                          Text(
                            'REEL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.rFontSize(10),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Views count (bottom-right)
                Positioned(
                  bottom: context.rSpacing(8),
                  right: context.rSpacing(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.rSpacing(8),
                      vertical: context.rSpacing(4),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(context.rRadius(12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_filled,
                          size: context.rIconSize(14),
                          color: Colors.white,
                        ),
                        SizedBox(width: context.rSpacing(4)),
                        Text(
                          _formatCount(reel.viewsCount),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.rFontSize(11),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  /// Build a grid item for a post
  Widget _buildPostGridItem(
    BuildContext context,
    dynamic post,
    List<dynamic> allPosts,
    int postIndex,
    bool isDark,
  ) {
    // Use thumbnail URL for videos, first media URL for images
    final thumbnailUrl = post.isVideo
        ? (post.thumbnailUrl.isNotEmpty
              ? post.thumbnailUrl
              : post.videoUrlOrFirst)
        : (post.mediaUrls.isNotEmpty ? post.mediaUrls.first : '');

    return GestureDetector(
      onTap: () => _openFirestorePostViewer(context, allPosts, postIndex),
      child: Hero(
        tag: 'post_${post.id}',
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.rRadius(20)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Use CachedNetworkImage for better performance
                CachedNetworkImage(
                  imageUrl: thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDark ? Colors.grey[850] : Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          isDark ? Colors.grey[850]! : Colors.grey[200]!,
                          isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            post.isVideo
                                ? Icons.videocam_rounded
                                : Icons.image_not_supported_outlined,
                            size: context.rIconSize(48),
                            color: isDark ? Colors.white24 : Colors.grey[400],
                          ),
                          if (post.isVideo) ...[
                            SizedBox(height: context.rSpacing(8)),
                            Text(
                              'Video',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey[400],
                                fontSize: context.rFontSize(12),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  fadeInDuration: const Duration(milliseconds: 300),
                  fadeOutDuration: const Duration(milliseconds: 100),
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
                // Video indicator (top-left)
                if (post.isVideo)
                  Positioned(
                    top: context.rSpacing(8),
                    left: context.rSpacing(8),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.rSpacing(8),
                        vertical: context.rSpacing(4),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(
                          context.rRadius(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            size: context.rIconSize(16),
                            color: Colors.white,
                          ),
                          if (post.videoDuration != null) ...[
                            SizedBox(width: context.rSpacing(4)),
                            Text(
                              _formatDuration(post.videoDuration!),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.rFontSize(11),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                // Post stats overlay (top-right)
                Positioned(
                  top: context.rSpacing(8),
                  right: context.rSpacing(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.rSpacing(8),
                      vertical: context.rSpacing(4),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(context.rRadius(12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite,
                          size: context.rIconSize(14),
                          color: Colors.white,
                        ),
                        SizedBox(width: context.rSpacing(4)),
                        Text(
                          _formatCount(post.likes),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.rFontSize(12),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Three-dot menu button (bottom-right, repositioned to avoid overlap)
                Positioned(
                  bottom: context.rSpacing(8),
                  right: context.rSpacing(8),
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
                          // Remove post immediately from cache for instant UI update
                          final postProvider = context.read<PostProvider>();
                          postProvider.removePost(post.id);

                          // Also reload user stats
                          final authProvider = context.read<AuthProvider>();
                          if (authProvider.currentUserId != null) {
                            authProvider.reloadUserData(showLoading: false);
                          }
                        },
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(context.rSpacing(6)),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.more_vert,
                        size: context.rIconSize(18),
                        color: Colors.white,
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

  Widget _buildReelsGrid(BuildContext context, bool isDark) {
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final bottomPadding = bottomSafeArea + 210;

    if (_userReels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 64,
                color: isDark ? Colors.white24 : Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No reels yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first reel!',
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
      itemCount: _userReels.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.gridColumns,
        mainAxisSpacing: context.rSpacing(12),
        crossAxisSpacing: context.rSpacing(12),
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final reel = _userReels[index];
        return GestureDetector(
          onTap: () {
            // Navigate to reel feed page starting from this reel
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    ReelFeedPage(initialReels: _userReels, initialIndex: index),
              ),
            );
          },
          child: _buildReelGridItem(context, reel, isDark),
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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '0:${remainingSeconds.toString().padLeft(2, '0')}';
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
        type: post.isVideo
            ? profile_post.PostType.video
            : profile_post.PostType.image,
        mediaUrls: post.mediaUrls,
        thumbnailUrl: post.thumbnailUrl,
        username: post.username,
        userAvatar: post.userAvatar,
        timestamp: post.timestamp,
        caption: post.caption,
        videoUrl: post.videoUrl,
        videoDuration: post.videoDuration,
        mediaType: post.mediaType,
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
