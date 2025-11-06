import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

/// Service for caching user data offline using SharedPreferences
/// Enables profile viewing without internet connection
class UserCacheService {
  static const String _cachePrefix = 'user_cache_';
  static const String _lastUpdatePrefix = 'user_cache_timestamp_';

  /// Save user data to local cache
  /// Call this whenever fresh user data is fetched from Supabase
  static Future<void> cacheUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_cachePrefix${user.uid}';
      final timestampKey = '$_lastUpdatePrefix${user.uid}';

      final json = jsonEncode(user.toMap());
      await prefs.setString(key, json);
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);

      debugPrint('💾 Cached user: ${user.username}');
    } catch (e) {
      debugPrint('❌ Error caching user: $e');
    }
  }

  /// Retrieve user data from local cache
  /// Returns null if user not found in cache
  static Future<UserModel?> getCachedUser(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_cachePrefix$uid';
      final json = prefs.getString(key);

      if (json != null) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        debugPrint('📦 Loaded cached user: ${map['username']} (offline mode)');
        return UserModel.fromMap(map);
      }
    } catch (e) {
      debugPrint('❌ Error loading cached user: $e');
    }
    return null;
  }

  /// Check if cached data exists for user
  static Future<bool> hasCachedUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_cachePrefix$uid');
  }

  /// Get last cache update timestamp
  /// Returns null if never cached
  static Future<DateTime?> getLastUpdateTime(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('$_lastUpdatePrefix$uid');
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      debugPrint('❌ Error getting cache timestamp: $e');
    }
    return null;
  }

  /// Check if cached data is stale (older than specified duration)
  /// Default: 24 hours
  static Future<bool> isCacheStale(
    String uid, {
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final lastUpdate = await getLastUpdateTime(uid);
    if (lastUpdate == null) return true;

    return DateTime.now().difference(lastUpdate) > maxAge;
  }

  /// Clear specific user from cache
  static Future<void> clearUserCache(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$uid');
      await prefs.remove('$_lastUpdatePrefix$uid');
      debugPrint('🗑️ Cleared cache for user: $uid');
    } catch (e) {
      debugPrint('❌ Error clearing user cache: $e');
    }
  }

  /// Clear all user caches (useful for logout)
  static Future<void> clearAllCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int cleared = 0;

      for (final key in keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_lastUpdatePrefix)) {
          await prefs.remove(key);
          cleared++;
        }
      }

      debugPrint('🗑️ Cleared $cleared cached items');
    } catch (e) {
      debugPrint('❌ Error clearing all caches: $e');
    }
  }

  /// Get cache statistics for debugging
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      int totalUsers = 0;
      List<String> cachedUsernames = [];

      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          totalUsers++;
          final json = prefs.getString(key);
          if (json != null) {
            final map = jsonDecode(json) as Map<String, dynamic>;
            cachedUsernames.add(map['username'] as String);
          }
        }
      }

      return {
        'total_cached_users': totalUsers,
        'cached_usernames': cachedUsernames,
      };
    } catch (e) {
      debugPrint('❌ Error getting cache stats: $e');
      return {};
    }
  }
}
