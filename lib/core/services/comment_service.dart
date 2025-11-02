import 'package:supabase_flutter/supabase_flutter.dart';

/// Comment Model
class Comment {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String? userAvatar;
  final String text;
  final DateTime timestamp;
  final int likes;
  final bool isLiked;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.text,
    required this.timestamp,
    this.likes = 0,
    this.isLiked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'username': username,
      'user_avatar': userAvatar,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'likes': likes,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] ?? '',
      postId: map['post_id'] ?? '',
      userId: map['user_id'] ?? '',
      username: map['username'] ?? '',
      userAvatar: map['user_avatar'],
      text: map['text'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      likes: map['likes_count'] ?? map['likes'] ?? 0,
      isLiked: map['is_liked'] ?? false,
    );
  }
}

/// Complete CommentService with Supabase implementation
class CommentService {
  static final CommentService _instance = CommentService._internal();
  factory CommentService() => _instance;
  CommentService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Add a comment to a post
  Future<Comment?> addComment(String postId, String text) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('❌ User not authenticated');
        return null;
      }

      // Get user data
      final userData = await _supabase
          .from('users')
          .select('username, username_display, display_name, photo_url')
          .eq('uid', currentUser.id)
          .single();

      final username =
          userData['username_display'] ??
          userData['display_name'] ??
          userData['username'] ??
          'User';

      // Insert comment
      final result = await _supabase
          .from('comments')
          .insert({
            'post_id': postId,
            'user_id': currentUser.id,
            'text': text,
            'likes_count': 0,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // Increment comment count on post
      await _supabase.rpc(
        'increment_comments_count',
        params: {'post_id_input': postId},
      );

      print('✅ Comment added successfully');

      return Comment.fromMap({
        ...result,
        'username': username,
        'user_avatar': userData['photo_url'],
      });
    } catch (e) {
      print('❌ Error adding comment: $e');
      return null;
    }
  }

  /// Get comments for a post
  Future<List<Comment>> getComments(String postId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;

      final result = await _supabase
          .from('comments')
          .select('''
            *,
            users!comments_user_id_fkey(
              username,
              username_display,
              display_name,
              photo_url
            )
          ''')
          .eq('post_id', postId)
          .order('created_at', ascending: false);

      final comments = (result as List).map((commentData) {
        final user = commentData['users'];
        final username =
            user['username_display'] ??
            user['display_name'] ??
            user['username'] ??
            'User';

        // Check if current user liked this comment
        bool isLiked = false;
        if (currentUserId != null && commentData['liked_by'] != null) {
          isLiked = (commentData['liked_by'] as List).contains(currentUserId);
        }

        return Comment.fromMap({
          ...commentData,
          'username': username,
          'user_avatar': user['photo_url'],
          'is_liked': isLiked,
        });
      }).toList();

      print('✅ Got ${comments.length} comments');
      return comments;
    } catch (e) {
      print('❌ Error getting comments: $e');
      return [];
    }
  }

  /// Delete a comment
  Future<bool> deleteComment(String commentId, String postId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      await _supabase
          .from('comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', currentUserId);

      // Decrement comment count on post
      await _supabase.rpc(
        'decrement_comments_count',
        params: {'post_id_input': postId},
      );

      print('✅ Comment deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting comment: $e');
      return false;
    }
  }

  /// Like a comment
  Future<bool> likeComment(String commentId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      // Check if already liked
      final existing = await _supabase
          .from('comment_likes')
          .select()
          .eq('comment_id', commentId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (existing != null) {
        // Unlike
        await _supabase
            .from('comment_likes')
            .delete()
            .eq('comment_id', commentId)
            .eq('user_id', currentUserId);

        await _supabase.rpc(
          'decrement_comment_likes',
          params: {'comment_id_input': commentId},
        );

        print('✅ Comment unliked');
        return false;
      } else {
        // Like
        await _supabase.from('comment_likes').insert({
          'comment_id': commentId,
          'user_id': currentUserId,
          'created_at': DateTime.now().toIso8601String(),
        });

        await _supabase.rpc(
          'increment_comment_likes',
          params: {'comment_id_input': commentId},
        );

        print('✅ Comment liked');
        return true;
      }
    } catch (e) {
      print('❌ Error liking comment: $e');
      return false;
    }
  }

  /// Get comment count for a post
  Future<int> getCommentCount(String postId) async {
    try {
      final result = await _supabase
          .from('posts')
          .select('comments_count')
          .eq('id', postId)
          .single();

      return result['comments_count'] ?? 0;
    } catch (e) {
      print('❌ Error getting comment count: $e');
      return 0;
    }
  }
}
