import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final _supabase = Supabase.instance.client;

  /// Send a follow request notification (for private accounts)
  Future<bool> sendFollowRequest({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'type': 'follow_request',
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      });
      return true;
    } catch (e) {
      print('❌ Error sending follow request: $e');
      return false;
    }
  }

  /// Send a follow notification (for public accounts)
  Future<bool> sendFollowNotification({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'type': 'follow',
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      });
      return true;
    } catch (e) {
      print('❌ Error sending follow notification: $e');
      return false;
    }
  }

  /// Send a like notification
  Future<bool> sendLikeNotification({
    required String fromUserId,
    required String toUserId,
    required String postId,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'post_id': postId,
        'type': 'like',
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      });
      return true;
    } catch (e) {
      print('❌ Error sending like notification: $e');
      return false;
    }
  }

  /// Send a comment notification
  Future<bool> sendCommentNotification({
    required String fromUserId,
    required String toUserId,
    required String postId,
    required String commentText,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'post_id': postId,
        'comment_text': commentText,
        'type': 'comment',
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      });
      return true;
    } catch (e) {
      print('❌ Error sending comment notification: $e');
      return false;
    }
  }

  /// Get all notifications for a user
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('''
            *,
            from_user:users!notifications_from_user_id_fkey(uid, username, display_name, photo_url)
          ''')
          .eq('to_user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ Error getting notifications: $e');
      return [];
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('to_user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      return true;
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('to_user_id', userId)
          .eq('is_read', false);
      return true;
    } catch (e) {
      print('❌ Error marking all as read: $e');
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _supabase.from('notifications').delete().eq('id', notificationId);
      return true;
    } catch (e) {
      print('❌ Error deleting notification: $e');
      return false;
    }
  }

  /// Accept follow request
  Future<bool> acceptFollowRequest({
    required String notificationId,
    required String followerId,
    required String followingId,
  }) async {
    try {
      // Start a transaction-like operation
      // 1. Create follow relationship
      await _supabase.from('follows').insert({
        'follower_id': followerId,
        'following_id': followingId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. Delete the follow request notification
      await deleteNotification(notificationId);

      // 3. Send acceptance notification
      await sendFollowNotification(
        fromUserId: followingId,
        toUserId: followerId,
      );

      return true;
    } catch (e) {
      print('❌ Error accepting follow request: $e');
      return false;
    }
  }

  /// Reject follow request
  Future<bool> rejectFollowRequest(String notificationId) async {
    try {
      await deleteNotification(notificationId);
      return true;
    } catch (e) {
      print('❌ Error rejecting follow request: $e');
      return false;
    }
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }
}
