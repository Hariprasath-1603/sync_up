import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling post interactions (likes, comments, saves)
class InteractionService {
  static final InteractionService _instance = InteractionService._internal();
  factory InteractionService() => _instance;
  InteractionService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== LIKES ====================

  /// Toggle like on a post
  Future<bool> toggleLike(String postId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('âŒ User not authenticated');
        return false;
      }

      // Check if already liked
      final existingLike = await _supabase
          .from('post_likes')
          .select('id')
          .eq('user_id', userId)
          .eq('post_id', postId)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await _supabase
            .from('post_likes')
            .delete()
            .eq('user_id', userId)
            .eq('post_id', postId);
        print('âœ… Post unliked');
        return false;
      } else {
        // Like
        await _supabase.from('post_likes').insert({
          'user_id': userId,
          'post_id': postId,
        });
        print('âœ… Post liked');
        return true;
      }
    } catch (e) {
      print('âŒ Error toggling like: $e');
      return false;
    }
  }

  /// Check if user has liked a post
  Future<bool> isPostLiked(String postId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final result = await _supabase
          .from('post_likes')
          .select('id')
          .eq('user_id', userId)
          .eq('post_id', postId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      print('âŒ Error checking like status: $e');
      return false;
    }
  }

  /// Get like count for a post
  Future<int> getLikeCount(String postId) async {
    try {
      final result = await _supabase
          .from('post_likes')
          .select('id')
          .eq('post_id', postId);

      return (result as List).length;
    } catch (e) {
      print('âŒ Error getting like count: $e');
      return 0;
    }
  }

  // ==================== SAVES ====================

  /// Toggle save on a post
  Future<bool> toggleSave(String postId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('âŒ User not authenticated');
        return false;
      }

      // Check if already saved
      final existingSave = await _supabase
          .from('saved_posts')
          .select('id')
          .eq('user_id', userId)
          .eq('post_id', postId)
          .maybeSingle();

      if (existingSave != null) {
        // Unsave
        await _supabase
            .from('saved_posts')
            .delete()
            .eq('user_id', userId)
            .eq('post_id', postId);
        print('âœ… Post unsaved');
        return false;
      } else {
        // Save
        await _supabase.from('saved_posts').insert({
          'user_id': userId,
          'post_id': postId,
        });
        print('âœ… Post saved');
        return true;
      }
    } catch (e) {
      print('âŒ Error toggling save: $e');
      return false;
    }
  }

  /// Check if user has saved a post
  Future<bool> isPostSaved(String postId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final result = await _supabase
          .from('saved_posts')
          .select('id')
          .eq('user_id', userId)
          .eq('post_id', postId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      print('âŒ Error checking save status: $e');
      return false;
    }
  }

  // ==================== COMMENTS ====================

  /// Add a comment to a post
  Future<String?> addComment({
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('âŒ User not authenticated');
        return null;
      }

      final result = await _supabase
          .from('comments')
          .insert({
            'post_id': postId,
            'user_id': userId,
            'content': content,
            if (parentCommentId != null) 'parent_comment_id': parentCommentId,
          })
          .select('id')
          .single();

      print('âœ… Comment added');
      return result['id'];
    } catch (e) {
      print('âŒ Error adding comment: $e');
      return null;
    }
  }

  /// Get comments for a post
  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final result = await _supabase
          .from('comments')
          .select('''
            *,
            users!comments_user_id_fkey(
              uid,
              username,
              username_display,
              display_name,
              photo_url
            )
          ''')
          .eq('post_id', postId)
          .isFilter('parent_comment_id', null)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('âŒ Error getting comments: $e');
      return [];
    }
  }

  /// Get replies for a comment
  Future<List<Map<String, dynamic>>> getReplies(String commentId) async {
    try {
      final result = await _supabase
          .from('comments')
          .select('''
            *,
            users!comments_user_id_fkey(
              uid,
              username,
              username_display,
              display_name,
              photo_url
            )
          ''')
          .eq('parent_comment_id', commentId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('âŒ Error getting replies: $e');
      return [];
    }
  }

  /// Delete a comment
  Future<bool> deleteComment(String commentId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', userId);

      print('âœ… Comment deleted');
      return true;
    } catch (e) {
      print('âŒ Error deleting comment: $e');
      return false;
    }
  }

  /// Toggle like on a comment
  Future<bool> toggleCommentLike(String commentId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Check if already liked
      final existingLike = await _supabase
          .from('comment_likes')
          .select('id')
          .eq('user_id', userId)
          .eq('comment_id', commentId)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await _supabase
            .from('comment_likes')
            .delete()
            .eq('user_id', userId)
            .eq('comment_id', commentId);
        return false;
      } else {
        // Like
        await _supabase.from('comment_likes').insert({
          'user_id': userId,
          'comment_id': commentId,
        });
        return true;
      }
    } catch (e) {
      print('âŒ Error toggling comment like: $e');
      return false;
    }
  }

  // ==================== POST VIEWS ====================

  /// Record a post view
  Future<void> recordPostView(String postId, {int durationSeconds = 0}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      await _supabase.from('post_views').insert({
        'post_id': postId,
        'viewer_id': userId,
        'duration_seconds': durationSeconds,
      });
    } catch (e) {
      print('âŒ Error recording post view: $e');
    }
  }

  // ==================== FOLLOW/UNFOLLOW ====================

  /// Toggle follow on a user
  Future<bool> toggleFollow(String targetUserId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null || userId == targetUserId) return false;

      // Check if already following
      final existingFollow = await _supabase
          .from('followers')
          .select('id')
          .eq('follower_id', userId)
          .eq('following_id', targetUserId)
          .maybeSingle();

      if (existingFollow != null) {
        // Unfollow
        await _supabase
            .from('followers')
            .delete()
            .eq('follower_id', userId)
            .eq('following_id', targetUserId);

        // Update counts
        await _updateFollowCounts(userId, targetUserId, false);

        print('âœ… Unfollowed user');
        return false;
      } else {
        // Follow
        await _supabase.from('followers').insert({
          'follower_id': userId,
          'following_id': targetUserId,
        });

        // Update counts
        await _updateFollowCounts(userId, targetUserId, true);

        print('âœ… Followed user');
        return true;
      }
    } catch (e) {
      print('âŒ Error toggling follow: $e');
      return false;
    }
  }

  /// Check if user is following another user
  Future<bool> isFollowing(String targetUserId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final result = await _supabase
          .from('followers')
          .select('id')
          .eq('follower_id', userId)
          .eq('following_id', targetUserId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      print('âŒ Error checking follow status: $e');
      return false;
    }
  }

  /// Update follow counts for both users
  Future<void> _updateFollowCounts(
    String followerId,
    String followingId,
    bool isFollowing,
  ) async {
    try {
      // Get current counts
      final followerData = await _supabase
          .from('users')
          .select('following')
          .eq('uid', followerId)
          .single();

      final followingData = await _supabase
          .from('users')
          .select('followers')
          .eq('uid', followingId)
          .single();

      List<String> followerFollowing = List<String>.from(
        followerData['following'] ?? [],
      );
      List<String> followingFollowers = List<String>.from(
        followingData['followers'] ?? [],
      );

      if (isFollowing) {
        if (!followerFollowing.contains(followingId)) {
          followerFollowing.add(followingId);
        }
        if (!followingFollowers.contains(followerId)) {
          followingFollowers.add(followerId);
        }
      } else {
        followerFollowing.remove(followingId);
        followingFollowers.remove(followerId);
      }

      // Update follower's following list
      await _supabase
          .from('users')
          .update({
            'following': followerFollowing,
            'following_count': followerFollowing.length,
          })
          .eq('uid', followerId);

      // Update following's followers list
      await _supabase
          .from('users')
          .update({
            'followers': followingFollowers,
            'followers_count': followingFollowers.length,
          })
          .eq('uid', followingId);
    } catch (e) {
      print('âŒ Error updating follow counts: $e');
    }
  }
}

