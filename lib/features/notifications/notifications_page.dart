import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUserId;

    if (userId != null) {
      final notifications = await _notificationService.getNotifications(userId);
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptFollowRequest(Map<String, dynamic> notification) async {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUserId;

    if (currentUserId == null) return;

    final success = await _notificationService.acceptFollowRequest(
      notificationId: notification['id'],
      followerId: notification['from_user_id'],
      followingId: currentUserId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Follow request accepted')));
      _loadNotifications(); // Refresh
    }
  }

  Future<void> _rejectFollowRequest(Map<String, dynamic> notification) async {
    final success = await _notificationService.rejectFollowRequest(
      notification['id'],
    );

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Follow request rejected')));
      _loadNotifications(); // Refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              final userId = authProvider.currentUserId;
              if (userId != null) {
                await _notificationService.markAllAsRead(userId);
                _loadNotifications();
              }
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.builder(
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return _buildNotificationItem(notification, isDark);
                },
              ),
            ),
    );
  }

  Widget _buildNotificationItem(
    Map<String, dynamic> notification,
    bool isDark,
  ) {
    final type = notification['type'];
    final fromUser = notification['from_user'];
    final isRead = notification['is_read'] ?? false;
    final createdAt = DateTime.parse(notification['created_at']);

    final username = fromUser['username'] ?? 'Unknown';
    final displayName = fromUser['display_name'] ?? username;
    final photoUrl = fromUser['photo_url'] ?? '';

    String message = '';
    Widget? trailing;

    switch (type) {
      case 'follow_request':
        message = 'wants to follow you';
        trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _acceptFollowRequest(notification),
              style: TextButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Accept',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _rejectFollowRequest(notification),
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text('Reject', style: TextStyle(color: Colors.grey[700])),
            ),
          ],
        );
        break;
      case 'follow':
        message = 'started following you';
        break;
      case 'like':
        message = 'liked your post';
        break;
      case 'comment':
        final commentText = notification['comment_text'] ?? '';
        message = 'commented: $commentText';
        break;
      default:
        message = 'sent you a notification';
    }

    return Container(
      color: isRead ? null : kPrimary.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.isEmpty ? const Icon(Icons.person) : null,
        ),
        title: RichText(
          text: TextSpan(
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
            children: [
              TextSpan(
                text: displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ' $message'),
            ],
          ),
        ),
        subtitle: Text(
          timeago.format(createdAt),
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
            fontSize: 12,
          ),
        ),
        trailing: trailing,
        onTap: () {
          _notificationService.markAsRead(notification['id']);
          setState(() {
            notification['is_read'] = true;
          });
        },
      ),
    );
  }
}
