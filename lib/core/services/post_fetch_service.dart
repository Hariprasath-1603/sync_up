import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/profile/models/post_model.dart';
import 'moderation_service.dart';

/// Complete PostFetchService with Supabase implementation
class PostFetchService {
  static final PostFetchService _instance = PostFetchService._internal();
  factory PostFetchService() => _instance;
  PostFetchService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final ModerationService _moderationService = ModerationService();

  /// Get For You feed posts (trending + recent)
  /// Excludes own posts, blocked users, and muted users
  Stream<List<PostModel>> getForYouPosts({int limit = 20}) async* {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        yield [];
        return;
      }

      // Get blocked and muted user IDs
      final blockedIds = await _moderationService.getBlockedUserIds();
      final mutedIds = await _moderationService.getMutedUserIds();
      final excludedIds = {...blockedIds, ...mutedIds, currentUserId};

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
          .not('user_id', 'in', '(${excludedIds.join(',')})')
          .order('created_at', ascending: false)
          .limit(limit);

      yield _convertToPostModels(result as List);
    } catch (e) {
      print('❌ Error fetching For You posts: $e');
      yield [];
    }
  }

  /// Get Following feed posts (from users you follow)
  /// Excludes blocked and muted users
  Stream<List<PostModel>> getFollowingPosts({int limit = 20}) async* {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        yield [];
        return;
      }

      // Get list of following
      final followingResult = await _supabase
          .from('followers')
          .select('following_id')
          .eq('follower_id', currentUserId);

      final followingIds = (followingResult as List)
          .map((e) => e['following_id'] as String)
          .toList();

      if (followingIds.isEmpty) {
        yield [];
        return;
      }

      // Get blocked and muted user IDs
      final blockedIds = await _moderationService.getBlockedUserIds();
      final mutedIds = await _moderationService.getMutedUserIds();
      final excludedIds = {...blockedIds, ...mutedIds};

      // Filter followingIds to exclude blocked/muted users
      final filteredFollowingIds = followingIds
          .where((id) => !excludedIds.contains(id))
          .toList();

      if (filteredFollowingIds.isEmpty) {
        yield [];
        return;
      }

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
          .inFilter('user_id', filteredFollowingIds)
          .order('created_at', ascending: false)
          .limit(limit);

      yield _convertToPostModels(result as List);
    } catch (e) {
      print('❌ Error fetching Following posts: $e');
      yield [];
    }
  }

  /// Get posts from a specific user
  Stream<List<PostModel>> getUserPosts(String userId, {int limit = 50}) async* {
    try {
      print('📥 Fetching posts for user: $userId');
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
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      final posts = _convertToPostModels(result as List);
      print('✅ Fetched ${posts.length} posts for user $userId');
      yield posts;
    } catch (e) {
      print('❌ Error fetching user posts: $e');
      yield [];
    }
  }

  /// Search posts by caption or tags
  Future<List<PostModel>> searchPosts(String query, {int limit = 20}) async {
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
          .or('caption.ilike.%$query%,tags.cs.{$query}')
          .order('created_at', ascending: false)
          .limit(limit);

      return _convertToPostModels(result as List);
    } catch (e) {
      print('❌ Error searching posts: $e');
      return [];
    }
  }

  /// Get Explore posts (trending by likes/views)
  /// Excludes own posts, blocked users, and muted users
  Stream<List<PostModel>> getExplorePosts({int limit = 30}) async* {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        yield [];
        return;
      }

      // Get blocked and muted user IDs
      final blockedIds = await _moderationService.getBlockedUserIds();
      final mutedIds = await _moderationService.getMutedUserIds();
      final excludedIds = {...blockedIds, ...mutedIds, currentUserId};

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
          .not('user_id', 'in', '(${excludedIds.join(',')})')
          .order('likes_count', ascending: false)
          .order('views_count', ascending: false)
          .limit(limit);

      yield _convertToPostModels(result as List);
    } catch (e) {
      print('❌ Error fetching Explore posts: $e');
      yield [];
    }
  }

  /// Get a single post by ID
  Future<PostModel?> getPostById(String postId) async {
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
          .eq('id', postId)
          .single();

      final posts = _convertToPostModels([result]);
      return posts.isNotEmpty ? posts.first : null;
    } catch (e) {
      print('❌ Error fetching post: $e');
      return null;
    }
  }

  /// Get saved posts for current user
  Stream<List<PostModel>> getSavedPosts() async* {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        yield [];
        return;
      }

      final savedResult = await _supabase
          .from('saved_posts')
          .select('post_id')
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      final postIds = (savedResult as List)
          .map((e) => e['post_id'] as String)
          .toList();

      if (postIds.isEmpty) {
        yield [];
        return;
      }

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
          .inFilter('id', postIds);

      yield _convertToPostModels(result as List);
    } catch (e) {
      print('❌ Error fetching saved posts: $e');
      yield [];
    }
  }

  /// Helper: Convert Supabase result to PostModel list
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

      // Debug logging
      print('🔍 Post ID: ${postData['id']}');
      print('   User: $username');
      print('   Media URLs: $mediaUrls');
      print('   Media count: ${mediaUrls.length}');

      // TEMPORARILY COMMENTED OUT - Allow placeholder images for testing
      // Filter out placeholder/test URLs
      // final validMediaUrls = mediaUrls.where((url) {
      //   return !url.contains('picsum.photos') &&
      //       !url.contains('placeholder.com') &&
      //       !url.contains('pravatar.cc') &&
      //       url.isNotEmpty;
      // }).toList();

      // // Skip posts with only placeholder images
      // if (mediaUrls.isNotEmpty && validMediaUrls.isEmpty) {
      //   print('⚠️  Skipping post with placeholder images');
      //   return null;
      // }

      // For now, use all media URLs (including placeholders)
      final validMediaUrls = mediaUrls.where((url) => url.isNotEmpty).toList();

      return PostModel(
        id: postData['id'],
        userId: postData['user_id'],
        type: _getPostType(postData['post_type']),
        mediaUrls: validMediaUrls,
        thumbnailUrl: validMediaUrls.isNotEmpty
            ? validMediaUrls[0]
            : 'https://via.placeholder.com/400', // Fallback placeholder
        username: username,
        userAvatar: user['photo_url']?.toString().isNotEmpty == true
            ? user['photo_url']
            : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(username)}&background=4A6CF7&color=fff', // Generated avatar fallback
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
        // Check if current user is the owner
        isFollowing:
            currentUserId != null && postData['user_id'] != currentUserId,
      );
    }).toList();
  }

  /// Helper: Convert post type string to enum
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
