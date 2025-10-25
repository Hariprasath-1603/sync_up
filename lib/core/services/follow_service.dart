import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing follow/unfollow relationships
class FollowService {
  static final FollowService _instance = FollowService._internal();
  factory FollowService() => _instance;
  FollowService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Follow a user
  Future<bool> followUser(String currentUserId, String targetUserId) async {
    try {
      // Check if already following
      final existing = await _supabase
          .from('followers')
          .select()
          .eq('follower_id', currentUserId)
          .eq('following_id', targetUserId)
          .maybeSingle();

      if (existing != null) {
        print('Already following this user');
        return false;
      }

      // Add follow relationship
      await _supabase.from('followers').insert({
        'follower_id': currentUserId,
        'following_id': targetUserId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update follower counts
      await _incrementFollowerCount(targetUserId);
      await _incrementFollowingCount(currentUserId);

      print('✅ Successfully followed user: $targetUserId');
      return true;
    } catch (e) {
      print('❌ Error following user: $e');
      return false;
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      // Delete follow relationship
      await _supabase
          .from('followers')
          .delete()
          .eq('follower_id', currentUserId)
          .eq('following_id', targetUserId);

      // Update follower counts
      await _decrementFollowerCount(targetUserId);
      await _decrementFollowingCount(currentUserId);

      print('✅ Successfully unfollowed user: $targetUserId');
      return true;
    } catch (e) {
      print('❌ Error unfollowing user: $e');
      return false;
    }
  }

  /// Check if current user is following target user
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final result = await _supabase
          .from('followers')
          .select()
          .eq('follower_id', currentUserId)
          .eq('following_id', targetUserId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      print('❌ Error checking follow status: $e');
      return false;
    }
  }

  /// Get list of followers for a user
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    try {
      final result = await _supabase
          .from('followers')
          .select('follower_id, users!followers_follower_id_fkey(*)')
          .eq('following_id', userId)
          .order('created_at', ascending: false);

      return (result as List)
          .map((e) => {
                'uid': e['users']['uid'],
                'username': e['users']['username_display'] ?? e['users']['username'],
                'display_name': e['users']['display_name'] ?? e['users']['full_name'],
                'photo_url': e['users']['photo_url'],
                'bio': e['users']['bio'],
              })
          .toList();
    } catch (e) {
      print('❌ Error fetching followers: $e');
      return [];
    }
  }

  /// Get list of users that a user is following
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    try {
      final result = await _supabase
          .from('followers')
          .select('following_id, users!followers_following_id_fkey(*)')
          .eq('follower_id', userId)
          .order('created_at', ascending: false);

      return (result as List)
          .map((e) => {
                'uid': e['users']['uid'],
                'username': e['users']['username_display'] ?? e['users']['username'],
                'display_name': e['users']['display_name'] ?? e['users']['full_name'],
                'photo_url': e['users']['photo_url'],
                'bio': e['users']['bio'],
              })
          .toList();
    } catch (e) {
      print('❌ Error fetching following: $e');
      return [];
    }
  }

  /// Get follower count for a user
  Future<int> getFollowerCount(String userId) async {
    try {
      final result = await _supabase
          .from('followers')
          .select()
          .eq('following_id', userId);

      return (result as List).length;
    } catch (e) {
      print('❌ Error getting follower count: $e');
      return 0;
    }
  }

  /// Get following count for a user
  Future<int> getFollowingCount(String userId) async {
    try {
      final result = await _supabase
          .from('followers')
          .select()
          .eq('follower_id', userId);

      return (result as List).length;
    } catch (e) {
      print('❌ Error getting following count: $e');
      return 0;
    }
  }

  // Helper methods to update counts
  Future<void> _incrementFollowerCount(String userId) async {
    try {
      await _supabase.rpc('increment_followers_count', params: {'user_id': userId});
    } catch (e) {
      print('Error incrementing follower count: $e');
    }
  }

  Future<void> _decrementFollowerCount(String userId) async {
    try {
      await _supabase.rpc('decrement_followers_count', params: {'user_id': userId});
    } catch (e) {
      print('Error decrementing follower count: $e');
    }
  }

  Future<void> _incrementFollowingCount(String userId) async {
    try {
      await _supabase.rpc('increment_following_count', params: {'user_id': userId});
    } catch (e) {
      print('Error incrementing following count: $e');
    }
  }

  Future<void> _decrementFollowingCount(String userId) async {
    try {
      await _supabase.rpc('decrement_following_count', params: {'user_id': userId});
    } catch (e) {
      print('Error decrementing following count: $e');
    }
  }
}
