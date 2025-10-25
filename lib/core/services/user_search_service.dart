import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for searching users
class UserSearchService {
  static final UserSearchService _instance = UserSearchService._internal();
  factory UserSearchService() => _instance;
  UserSearchService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Search users by username or display name
  Future<List<Map<String, dynamic>>> searchUsers(String query, {int limit = 20}) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final searchQuery = query.trim().toLowerCase();

      // Search in username, display_name, and full_name
      final result = await _supabase
          .from('users')
          .select('uid, username, username_display, display_name, full_name, photo_url, bio, followers_count, following_count')
          .or('username.ilike.%$searchQuery%,username_display.ilike.%$searchQuery%,display_name.ilike.%$searchQuery%,full_name.ilike.%$searchQuery%')
          .order('followers_count', ascending: false)
          .limit(limit);

      return (result as List)
          .map((user) => {
                'uid': user['uid'],
                'username': user['username_display'] ?? user['username'],
                'display_name': user['display_name'] ?? user['full_name'] ?? user['username_display'],
                'photo_url': user['photo_url'],
                'bio': user['bio'],
                'followers_count': user['followers_count'] ?? 0,
                'following_count': user['following_count'] ?? 0,
              })
          .toList();
    } catch (e) {
      print('❌ Error searching users: $e');
      return [];
    }
  }

  /// Get suggested users (popular users)
  Future<List<Map<String, dynamic>>> getSuggestedUsers({int limit = 10}) async {
    try {
      final result = await _supabase
          .from('users')
          .select('uid, username, username_display, display_name, full_name, photo_url, bio, followers_count')
          .order('followers_count', ascending: false)
          .limit(limit);

      return (result as List)
          .map((user) => {
                'uid': user['uid'],
                'username': user['username_display'] ?? user['username'],
                'display_name': user['display_name'] ?? user['full_name'] ?? user['username_display'],
                'photo_url': user['photo_url'],
                'bio': user['bio'],
                'followers_count': user['followers_count'] ?? 0,
              })
          .toList();
    } catch (e) {
      print('❌ Error getting suggested users: $e');
      return [];
    }
  }

  /// Get user by username
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    try {
      final result = await _supabase
          .from('users')
          .select()
          .eq('username', username.toLowerCase())
          .maybeSingle();

      if (result == null) return null;

      return {
        'uid': result['uid'],
        'username': result['username_display'] ?? result['username'],
        'display_name': result['display_name'] ?? result['full_name'],
        'photo_url': result['photo_url'],
        'bio': result['bio'],
        'followers_count': result['followers_count'] ?? 0,
        'following_count': result['following_count'] ?? 0,
        'posts_count': result['posts_count'] ?? 0,
      };
    } catch (e) {
      print('❌ Error getting user by username: $e');
      return null;
    }
  }
}
