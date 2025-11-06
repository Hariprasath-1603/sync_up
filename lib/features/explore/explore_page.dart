import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import 'search_page.dart';
import '../profile/models/post_model.dart';
import '../profile/pages/post_viewer_page_v2.dart';
import '../reels/reels_page_new.dart';
import '../profile/other_user_profile_page.dart';

enum ContentFilter { all, posts, reels, people }

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _reels = [];
  List<Map<String, dynamic>> _people = [];
  bool _isLoadingPosts = true;
  bool _isLoadingReels = true;
  bool _isLoadingPeople = true;
  int _selectedCategory = 0;
  ContentFilter _selectedFilter = ContentFilter.all;

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.explore_rounded, 'label': 'All'},
    {'icon': Icons.trending_up_rounded, 'label': 'Trending'},
    {'icon': Icons.people_rounded, 'label': 'People'},
    {'icon': Icons.photo_camera_rounded, 'label': 'Photography'},
    {'icon': Icons.sports_basketball_rounded, 'label': 'Sports'},
    {'icon': Icons.palette_rounded, 'label': 'Art'},
    {'icon': Icons.travel_explore_rounded, 'label': 'Travel'},
    {'icon': Icons.restaurant_rounded, 'label': 'Food'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPosts();
    _loadReels();
    _loadPeople();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    try {
      setState(() => _isLoadingPosts = true);

      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        setState(() => _isLoadingPosts = false);
        return;
      }

      final result = await _supabase
          .from('posts')
          .select('id, media_urls, likes_count, comments_count, type, user_id')
          .eq('type', 'image')
          .order('likes_count', ascending: false)
          .limit(30);

      final posts = (result as List)
          .map((post) {
            final mediaUrls = post['media_urls'] != null
                ? List<String>.from(post['media_urls'])
                : <String>[];

            // Filter out placeholder URLs
            final validMediaUrls = mediaUrls.where((url) {
              return !url.contains('picsum.photos') &&
                  !url.contains('placeholder.com') &&
                  !url.contains('pravatar.cc') &&
                  url.isNotEmpty;
            }).toList();

            return {
              'id': post['id'],
              'user_id': post['user_id'],
              'imageUrl': validMediaUrls.isNotEmpty ? validMediaUrls.first : '',
              'likes': post['likes_count'] ?? 0,
              'comments': post['comments_count'] ?? 0,
              'type': 'post',
            };
          })
          .where((post) => post['imageUrl'].toString().isNotEmpty)
          .toList();

      setState(() {
        _posts = posts;
        _isLoadingPosts = false;
      });
    } catch (e) {
      print('Error loading posts: $e');
      setState(() => _isLoadingPosts = false);
    }
  }

  Future<void> _loadReels() async {
    try {
      setState(() => _isLoadingReels = true);

      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        setState(() => _isLoadingReels = false);
        return;
      }

      final result = await _supabase
          .from('posts')
          .select(
            'id, media_urls, thumbnail_url, likes_count, views_count, user_id',
          )
          .eq('type', 'reel')
          .order('views_count', ascending: false)
          .limit(30);

      final reels = (result as List)
          .map((post) {
            final mediaUrls = post['media_urls'] != null
                ? List<String>.from(post['media_urls'])
                : <String>[];

            // Filter out placeholder URLs
            final validMediaUrls = mediaUrls.where((url) {
              return !url.contains('picsum.photos') &&
                  !url.contains('placeholder.com') &&
                  !url.contains('pravatar.cc') &&
                  url.isNotEmpty;
            }).toList();

            final thumbnailUrl =
                post['thumbnail_url'] ??
                (validMediaUrls.isNotEmpty ? validMediaUrls.first : '');
            return {
              'id': post['id'],
              'user_id': post['user_id'],
              'imageUrl': thumbnailUrl,
              'videoUrl': validMediaUrls.isNotEmpty ? validMediaUrls.first : '',
              'likes': post['likes_count'] ?? 0,
              'views': post['views_count'] ?? 0,
              'type': 'reel',
            };
          })
          .where((reel) => reel['imageUrl'].toString().isNotEmpty)
          .toList();

      setState(() {
        _reels = reels;
        _isLoadingReels = false;
      });
    } catch (e) {
      print('Error loading reels: $e');
      setState(() => _isLoadingReels = false);
    }
  }

  Future<void> _loadPeople() async {
    try {
      setState(() => _isLoadingPeople = true);

      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        setState(() => _isLoadingPeople = false);
        return;
      }

      final result = await _supabase
          .from('users')
          .select(
            'uid, username, username_display, display_name, full_name, photo_url, followers_count',
          )
          .neq('uid', currentUserId)
          .order('followers_count', ascending: false)
          .limit(30);

      final people = (result as List).map((user) {
        return {
          'id': user['uid'],
          'username':
              user['username_display'] ??
              user['display_name'] ??
              user['username'],
          'fullName': user['full_name'],
          'avatar': user['photo_url'] ?? '',
          'followers': user['followers_count'] ?? 0,
          'type': 'user',
        };
      }).toList();

      setState(() {
        _people = people;
        _isLoadingPeople = false;
      });
    } catch (e) {
      print('Error loading people: $e');
      setState(() => _isLoadingPeople = false);
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? kDarkBackground : kLightBackground,
      appBar: _buildGlassAppBar(isDark),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    kDarkBackground,
                    kDarkBackground.withOpacity(0.95),
                    const Color(0xFF1a1a2e),
                  ]
                : [
                    kLightBackground,
                    Colors.blue.shade50.withOpacity(0.3),
                    Colors.purple.shade50.withOpacity(0.3),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildCategoryChips(isDark),
              const SizedBox(height: 12),
              _buildFilterBar(isDark),
              const SizedBox(height: 12),
              Expanded(child: _buildFilteredContent(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildGlassAppBar(bool isDark) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.white.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildGlassSearchBar(isDark)),
                    const SizedBox(width: 12),
                    _buildGlassIconButton(
                      Icons.qr_code_scanner_rounded,
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildGlassIconButton(Icons.tune_rounded, isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassSearchBar(bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.05),
                  ]
                : [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.02),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.15)
                : Colors.black.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Search',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black45,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassIconButton(IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.05)]
              : [
                  Colors.black.withOpacity(0.05),
                  Colors.black.withOpacity(0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.15)
              : Colors.black.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: kPrimary, size: 22),
    );
  }

  Widget _buildCategoryChips(bool isDark) {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == index;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [kPrimary, kPrimary.withOpacity(0.8)],
                        )
                      : LinearGradient(
                          colors: isDark
                              ? [
                                  Colors.white.withOpacity(0.08),
                                  Colors.white.withOpacity(0.05),
                                ]
                              : [
                                  Colors.black.withOpacity(0.05),
                                  Colors.black.withOpacity(0.02),
                                ],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? kPrimary.withOpacity(0.5)
                        : isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.08),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: kPrimary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.2)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : isDark
                          ? Colors.white70
                          : Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : isDark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    final filters = [
      {
        'value': ContentFilter.all,
        'label': 'All',
        'icon': Icons.explore_rounded,
      },
      {
        'value': ContentFilter.posts,
        'label': 'Posts',
        'icon': Icons.grid_on_rounded,
      },
      {
        'value': ContentFilter.reels,
        'label': 'Reels',
        'icon': Icons.play_circle_rounded,
      },
      {
        'value': ContentFilter.people,
        'label': 'People',
        'icon': Icons.people_rounded,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.05)]
              : [
                  Colors.black.withOpacity(0.05),
                  Colors.black.withOpacity(0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.15)
              : Colors.black.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['value'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter['value'] as ContentFilter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [kPrimary, kPrimary.withOpacity(0.8)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: kPrimary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : isDark
                          ? Colors.white60
                          : Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      filter['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : isDark
                            ? Colors.white60
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilteredContent(bool isDark) {
    switch (_selectedFilter) {
      case ContentFilter.posts:
        return _buildMasonryGrid(_posts, _isLoadingPosts, isDark, 'posts');
      case ContentFilter.reels:
        return _buildReelsGrid(_reels, _isLoadingReels, isDark);
      case ContentFilter.people:
        return _buildPeopleList(_people, _isLoadingPeople, isDark);
      case ContentFilter.all:
        return _buildAllContent(isDark);
    }
  }

  Widget _buildAllContent(bool isDark) {
    final isLoading = _isLoadingPosts || _isLoadingReels || _isLoadingPeople;

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: kPrimary, strokeWidth: 3),
      );
    }

    final allContent = [..._posts, ..._reels, ..._people]
      ..shuffle(); // Mix content for variety

    if (allContent.isEmpty) {
      return _buildEmptyState(
        isDark,
        'No content available',
        Icons.explore_off_rounded,
      );
    }

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async {
        await Future.wait([_loadPosts(), _loadReels(), _loadPeople()]);
      },
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: allContent.length,
        itemBuilder: (context, index) {
          final item = allContent[index];
          if (item['type'] == 'user') {
            return _buildPersonGridItem(item, isDark);
          } else {
            return _buildGlassGridItem(
              item,
              isDark,
              item['type'] as String,
              index,
            );
          }
        },
      ),
    );
  }

  Widget _buildReelsGrid(
    List<Map<String, dynamic>> reels,
    bool isLoading,
    bool isDark,
  ) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kPrimary, strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              'Loading reels...',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (reels.isEmpty) {
      return _buildEmptyState(
        isDark,
        'No reels to watch',
        Icons.videocam_off_rounded,
      );
    }

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: _loadReels,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.6,
        ),
        itemCount: reels.length,
        itemBuilder: (context, index) {
          final reel = reels[index];
          return _buildReelGridItem(reel, isDark, index);
        },
      ),
    );
  }

  Widget _buildPeopleList(
    List<Map<String, dynamic>> people,
    bool isLoading,
    bool isDark,
  ) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kPrimary, strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              'Loading people...',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (people.isEmpty) {
      return _buildEmptyState(
        isDark,
        'No people found',
        Icons.people_outline_rounded,
      );
    }

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: _loadPeople,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: people.length,
        itemBuilder: (context, index) {
          final person = people[index];
          return _buildPersonListItem(person, isDark);
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.05),
                      ]
                    : [
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.02),
                      ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.black.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 48,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later 😅',
            style: TextStyle(
              color: isDark ? Colors.white.withOpacity(0.5) : Colors.black38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReelGridItem(Map<String, dynamic> reel, bool isDark, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const ReelsPageNew()));
      },
      child: Hero(
        tag: 'reel_${reel['id']}_$index',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  reel['imageUrl'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [Colors.grey[850]!, Colors.grey[900]!]
                              : [Colors.grey[300]!, Colors.grey[200]!],
                        ),
                      ),
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: isDark ? Colors.white30 : Colors.black26,
                        size: 32,
                      ),
                    );
                  },
                ),
                // Dark gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Play icon overlay
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                // Views count
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatCount(reel['views'] as int),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildPersonGridItem(Map<String, dynamic> person, bool isDark) {
    return GestureDetector(
      onTap: () {
        // Navigate to user profile
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OtherUserProfilePage(
              userId: person['id'] as String,
              username: person['username'] as String,
              avatarUrl: person['avatar'] as String?,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.05),
                  ]
                : [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.02),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.15)
                : Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
              backgroundImage: person['avatar'].isNotEmpty
                  ? NetworkImage(person['avatar'])
                  : null,
              child: person['avatar'].isEmpty
                  ? Icon(
                      Icons.person,
                      size: 32,
                      color: isDark ? Colors.white70 : Colors.black54,
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              person['username'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatCount(person['followers'] as int)} followers',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonListItem(Map<String, dynamic> person, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.05)]
              : [
                  Colors.black.withOpacity(0.05),
                  Colors.black.withOpacity(0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.15)
              : Colors.black.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
          backgroundImage: person['avatar'].isNotEmpty
              ? NetworkImage(person['avatar'])
              : null,
          child: person['avatar'].isEmpty
              ? Icon(
                  Icons.person,
                  color: isDark ? Colors.white70 : Colors.black54,
                )
              : null,
        ),
        title: Text(
          person['username'],
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: person['fullName'] != null
            ? Text(
                person['fullName'],
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 13,
                ),
              )
            : null,
        trailing: Text(
          '${_formatCount(person['followers'] as int)} followers',
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
            fontSize: 12,
          ),
        ),
        onTap: () {
          // Navigate to user profile
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OtherUserProfilePage(
                userId: person['id'] as String,
                username: person['username'] as String,
                avatarUrl: person['avatar'] as String?,
              ),
            ),
          );
        },
      ),
    );
  }

  // ignore: unused_element
  Widget _buildGlassTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.05)]
              : [
                  Colors.black.withOpacity(0.05),
                  Colors.black.withOpacity(0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.15)
              : Colors.black.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary, kPrimary.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grid_on_rounded, size: 18),
                SizedBox(width: 6),
                Text('Posts'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_rounded, size: 18),
                SizedBox(width: 6),
                Text('Reels'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasonryGrid(
    List<Map<String, dynamic>> items,
    bool isLoading,
    bool isDark,
    String type,
  ) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kPrimary, strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              'Loading $type...',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.05),
                        ]
                      : [
                          Colors.black.withOpacity(0.05),
                          Colors.black.withOpacity(0.02),
                        ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.15)
                      : Colors.black.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Icon(
                type == 'posts'
                    ? Icons.photo_library_rounded
                    : Icons.video_library_rounded,
                size: 48,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              type == 'posts' ? 'No posts to explore' : 'No reels to watch',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new content',
              style: TextStyle(
                color: isDark ? Colors.white.withOpacity(0.5) : Colors.black38,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: type == 'posts' ? _loadPosts : _loadReels,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = items[index];
                return _buildGlassGridItem(item, isDark, type, index);
              }, childCount: items.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassGridItem(
    Map<String, dynamic> item,
    bool isDark,
    String type,
    int index,
  ) {
    return GestureDetector(
      onTap: () async {
        if (type == 'posts') {
          // Convert Map to PostModel
          final post = PostModel(
            id: item['id'] as String,
            userId: item['user_id'] as String? ?? '',
            type: PostType.image,
            mediaUrls: [item['imageUrl'] as String],
            thumbnailUrl: item['imageUrl'] as String,
            username: item['username'] as String? ?? 'Unknown',
            userAvatar: item['avatarUrl'] as String? ?? '',
            timestamp: DateTime.parse(
              item['created_at'] as String? ?? DateTime.now().toIso8601String(),
            ),
            caption: item['caption'] as String? ?? '',
            likes: item['likes'] as int? ?? 0,
            comments: item['comments'] as int? ?? 0,
            views: item['views'] as int? ?? 0,
          );

          // Navigate to post viewer
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostViewerPageV2(
                initialPost: post,
                allPosts: [post], // Just show this one post
              ),
            ),
          );
        } else if (type == 'reels') {
          // Navigate to reels page
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const ReelsPageNew()));
        }
      },
      child: Hero(
        tag: '${type}_${item['id']}_$index',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  item['imageUrl'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [Colors.grey[850]!, Colors.grey[900]!]
                              : [Colors.grey[300]!, Colors.grey[200]!],
                        ),
                      ),
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: isDark ? Colors.white30 : Colors.black26,
                        size: 32,
                      ),
                    );
                  },
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.4, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.black.withOpacity(0.2),
                            ],
                          ),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatItem(
                              type == 'posts'
                                  ? Icons.favorite_rounded
                                  : Icons.play_circle_fill_rounded,
                              _formatCount(
                                type == 'posts'
                                    ? (item['likes'] as int)
                                    : (item['views'] as int),
                              ),
                            ),
                            if (type == 'posts')
                              _buildStatItem(
                                Icons.chat_bubble_rounded,
                                _formatCount(item['comments'] as int),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kPrimary.withOpacity(0.9),
                          kPrimary.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      type == 'posts'
                          ? Icons.image_rounded
                          : Icons.videocam_rounded,
                      color: Colors.white,
                      size: 14,
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

  Widget _buildStatItem(IconData icon, String count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 4),
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.black45,
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
