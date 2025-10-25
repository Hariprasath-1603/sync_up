import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

/// Simplified DatabaseService for Supabase
/// TODO: This is a minimal implementation to make the app compile
/// Full Firestore to Supabase migration for complex features is pending
class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== USERNAME VALIDATION ====================

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final result = await _supabase
          .from('users')
          .select('username')
          .eq('username', username.toLowerCase().trim())
          .maybeSingle();
      return result == null;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }

  String? validateUsernameFormat(String username) {
    if (username.isEmpty) return 'Username cannot be empty';
    if (username.length < 3) return 'Username must be at least 3 characters';
    if (username.length > 30) return 'Username must be less than 30 characters';
    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(username)) {
      return 'Username can only contain letters, numbers, dots, and underscores';
    }
    if (!RegExp(r'^[a-zA-Z0-9]').hasMatch(username)) {
      return 'Username must start with a letter or number';
    }
    if (username.endsWith('.') || username.endsWith('_')) {
      return 'Username cannot end with a dot or underscore';
    }
    if (username.contains('..') || username.contains('__')) {
      return 'Username cannot have consecutive dots or underscores';
    }
    return null;
  }

  // ==================== USER CRUD OPERATIONS ====================

  Future<bool> createUser(UserModel user) async {
    try {
      final isAvailable = await isUsernameAvailable(user.username);
      if (!isAvailable) {
        print('Username ${user.username} is already taken');
        return false;
      }

      await _supabase.from('users').insert(user.toMap());
      print('User created successfully: ${user.username}');
      return true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  Future<UserModel?> getUserByUid(String uid) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('uid', uid)
          .maybeSingle();

      return data != null ? UserModel.fromMap(data) : null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<UserModel?> getUserByUsername(String username) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('username', username.toLowerCase().trim())
          .maybeSingle();

      return data != null ? UserModel.fromMap(data) : null;
    } catch (e) {
      print('Error getting user by username: $e');
      return null;
    }
  }

  Future<bool> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from('users')
          .update({...updates, 'last_active': DateTime.now().toIso8601String()})
          .eq('uid', uid);
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String uid) async {
    try {
      await _supabase.from('users').delete().eq('uid', uid);
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  Future<void> updateLastActive(String uid) async {
    try {
      await _supabase
          .from('users')
          .update({'last_active': DateTime.now().toIso8601String()})
          .eq('uid', uid);
    } catch (e) {
      print('Error updating last active: $e');
    }
  }

  // ==================== FOLLOW/UNFOLLOW ====================

  Future<bool> followUser(String currentUserId, String targetUserId) async {
    try {
      // Get current user data
      final currentUser = await getUserByUid(currentUserId);
      final targetUser = await getUserByUid(targetUserId);

      if (currentUser == null || targetUser == null) return false;

      // Update following list
      final newFollowing = [...currentUser.following, targetUserId];
      await _supabase
          .from('users')
          .update({
            'following': newFollowing,
            'following_count': newFollowing.length,
          })
          .eq('uid', currentUserId);

      // Update followers list
      final newFollowers = [...targetUser.followers, currentUserId];
      await _supabase
          .from('users')
          .update({
            'followers': newFollowers,
            'followers_count': newFollowers.length,
          })
          .eq('uid', targetUserId);

      return true;
    } catch (e) {
      print('Error following user: $e');
      return false;
    }
  }

  Future<bool> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      // Get current user data
      final currentUser = await getUserByUid(currentUserId);
      final targetUser = await getUserByUid(targetUserId);

      if (currentUser == null || targetUser == null) return false;

      // Update following list
      final newFollowing = currentUser.following
          .where((id) => id != targetUserId)
          .toList();
      await _supabase
          .from('users')
          .update({
            'following': newFollowing,
            'following_count': newFollowing.length,
          })
          .eq('uid', currentUserId);

      // Update followers list
      final newFollowers = targetUser.followers
          .where((id) => id != currentUserId)
          .toList();
      await _supabase
          .from('users')
          .update({
            'followers': newFollowers,
            'followers_count': newFollowers.length,
          })
          .eq('uid', targetUserId);

      return true;
    } catch (e) {
      print('Error unfollowing user: $e');
      return false;
    }
  }

  // ==================== SEARCH ====================

  Future<List<UserModel>> searchUsers(String query, {int limit = 20}) async {
    try {
      final results = await _supabase
          .from('users')
          .select()
          .or('username.ilike.%$query%,display_name.ilike.%$query%')
          .limit(limit);

      return (results as List)
          .map((data) => UserModel.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}
