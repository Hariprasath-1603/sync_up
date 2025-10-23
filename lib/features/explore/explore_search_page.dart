import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../profile/other_user_profile_page.dart';
import '../reels/reels_page_new.dart';
import '../profile/pages/post_viewer_instagram_style.dart';
import '../profile/models/post_model.dart' as profile_post;

class ExploreSearchPage extends StatefulWidget {
  const ExploreSearchPage({super.key});

  @override
  State<ExploreSearchPage> createState() => _ExploreSearchPageState();
}

class _ExploreSearchPageState extends State<ExploreSearchPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late TabController _tabController;
  String _searchQuery = '';
  bool _isSearching = false;

  // Popular searches
  final List<String> _trendingSearches = [
    'sunset',
    'travel',
    'food',
    'fitness',
    'photography',
    'art',
    'music',
    'dance',
  ];

  // Mock data for users
  final List<Map<String, dynamic>> _allUsers = [
    {
      'userId': 'user1',
      'username': '@maria.roze',
      'fullName': 'Maria Rose',
      'avatar': 'https://i.pravatar.cc/150?img=1',
      'verified': true,
      'followers': '234K',
      'bio': 'Travel photographer 📸',
    },
    {
      'userId': 'user2',
      'username': '@alex_travel',
      'fullName': 'Alex Thompson',
      'avatar': 'https://i.pravatar.cc/150?img=2',
      'verified': false,
      'followers': '89K',
      'bio': 'Adventure seeker 🌍',
    },
    {
      'userId': 'user3',
      'username': '@fitness_king',
      'fullName': 'Mike Johnson',
      'avatar': 'https://i.pravatar.cc/150?img=3',
      'verified': true,
      'followers': '456K',
      'bio': 'Fitness coach & nutrition expert 💪',
    },
    {
      'userId': 'user4',
      'username': '@foodie_life',
      'fullName': 'Sarah Lee',
      'avatar': 'https://i.pravatar.cc/150?img=4',
      'verified': false,
      'followers': '123K',
      'bio': 'Food blogger 🍕',
    },
    {
      'userId': 'user5',
      'username': '@dance_queen',
      'fullName': 'Emma Davis',
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'verified': true,
      'followers': '567K',
      'bio': 'Professional dancer 💃',
    },
  ];

  // Mock data for reels
  final List<Map<String, dynamic>> _allReels = [
    {
      'id': 'reel1',
      'thumbnail': 'https://picsum.photos/seed/reel1/400/600',
      'username': '@maria.roze',
      'views': '1.2M',
      'likes': '245K',
    },
    {
      'id': 'reel2',
      'thumbnail': 'https://picsum.photos/seed/reel2/400/600',
      'username': '@alex_travel',
      'views': '890K',
      'likes': '156K',
    },
    {
      'id': 'reel3',
      'thumbnail': 'https://picsum.photos/seed/reel3/400/600',
      'username': '@fitness_king',
      'views': '2.3M',
      'likes': '423K',
    },
    {
      'id': 'reel4',
      'thumbnail': 'https://picsum.photos/seed/reel4/400/600',
      'username': '@foodie_life',
      'views': '654K',
      'likes': '98K',
    },
    {
      'id': 'reel5',
      'thumbnail': 'https://picsum.photos/seed/reel5/400/600',
      'username': '@dance_queen',
      'views': '3.1M',
      'likes': '678K',
    },
  ];

  // Mock data for posts
  final List<Map<String, dynamic>> _allPosts = [
    {
      'id': 'post1',
      'thumbnail': 'https://picsum.photos/seed/post1/400/400',
      'username': '@maria.roze',
      'likes': '12K',
      'comments': '234',
    },
    {
      'id': 'post2',
      'thumbnail': 'https://picsum.photos/seed/post2/400/400',
      'username': '@alex_travel',
      'likes': '8.5K',
      'comments': '156',
    },
    {
      'id': 'post3',
      'thumbnail': 'https://picsum.photos/seed/post3/400/400',
      'username': '@fitness_king',
      'likes': '23K',
      'comments': '567',
    },
    {
      'id': 'post4',
      'thumbnail': 'https://picsum.photos/seed/post4/400/400',
      'username': '@foodie_life',
      'likes': '5.6K',
      'comments': '89',
    },
    {
      'id': 'post5',
      'thumbnail': 'https://picsum.photos/seed/post5/400/400',
      'username': '@dance_queen',
      'likes': '34K',
      'comments': '789',
    },
  ];

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _allUsers;
    return _allUsers.where((user) {
      return user['username'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          user['fullName'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          user['bio'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredReels {
    if (_searchQuery.isEmpty) return _allReels;
    return _allReels.where((reel) {
      return reel['username'].toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredPosts {
    if (_searchQuery.isEmpty) return _allPosts;
    return _allPosts.where((post) {
      return post['username'].toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kDarkBackground : kLightBackground,
      body: Column(
        children: [
          // Search Bar Header
          _buildSearchHeader(isDark),

          // Tab Bar
          _buildTabBar(isDark),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(isDark),
                _buildReelsTab(isDark),
                _buildPostsTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        12,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
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
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.5),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _isSearching = value.isNotEmpty;
                      });
                    },
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search users, reels, posts...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _isSearching = false;
                      });
                    },
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.search,
                      color: isDark ? Colors.white54 : Colors.black45,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.5),
                width: 1.2,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kPrimary.withOpacity(0.8),
                    kPrimary.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_outline, size: 18),
                      const SizedBox(width: 6),
                      Text('Users (${_filteredUsers.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_circle_outline, size: 18),
                      const SizedBox(width: 6),
                      Text('Reels (${_filteredReels.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.grid_on_outlined, size: 18),
                      const SizedBox(width: 6),
                      Text('Posts (${_filteredPosts.length})'),
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

  Widget _buildUsersTab(bool isDark) {
    if (!_isSearching) {
      return _buildTrendingSearches(isDark);
    }

    if (_filteredUsers.isEmpty) {
      return _buildEmptyState(
        isDark,
        'No users found',
        Icons.person_off_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserCard(isDark, user);
      },
    );
  }

  Widget _buildReelsTab(bool isDark) {
    if (!_isSearching) {
      return _buildTrendingSearches(isDark);
    }

    if (_filteredReels.isEmpty) {
      return _buildEmptyState(
        isDark,
        'No reels found',
        Icons.videocam_off_outlined,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredReels.length,
      itemBuilder: (context, index) {
        final reel = _filteredReels[index];
        return _buildReelCard(isDark, reel);
      },
    );
  }

  Widget _buildPostsTab(bool isDark) {
    if (!_isSearching) {
      return _buildTrendingSearches(isDark);
    }

    if (_filteredPosts.isEmpty) {
      return _buildEmptyState(
        isDark,
        'No posts found',
        Icons.image_not_supported_outlined,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemCount: _filteredPosts.length,
      itemBuilder: (context, index) {
        final post = _filteredPosts[index];
        return _buildPostCard(isDark, post);
      },
    );
  }

  Widget _buildTrendingSearches(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'TRENDING SEARCHES',
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _trendingSearches.map((search) {
            return InkWell(
              onTap: () {
                _searchController.text = search;
                setState(() {
                  _searchQuery = search;
                  _isSearching = true;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
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
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, size: 18, color: kPrimary),
                    const SizedBox(width: 8),
                    Text(
                      search,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUserCard(bool isDark, Map<String, dynamic> user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.5),
                width: 1.2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OtherUserProfilePage(
                        userId: user['userId'],
                        username: user['username'],
                        avatarUrl: user['avatar'],
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(user['avatar']),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user['fullName'],
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (user['verified']) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user['username'],
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user['bio'],
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black45,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kPrimary.withOpacity(0.8),
                              kPrimary.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user['followers'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReelCard(bool isDark, Map<String, dynamic> reel) {
    return GestureDetector(
      onTap: () {
        final reelData = ReelData(
          id: reel['id'],
          userId: 'user_${reel['username'].replaceAll('@', '')}',
          username: reel['username'],
          profilePic: 'https://i.pravatar.cc/150?img=1',
          caption: 'Amazing reel! 🔥',
          musicName: 'Trending Audio',
          musicArtist: reel['username'],
          videoUrl: reel['thumbnail'],
          likes:
              int.tryParse(reel['likes'].replaceAll(RegExp(r'[^0-9]'), '')) ??
              0,
          comments: 856,
          shares: 234,
          views:
              int.tryParse(reel['views'].replaceAll(RegExp(r'[^0-9]'), '')) ??
              0,
          isLiked: false,
          isSaved: false,
          isFollowing: false,
          location: null,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ReelsPageNew(initialReel: reelData, initialIndex: 0),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(reel['thumbnail'], fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.visibility,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reel['views'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reel['username'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(bool isDark, Map<String, dynamic> post) {
    return GestureDetector(
      onTap: () {
        final postModel = profile_post.PostModel(
          id: post['id'],
          type: profile_post.PostType.image,
          mediaUrls: [post['thumbnail']],
          thumbnailUrl: post['thumbnail'],
          username: post['username'],
          userAvatar: 'https://i.pravatar.cc/150?img=1',
          timestamp: DateTime.now(),
          caption: 'Amazing post!',
          likes:
              int.tryParse(post['likes'].replaceAll(RegExp(r'[^0-9]'), '')) ??
              0,
          comments: int.tryParse(post['comments']) ?? 0,
          shares: 10,
          views: 10000,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostViewerInstagramStyle(
              initialPost: postModel,
              allPosts: [postModel],
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(post['thumbnail'], fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        post['likes'],
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
                      const Icon(Icons.comment, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        post['comments'],
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

  Widget _buildEmptyState(bool isDark, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: isDark ? Colors.white24 : Colors.black26),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for something else',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
