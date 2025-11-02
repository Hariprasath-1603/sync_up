import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling user moderation (block, mute, report)
class ModerationService {
  static final ModerationService _instance = ModerationService._internal();
  factory ModerationService() => _instance;
  ModerationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== BLOCK ====================

  /// Block a user
  Future<bool> blockUser(String userId, {String? reason}) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null || currentUserId == userId) {
        return false;
      }

      // Add block
      await _supabase.from('blocked_users').insert({
        'blocker_id': currentUserId,
        'blocked_id': userId,
        if (reason != null) 'reason': reason,
      });

      // Remove following relationship if exists
      await _supabase
          .from('followers')
          .delete()
          .eq('follower_id', currentUserId)
          .eq('following_id', userId);

      await _supabase
          .from('followers')
          .delete()
          .eq('follower_id', userId)
          .eq('following_id', currentUserId);

      print('✅ User blocked successfully');
      return true;
    } catch (e) {
      print('❌ Error blocking user: $e');
      return false;
    }
  }

  /// Unblock a user
  Future<bool> unblockUser(String userId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      await _supabase
          .from('blocked_users')
          .delete()
          .eq('blocker_id', currentUserId)
          .eq('blocked_id', userId);

      print('✅ User unblocked successfully');
      return true;
    } catch (e) {
      print('❌ Error unblocking user: $e');
      return false;
    }
  }

  /// Check if user is blocked
  Future<bool> isUserBlocked(String userId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      final result = await _supabase
          .from('blocked_users')
          .select('id')
          .eq('blocker_id', currentUserId)
          .eq('blocked_id', userId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      print('❌ Error checking block status: $e');
      return false;
    }
  }

  /// Get list of blocked user IDs
  Future<List<String>> getBlockedUserIds() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return [];

      final result = await _supabase
          .from('blocked_users')
          .select('blocked_id')
          .eq('blocker_id', currentUserId);

      return (result as List)
          .map((item) => item['blocked_id'] as String)
          .toList();
    } catch (e) {
      print('❌ Error getting blocked users: $e');
      return [];
    }
  }

  // ==================== MUTE ====================

  /// Mute a user
  Future<bool> muteUser(String userId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null || currentUserId == userId) {
        return false;
      }

      await _supabase.from('muted_users').insert({
        'muter_id': currentUserId,
        'muted_id': userId,
      });

      print('✅ User muted successfully');
      return true;
    } catch (e) {
      print('❌ Error muting user: $e');
      return false;
    }
  }

  /// Unmute a user
  Future<bool> unmuteUser(String userId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      await _supabase
          .from('muted_users')
          .delete()
          .eq('muter_id', currentUserId)
          .eq('muted_id', userId);

      print('✅ User unmuted successfully');
      return true;
    } catch (e) {
      print('❌ Error unmuting user: $e');
      return false;
    }
  }

  /// Check if user is muted
  Future<bool> isUserMuted(String userId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      final result = await _supabase
          .from('muted_users')
          .select('id')
          .eq('muter_id', currentUserId)
          .eq('muted_id', userId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      print('❌ Error checking mute status: $e');
      return false;
    }
  }

  /// Get list of muted user IDs
  Future<List<String>> getMutedUserIds() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return [];

      final result = await _supabase
          .from('muted_users')
          .select('muted_id')
          .eq('muter_id', currentUserId);

      return (result as List)
          .map((item) => item['muted_id'] as String)
          .toList();
    } catch (e) {
      print('❌ Error getting muted users: $e');
      return [];
    }
  }

  // ==================== REPORT ====================

  /// Report a user
  Future<bool> reportUser({
    required String userId,
    required String reportType,
    String? description,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null || currentUserId == userId) {
        return false;
      }

      await _supabase.from('reports').insert({
        'reporter_id': currentUserId,
        'reported_user_id': userId,
        'report_type': reportType,
        if (description != null) 'description': description,
      });

      print('✅ User reported successfully');
      return true;
    } catch (e) {
      print('❌ Error reporting user: $e');
      return false;
    }
  }

  /// Report a post
  Future<bool> reportPost({
    required String postId,
    required String reportType,
    String? description,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      await _supabase.from('reports').insert({
        'reporter_id': currentUserId,
        'reported_post_id': postId,
        'report_type': reportType,
        if (description != null) 'description': description,
      });

      print('✅ Post reported successfully');
      return true;
    } catch (e) {
      print('❌ Error reporting post: $e');
      return false;
    }
  }

  /// Get available report types
  List<Map<String, String>> getReportTypes() {
    return [
      {'value': 'spam', 'label': 'Spam'},
      {'value': 'harassment', 'label': 'Harassment or Bullying'},
      {'value': 'inappropriate', 'label': 'Inappropriate Content'},
      {'value': 'impersonation', 'label': 'Impersonation'},
      {'value': 'violence', 'label': 'Violence or Dangerous Content'},
      {'value': 'hate_speech', 'label': 'Hate Speech'},
      {'value': 'false_info', 'label': 'False Information'},
      {'value': 'self_harm', 'label': 'Self-Harm or Suicide'},
      {'value': 'other', 'label': 'Other'},
    ];
  }

  // ==================== UTILITY ====================

  /// Filter posts to exclude blocked and muted users
  Future<List<T>> filterPostsByBlockedAndMuted<T>(
    List<T> posts,
    String Function(T) getUserIdExtractor,
  ) async {
    try {
      final blockedIds = await getBlockedUserIds();
      final mutedIds = await getMutedUserIds();
      final excludedIds = {...blockedIds, ...mutedIds};

      if (excludedIds.isEmpty) return posts;

      return posts
          .where((post) => !excludedIds.contains(getUserIdExtractor(post)))
          .toList();
    } catch (e) {
      print('❌ Error filtering posts: $e');
      return posts;
    }
  }
}
