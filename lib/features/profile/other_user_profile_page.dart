import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/scaffold_with_nav_bar.dart';
import 'models/post_model.dart' as profile_post;
import 'pages/post_viewer_instagram_style.dart';
import 'pages/profile_photo_viewer.dart';
import 'user_posts_page.dart';
import '../chat/individual_chat_page.dart';
import 'highlight_viewer.dart';
import 'other_user_followers_page.dart';

class OtherUserProfilePage extends StatefulWidget {
  final String userId;
  final String username;
  final String? avatarUrl;

  const OtherUserProfilePage({
    super.key,
    required this.userId,
    required this.username,
    this.avatarUrl,
  });

  @override
  State<OtherUserProfilePage> createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;

  final List<String> _posts = List.generate(
    8,
    (index) => 'https://picsum.photos/seed/user_post$index/400/600',
  );
  final List<String> _media = List.generate(
    6,
    (index) => 'https://picsum.photos/seed/user_media$index/600/400',
  );

  // User's active stories (mock data - set to empty list for no stories)
  final List<Map<String, String>> _userStories = [
    {'url': 'https://picsum.photos/seed/userstory1/400/600', 'title': 'Today'},
    {
      'url': 'https://picsum.photos/seed/userstory2/400/600',
      'title': 'Morning',
    },
    {'url': 'https://picsum.photos/seed/userstory3/400/600', 'title': 'Sunset'},
  ];

  // User's story highlights (simple image data)
  final List<Map<String, String>> _storyHighlights = [
    {'url': 'https://picsum.photos/seed/story1/200', 'title': 'Travel'},
    {'url': 'https://picsum.photos/seed/story2/200', 'title': 'Food'},
    {'url': 'https://picsum.photos/seed/story3/200', 'title': 'Friends'},
    {'url': 'https://picsum.photos/seed/story4/200', 'title': 'Events'},
  ];

