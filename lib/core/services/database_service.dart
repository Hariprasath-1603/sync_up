import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'user_cache_service.dart';

/// Database Service - Supabase Data Access Layer
/// 
/// Centralized service for all database operations using Supabase.
/// Provides a clean API for CRUD operations on users, posts, reels, and stories.
/// 
/// Key Features:
/// - Username validation and availability checking
/// - User CRUD operations (Create, Read, Update, Delete)
/// - Follow/unfollow relationship management
/// - Local caching integration via UserCacheService
/// - Error handling and type-safe queries
/// 
/// Architecture:
/// - Uses Supabase PostgreSQL as primary database
/// - All queries use `.from('table_name')` pattern
/// - Row Level Security (RLS) enforced at database level
/// - Returns strongly-typed models instead of raw JSON
/// 
/// Note: This service replaces the previous Firestore implementation.
/// Migration from Firebase to Supabase is now complete.
/// 
/// Usage Example:
/// ```dart
/// final dbService = DatabaseService();
/// final user = await dbService.getUserByUid('user-id-123');
/// if (user != null) {
///   print('Found user: ${user.username}');
/// }
/// ```
class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== USERNAME VALIDATION ====================
  // Usernames in SyncUp follow Instagram-style rules:
  // - 3-30 characters long
  // - Letters, numbers, dots, and underscores only
  // - Must start with alphanumeric character
  // - Cannot end with special characters
  // - No consecutive dots or underscores
  // All usernames are stored in lowercase for case-insensitive lookup

  /// Check if a username is available for registration
  /// 
  /// Performs a case-insensitive database lookup to check if username exists.
  /// Returns true if the username is available, false if taken or on error.
  /// 
  /// Implementation:
  /// - Converts username to lowercase and trims whitespace
  /// - Uses `.maybeSingle()` to get at most one result
  /// - Returns true only if no matching user found
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

  /// Validate username format according to SyncUp rules
  /// 
  /// Returns null if valid, or an error message string if invalid.
  /// This method only checks format, not availability.
  /// 
  /// Validation Rules:
  /// ✓ 3-30 characters in length
  /// ✓ Letters, numbers, dots (.), and underscores (_) only
  /// ✓ Must start with a letter or number
  /// ✓ Cannot end with dot or underscore
  /// ✓ No consecutive special characters (.. or __)
  /// 
  /// Use this before checking availability to fail fast on invalid formats.
  /// 
  /// Example:
  /// ```dart
  /// final error = validateUsernameFormat('user.name_123');
  /// if (error != null) {
  ///   showError(error); // Show validation error to user
  /// } else {
  ///   checkAvailability(); // Proceed to check if available
  /// }
  /// ```
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
      // Try fetching from Supabase first
      final data = await _supabase
          .from('users')
          .select()
          .eq('uid', uid)
          .maybeSingle();

      if (data != null) {
        final user = UserModel.fromMap(data);
        // Cache the fresh data for offline access
        await UserCacheService.cacheUser(user);
        return user;
      }

      // No data from server, return null
      return null;
    } catch (e) {
      print('⚠️ Network error fetching user, trying cache: $e');
      // Fallback to cached data on network error
      final cachedUser = await UserCacheService.getCachedUser(uid);
      if (cachedUser != null) {
        print('📦 Loaded user from offline cache: ${cachedUser.username}');
      }
      return cachedUser;
    }
  }

  Future<UserModel?> getUserByUsername(String username) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('username', username.toLowerCase().trim())
          .maybeSingle();

      if (data != null) {
        final user = UserModel.fromMap(data);
        // Cache the fresh data for offline access
        await UserCacheService.cacheUser(user);
        return user;
      }

      return null;
    } catch (e) {
      print('⚠️ Network error fetching user by username: $e');
      // Note: Can't easily lookup by username in cache, would need secondary index
      // For now, only uid-based lookups support offline mode
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

  // ==================== PROFILE UPDATES ====================

  /// Update user's cover photo URL
  Future<bool> updateUserCoverPhoto(String uid, String? coverPhotoUrl) async {
    try {
      await _supabase
          .from('users')
          .update({
            'cover_photo_url': coverPhotoUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('uid', uid);

      print('Cover photo updated successfully for user: $uid');
      return true;
    } catch (e) {
      print('Error updating cover photo: $e');
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
