import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../../features/profile/models/post_model.dart';

/// Service for searching users, posts, and reels
class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== USER SEARCH ====================

  /// Search users by username or display name
  Future<List<UserModel>> searchUsers(String query, {int limit = 20}) async {
    try {
      if (query.trim().isEmpty) return [];

      final searchQuery = query.trim().toLowerCase();

      final result = await _supabase
          .from('users')
          .select()
          .or(
            'username.ilike.%$searchQuery%,'
            'username_display.ilike.%$searchQuery%,'
            'display_name.ilike.%$searchQuery%,'
            'full_name.ilike.%$searchQuery%',
          )
          .order('followers_count', ascending: false)
          .limit(limit);

      return (result as List)
          .map((data) => UserModel.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error searching users: $e');
      return [];
    }
  }

  /// Search users by exact username
  Future<UserModel?> searchUserByUsername(String username) async {
    try {
      final result = await _supabase
          .from('users')
          .select()
          .eq('username', username.toLowerCase().trim())
          .maybeSingle();

      return result != null ? UserModel.fromMap(result) : null;
    } catch (e) {
      print('❌ Error searching user by username: $e');
      return null;
    }
  }

  /// Get suggested users (popular users to follow)
  Future<List<UserModel>> getSuggestedUsers({int limit = 10}) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return [];

      // Get users not followed by current user, ordered by followers count
      final result = await _supabase
          .from('users')
          .select()
          .neq('uid', currentUserId)
          .order('followers_count', ascending: false)
          .limit(limit);

      final users = (result as List)
          .map((data) => UserModel.fromMap(data as Map<String, dynamic>))
          .toList();

      // Filter out already followed users
      final followingResult = await _supabase
          .from('followers')
          .select('following_id')
          .eq('follower_id', currentUserId);

      final followingIds = (followingResult as List)
          .map((item) => item['following_id'] as String)
          .toSet();

      return users.where((user) => !followingIds.contains(user.uid)).toList();
    } catch (e) {
      print('❌ Error getting suggested users: $e');
      return [];
    }
  }

  // ==================== POST SEARCH ====================

  /// Search posts by caption or tags
  Future<List<PostModel>> searchPosts(String query, {int limit = 20}) async {
    try {
      if (query.trim().isEmpty) return [];

      final searchQuery = query.trim().toLowerCase();

      final result = await _supabase
          .from('posts')
          .select('''
            *,
            users!posts_user_id_fkey(
              uid,
              username,
              username_display,
              display_name,
              photo_url
            )
          ''')
          .neq('post_type', 'reel')
          .or('caption.ilike.%$searchQuery%,tags.cs.{$searchQuery}')
          .order('created_at', ascending: false)
          .limit(limit);

      return _convertToPostModels(result as List);
    } catch (e) {
      print('❌ Error searching posts: $e');
      return [];
    }
  }

  /// Search posts by hashtag
  Future<List<PostModel>> searchPostsByHashtag(
    String hashtag, {
    int limit = 30,
  }) async {
    try {
      final cleanHashtag = hashtag.replaceAll('#', '').trim().toLowerCase();

      final result = await _supabase
          .from('posts')
          .select('''
            *,
            users!posts_user_id_fkey(
              uid,
              username,
              username_display,
              display_name,
              photo_url
            )
          ''')
          .contains('tags', [cleanHashtag])
          .order('likes_count', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit);

      return _convertToPostModels(result as List);
    } catch (e) {
      print('❌ Error searching posts by hashtag: $e');
      return [];
    }
  }

  // ==================== REEL SEARCH ====================

  /// Search reels by caption or tags
  Future<List<PostModel>> searchReels(String query, {int limit = 20}) async {
    try {
      if (query.trim().isEmpty) return [];

      final searchQuery = query.trim().toLowerCase();

      final result = await _supabase
          .from('posts')
          .select('''
            *,
            users!posts_user_id_fkey(
              uid,
              username,
              username_display,
              display_name,
              photo_url
            )
          ''')
          .eq('post_type', 'reel')
          .or('caption.ilike.%$searchQuery%,tags.cs.{$searchQuery}')
          .order('created_at', ascending: false)
          .limit(limit);

      return _convertToPostModels(result as List);
    } catch (e) {
      print('❌ Error searching reels: $e');
      return [];
    }
  }

  /// Get trending reels
  Future<List<PostModel>> getTrendingReels({int limit = 20}) async {
    try {
      final result = await _supabase
          .from('posts')
          .select('''
            *,
            users!posts_user_id_fkey(
              uid,
              username,
              username_display,
              display_name,
              photo_url
            )
          ''')
          .eq('post_type', 'reel')
          .order('likes_count', ascending: false)
          .order('views_count', ascending: false)
          .limit(limit);

      return _convertToPostModels(result as List);
    } catch (e) {
      print('❌ Error getting trending reels: $e');
      return [];
    }
  }

  // ==================== TRENDING/POPULAR ====================

  /// Get trending hashtags
  Future<List<Map<String, dynamic>>> getTrendingHashtags({
    int limit = 10,
  }) async {
    try {
      // This is a simplified version - in production you'd want a separate hashtags table
      final result = await _supabase
          .from('posts')
          .select('tags')
          .not('tags', 'is', null)
          .order('created_at', ascending: false)
          .limit(100);

      // Count tag occurrences
      final tagCounts = <String, int>{};
      for (final post in result as List) {
        final tags = List<String>.from(post['tags'] ?? []);
        for (final tag in tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }

      // Sort by count and return top hashtags
      final sortedTags = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedTags
          .take(limit)
          .map((entry) => {'tag': entry.key, 'count': entry.value})
          .toList();
    } catch (e) {
      print('❌ Error getting trending hashtags: $e');
      return [];
    }
  }

  /// Get search history for current user (client-side storage recommended)
  List<String> getRecentSearches() {
    // In production, use local storage (SharedPreferences or Hive)
    // This is a placeholder
    return [];
  }

  /// Save search query to history (client-side storage recommended)
  Future<void> saveSearchQuery(String query) async {
    // In production, save to local storage
    // This is a placeholder
  }

  // ==================== HELPERS ====================

  /// Convert Supabase result to PostModel list
  List<PostModel> _convertToPostModels(List data) {
    final currentUserId = _supabase.auth.currentUser?.id;

    return data.map((postData) {
      final user = postData['users'];
      final username =
          user['username_display'] ??
          user['display_name'] ??
          user['username'] ??
          'User';

      final mediaUrls = postData['media_urls'] != null
          ? List<String>.from(postData['media_urls'])
          : <String>[];

      return PostModel(
        id: postData['id'],
        userId: postData['user_id'],
        type: _getPostType(postData['post_type']),
        mediaUrls: mediaUrls,
        thumbnailUrl: mediaUrls.isNotEmpty
            ? mediaUrls[0]
            : 'https://via.placeholder.com/400',
        username: username,
        userAvatar:
            user['photo_url'] ?? 'https://i.pravatar.cc/150?u=${user['uid']}',
        timestamp: DateTime.parse(postData['created_at']),
        caption: postData['caption'] ?? '',
        location: postData['location'],
        likes: postData['likes_count'] ?? 0,
        comments: postData['comments_count'] ?? 0,
        shares: postData['shares_count'] ?? 0,
        views: postData['views_count'] ?? 0,
        tags: postData['tags'] != null
            ? List<String>.from(postData['tags'])
            : [],
        commentsEnabled: postData['comments_enabled'] ?? true,
        isFollowing:
            currentUserId != null && postData['user_id'] != currentUserId,
      );
    }).toList();
  }

  /// Convert post type string to enum
  PostType _getPostType(String? type) {
    switch (type) {
      case 'video':
        return PostType.video;
      case 'carousel':
        return PostType.carousel;
      case 'reel':
        return PostType.reel;
      default:
        return PostType.image;
    }
  }
}
