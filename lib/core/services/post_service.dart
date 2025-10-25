import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

/// Service for creating and managing posts
class PostService {
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;
  PostService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new post
  Future<String?> createPost({
    required String userId,
    required String caption,
    required List<String> mediaUrls,
    String? location,
    List<String>? tags,
    String postType = 'image', // 'image', 'video', 'carousel'
  }) async {
    try {
      final postData = {
        'user_id': userId,
        'caption': caption,
        'media_urls': mediaUrls,
        'location': location,
        'tags': tags ?? [],
        'post_type': postType,
        'likes_count': 0,
        'comments_count': 0,
        'shares_count': 0,
        'views_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      };

      final result = await _supabase
          .from('posts')
          .insert(postData)
          .select('id')
          .single();

      // Increment user's post count
      await _incrementPostCount(userId);

      print('✅ Post created successfully: ${result['id']}');
      return result['id'];
    } catch (e) {
      print('❌ Error creating post: $e');
      return null;
    }
  }

  /// Upload media file to Supabase Storage
  Future<String?> uploadMedia(XFile file, String userId) async {
    try {
      final bytes = await file.readAsBytes();
      final fileExt = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${userId}.$fileExt';
      final filePath = '$userId/$fileName';

      await _supabase.storage.from('posts').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: file.mimeType ?? 'image/jpeg',
            ),
          );

      final publicUrl = _supabase.storage.from('posts').getPublicUrl(filePath);
      
      print('✅ Media uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Error uploading media: $e');
      return null;
    }
  }

  /// Get posts for user feed (following + recommended)
  Future<List<Map<String, dynamic>>> getFeedPosts(String userId, {int limit = 20}) async {
    try {
      // Get user's following list
      final followingResult = await _supabase
          .from('followers')
          .select('following_id')
          .eq('follower_id', userId);

      final followingIds = (followingResult as List)
          .map((e) => e['following_id'] as String)
          .toList();

      // Add user's own ID to see their posts too
      followingIds.add(userId);

      // Fetch posts from following + some recommended posts
      final result = await _supabase
          .from('posts')
          .select('''
            *,
            users!posts_user_id_fkey(
              uid,
              username,
              username_display,
              display_name,
              full_name,
              photo_url
            )
          ''')
          .inFilter('user_id', followingIds)
          .order('created_at', ascending: false)
          .limit(limit);

      return _formatPosts(result as List);
    } catch (e) {
      print('❌ Error fetching feed posts: $e');
      return [];
    }
  }

  /// Get user's own posts
  Future<List<Map<String, dynamic>>> getUserPosts(String userId) async {
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
              full_name,
              photo_url
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return _formatPosts(result as List);
    } catch (e) {
      print('❌ Error fetching user posts: $e');
      return [];
    }
  }

  /// Get explore posts (trending/popular)
  Future<List<Map<String, dynamic>>> getExplorePosts({int limit = 30}) async {
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
              full_name,
              photo_url
            )
          ''')
          .order('likes_count', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit);

      return _formatPosts(result as List);
    } catch (e) {
      print('❌ Error fetching explore posts: $e');
      return [];
    }
  }

  /// Like a post
  Future<bool> likePost(String postId, [String? userId]) async {
    try {
      final currentUserId = userId ?? _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      // Check if already liked
      final existing = await _supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (existing != null) {
        return false; // Already liked
      }

      // Add like
      await _supabase.from('post_likes').insert({
        'post_id': postId,
        'user_id': currentUserId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Increment like count
      await _supabase.rpc('increment_post_likes', params: {'post_id_input': postId});

      return true;
    } catch (e) {
      print('❌ Error liking post: $e');
      return false;
    }
  }

  /// Unlike a post
  Future<bool> unlikePost(String postId, [String? userId]) async {
    try {
      final currentUserId = userId ?? _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      await _supabase
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', currentUserId);

      // Decrement like count
      await _supabase.rpc('decrement_post_likes', params: {'post_id_input': postId});

      return true;
    } catch (e) {
      print('❌ Error unliking post: $e');
      return false;
    }
  }

  /// Save a post
  Future<bool> savePost(String postId, [String? userId]) async {
    try {
      final currentUserId = userId ?? _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      // Check if already saved
      final existing = await _supabase
          .from('saved_posts')
          .select()
          .eq('post_id', postId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (existing != null) {
        return false; // Already saved
      }

      await _supabase.from('saved_posts').insert({
        'post_id': postId,
        'user_id': currentUserId,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('❌ Error saving post: $e');
      return false;
    }
  }

  /// Unsave a post
  Future<bool> unsavePost(String postId, [String? userId]) async {
    try {
      final currentUserId = userId ?? _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      await _supabase
          .from('saved_posts')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', currentUserId);

      return true;
    } catch (e) {
      print('❌ Error unsaving post: $e');
      return false;
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId, [String? userId]) async {
    try {
      final currentUserId = userId ?? _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      await _supabase
          .from('posts')
          .delete()
          .eq('id', postId)
          .eq('user_id', currentUserId);

      await _decrementPostCount(currentUserId);
    } catch (e) {
      print('❌ Error deleting post: $e');
    }
  }

  /// Update a post
  Future<void> updatePost(String postId, Map<String, dynamic> updates) async {
    try {
      await _supabase.from('posts').update(updates).eq('id', postId);
    } catch (e) {
      print('❌ Error updating post: $e');
    }
  }

  String getPostLink(String postId) {
    return 'https://syncup.app/post/$postId';
  }

  // Helper methods
  List<Map<String, dynamic>> _formatPosts(List posts) {
    return posts.map((post) {
      final user = post['users'];
      return {
        'id': post['id'],
        'user_id': post['user_id'],
        'username': user['username_display'] ?? user['username'],
        'display_name': user['display_name'] ?? user['full_name'],
        'user_avatar': user['photo_url'],
        'caption': post['caption'],
        'media_urls': post['media_urls'] as List? ?? [],
        'location': post['location'],
        'tags': post['tags'] as List? ?? [],
        'post_type': post['post_type'],
        'likes_count': post['likes_count'] ?? 0,
        'comments_count': post['comments_count'] ?? 0,
        'shares_count': post['shares_count'] ?? 0,
        'views_count': post['views_count'] ?? 0,
        'created_at': post['created_at'],
      };
    }).toList();
  }

  Future<void> _incrementPostCount(String userId) async {
    try {
      await _supabase.rpc('increment_posts_count', params: {'user_id': userId});
    } catch (e) {
      print('Error incrementing post count: $e');
    }
  }

  Future<void> _decrementPostCount(String userId) async {
    try {
      await _supabase.rpc('decrement_posts_count', params: {'user_id': userId});
    } catch (e) {
      print('Error decrementing post count: $e');
    }
  }
}