  bool get hasStories => _userStories.isNotEmpty;

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kDarkBackground : kLightBackground,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // Back Button
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildGlassIconButton(
                  Icons.arrow_back_ios_new_rounded,
                  isDark,
                  () => Navigator.of(context).pop(),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildGlassIconButton(
                    Icons.more_vert_rounded,
                    isDark,
                    () => _showMoreOptions(context),
                  ),
                ),
              ],
            ),
            // Header with Avatar
            SliverToBoxAdapter(
              child: _buildGlassmorphicHeader(context, isDark),
            ),
            // Stats and Bio
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStatsAndBio(context, isDark),
              ),
            ),
            // Story Highlights
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: _buildStoryHighlights(isDark),
              ),
            ),
            // Tab Bar
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
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPostGrid(_posts, isDark),
              _buildPostGrid(_media, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // Glassmorphic Header with Avatar and Actions
  Widget _buildGlassmorphicHeader(BuildContext context, bool isDark) {
    final coverUrl = 'https://picsum.photos/seed/usercover/1200/400';
    final avatarUrl = widget.avatarUrl ?? 'https://i.pravatar.cc/300?img=5';

    return SizedBox(
      height: 280,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Image with Gradient Overlay
          Container(
            height: 200,
            decoration: BoxDecoration(
              image: DecorationImage(
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
                    colors: hasStories
                        ? [
                            Colors.blue.withOpacity(0.8),
                            Colors.blueAccent.withOpacity(0.6),
                          ]
                        : [
                            kPrimary.withOpacity(0.8),
                            kPrimary.withOpacity(0.4),
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: hasStories
                          ? Colors.blue.withOpacity(0.3)
                          : kPrimary.withOpacity(0.3),
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
                    onTap: hasStories ? () => _openUserStories(context) : null,
                    onLongPress: () =>
                        _openProfilePhotoViewer(context, avatarUrl),
                    child: Hero(
                      tag: 'profile_photo_${widget.username}',
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

  // Open User Stories
  void _openUserStories(BuildContext context) {
    if (_userStories.isEmpty) return;

    final navVisibility = NavBarVisibilityScope.maybeOf(context);
    navVisibility?.value = false;

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => HighlightViewer(
              highlights: _userStories,
              initialIndex: 0,
              username: widget.username,
            ),
          ),
        )
        .whenComplete(() {
          navVisibility?.value = true;
        });
  }

  // Open Profile Photo Viewer
  void _openProfilePhotoViewer(BuildContext context, String photoUrl) {
    final navVisibility = NavBarVisibilityScope.maybeOf(context);
    navVisibility?.value = false;

    Navigator.of(context)
        .push(
          PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.black87,
            pageBuilder: (context, animation, secondaryAnimation) {
              return ProfilePhotoViewer(
                photoUrl: photoUrl,
                username: widget.username,
                isOwnProfile: false,
                onFollow: () {
                  setState(() {
                    _isFollowing = !_isFollowing;
                  });
                  Navigator.of(context).pop();
                },
                onShare: () {
                  // Handle share action
                  Navigator.of(context).pop();
                },
                onCopyLink: () {
                  // Handle copy link action
                  Navigator.of(context).pop();
                },
                onQRCode: () {
                  // Handle QR code action
                  Navigator.of(context).pop();
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
          navVisibility?.value = true;
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

  Widget _buildStatsAndBio(BuildContext context, bool isDark) {
    return Column(
      children: [
        Text(
          widget.username,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Photographer | Travel enthusiast 📸',
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
            'bio.link.io/${widget.username.toLowerCase()}',
            style: TextStyle(
              color: kPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Follow and Message Buttons
        Row(
          children: [
            Expanded(flex: 2, child: _buildFollowButton(isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildMessageButton(isDark)),
          ],
        ),
        const SizedBox(height: 24),
        // Stats Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('87', 'Posts', isDark, () {
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
            _buildStatItem('523', 'Following', isDark, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OtherUserFollowersPage(
                    username: widget.username,
                    userId: widget.userId,
                    initialTab: 1,
                  ),
                ),
              );
            }),
            Container(
              width: 1,
              height: 40,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            ),
            _buildStatItem('45.2k', 'Followers', isDark, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OtherUserFollowersPage(
                    username: widget.username,
                    userId: widget.userId,
                    initialTab: 0,
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  // Follow Button
  Widget _buildFollowButton(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: _isFollowing
                ? null
                : LinearGradient(colors: [kPrimary.withOpacity(0.8), kPrimary]),
            color: _isFollowing
                ? (isDark ? Colors.white : Colors.black).withOpacity(0.1)
                : null,
            borderRadius: BorderRadius.circular(20),
            border: _isFollowing
                ? Border.all(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(
                      0.2,
                    ),
                    width: 1.5,
                  )
                : null,
            boxShadow: _isFollowing
                ? null
                : [
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
                setState(() {
                  _isFollowing = !_isFollowing;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                child: Center(
                  child: Text(
                    _isFollowing ? 'Following' : 'Follow',
                    style: TextStyle(
                      color: _isFollowing
                          ? (isDark ? Colors.white : Colors.black87)
                          : Colors.white,
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
    );
  }

  // Message Button
  Widget _buildMessageButton(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final navVisibility = NavBarVisibilityScope.maybeOf(context);
                navVisibility?.value = false;

                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => IndividualChatPage(
                          userName: widget.username,
                          userId: widget.userId,
                        ),
                      ),
                    )
                    .whenComplete(() {
                      navVisibility?.value = true;
                    });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                child: Center(
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: isDark ? Colors.white : Colors.black87,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: statWidget,
    );
  }

  Widget _buildStoryHighlights(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Story Highlights',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _storyHighlights.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final story = _storyHighlights[index];
              return _buildStoryItem(story, isDark, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStoryItem(Map<String, String> story, bool isDark, int index) {
    return SizedBox(
      width: 76,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              final navVisibility = NavBarVisibilityScope.maybeOf(context);
              navVisibility?.value = false;

              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => HighlightViewer(
                        highlights: _storyHighlights,
                        initialIndex: index,
                        username: widget.username,
                      ),
                    ),
                  )
                  .whenComplete(() {
                    navVisibility?.value = true;
                  });
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
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
        username: widget.username,
        userAvatar: widget.avatarUrl ?? 'https://i.pravatar.cc/150?img=5',
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

  void _showMoreOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Hide navigation bar when showing bottom sheet
    final navVisibility = NavBarVisibilityScope.maybeOf(context);
    navVisibility?.value = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: (isDark ? kDarkBackground : Colors.white).withOpacity(
                  0.9,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBottomSheetOption(
                    icon: Icons.block_outlined,
                    label: 'Block',
                    isDark: isDark,
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement block
                    },
                  ),
                  _buildBottomSheetOption(
                    icon: Icons.report_outlined,
                    label: 'Report',
                    isDark: isDark,
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement report
                    },
                  ),
                  _buildBottomSheetOption(
                    icon: Icons.share_outlined,
                    label: 'Share Profile',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement share
                    },
                  ),
                  _buildBottomSheetOption(
                    icon: Icons.qr_code_rounded,
                    label: 'QR Code',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement QR code
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      // Show navigation bar when bottom sheet closes
      navVisibility?.value = true;
    });
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String label,
    required bool isDark,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? Colors.red
            : (isDark ? Colors.white70 : Colors.black87),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive
              ? Colors.red
              : (isDark ? Colors.white : Colors.black87),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
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
