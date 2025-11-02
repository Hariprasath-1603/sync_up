import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final SupabaseClient _supabase = Supabase.instance.client;

  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _recentSearches = [];
  bool _isSearching = false;
  bool _showResults = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadRecentSearches() {
    // TODO: Load from local storage or database
    setState(() {
      _recentSearches = [];
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() {
      _searchQuery = query;
      _showResults = query.isNotEmpty;
    });

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _isSearching = true);

    try {
      // Search for users
      final usersResult = await _supabase
          .from('users')
          .select(
            'uid, username, username_display, display_name, full_name, photo_url',
          )
          .or(
            'username.ilike.%$query%,username_display.ilike.%$query%,display_name.ilike.%$query%,full_name.ilike.%$query%',
          )
          .limit(10);

      // Search for posts
      final postsResult = await _supabase
          .from('posts')
          .select('''
            id,
            caption,
            media_urls,
            likes_count,
            comments_count,
            users!posts_user_id_fkey(username, username_display, photo_url)
          ''')
          .or('caption.ilike.%$query%,tags.cs.{$query}')
          .order('created_at', ascending: false)
          .limit(20);

      final List<Map<String, dynamic>> results = [];

      // Add user results
      for (final user in (usersResult as List)) {
        final mediaUrls = [];
        results.add({
          'type': 'user',
          'id': user['uid'],
          'username':
              user['username_display'] ??
              user['display_name'] ??
              user['username'],
          'fullName': user['full_name'],
          'avatar': user['photo_url'] ?? '',
          'mediaUrls': mediaUrls,
        });
      }

      // Add post results (filter out placeholder images)
      for (final post in (postsResult as List)) {
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

        // Skip posts with only placeholder images
        if (mediaUrls.isNotEmpty && validMediaUrls.isEmpty) continue;

        final user = post['users'];
        results.add({
          'type': 'post',
          'id': post['id'],
          'caption': post['caption'] ?? '',
          'imageUrl': validMediaUrls.isNotEmpty ? validMediaUrls.first : '',
          'likes': post['likes_count'] ?? 0,
          'comments': post['comments_count'] ?? 0,
          'username': user['username_display'] ?? user['username'],
          'avatar': user['photo_url'] ?? '',
        });
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B0E13)
          : const Color(0xFFF6F7FB),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0B0E13),
                    const Color(0xFF1A1F2E),
                    kPrimary.withOpacity(0.1),
                  ]
                : [
                    const Color(0xFFF6F7FB),
                    const Color(0xFFFFFFFF),
                    kPrimary.withOpacity(0.05),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchHeader(isDark),
              Expanded(
                child: _showResults
                    ? _buildSearchResults(isDark)
                    : _buildRecentSearches(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
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
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.15)
                          : Colors.black.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search users, posts, hashtags...',
                      hintStyle: GoogleFonts.poppins(
                        color: isDark ? Colors.white60 : Colors.black45,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
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

  Widget _buildSearchResults(bool isDark) {
    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(color: kPrimary, strokeWidth: 3),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white.withOpacity(0.5) : Colors.black38,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        if (result['type'] == 'user') {
          return _buildUserResultCard(result, isDark);
        } else {
          return _buildPostResultCard(result, isDark);
        }
      },
    );
  }

  Widget _buildUserResultCard(Map<String, dynamic> user, bool isDark) {
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
          backgroundImage: user['avatar'].isNotEmpty
              ? NetworkImage(user['avatar'])
              : null,
          child: user['avatar'].isEmpty
              ? Icon(
                  Icons.person,
                  color: isDark ? Colors.white70 : Colors.black54,
                )
              : null,
        ),
        title: Text(
          user['username'],
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: user['fullName'] != null
            ? Text(
                user['fullName'],
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 13,
                ),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: isDark ? Colors.white60 : Colors.black54,
        ),
        onTap: () {
          // TODO: Navigate to user profile
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigate to ${user['username']} profile'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostResultCard(Map<String, dynamic> post, bool isDark) {
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
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 56,
            height: 56,
            color: isDark ? Colors.grey[800] : Colors.grey[300],
            child: post['imageUrl'].isNotEmpty
                ? Image.network(
                    post['imageUrl'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.broken_image_outlined,
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                  )
                : Icon(
                    Icons.image_outlined,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
          ),
        ),
        title: Text(
          post['username'],
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post['caption'].isNotEmpty)
              Text(
                post['caption'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  size: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post['likes']}',
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.comment,
                  size: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post['comments']}',
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          // TODO: Navigate to post detail
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Open post ${post['id']}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentSearches(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Recent Searches',
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (_recentSearches.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recent searches',
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start searching to see your history',
                    style: GoogleFonts.poppins(
                      color: isDark
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black38,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // TODO: Display recent searches
      ],
    );
  }
}
