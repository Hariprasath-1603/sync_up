import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'create_post_page.dart';

class ScheduledPostsPage extends StatefulWidget {
  const ScheduledPostsPage({super.key});

  @override
  State<ScheduledPostsPage> createState() => _ScheduledPostsPageState();
}

class _ScheduledPostsPageState extends State<ScheduledPostsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock scheduled posts - TODO: Load from server
  final List<Map<String, dynamic>> _upcomingPosts = [
    {
      'id': '1',
      'title': 'Product Launch Announcement',
      'text':
          'Excited to announce our new product line! Check it out 🚀 #ProductLaunch',
      'audience': 'Public',
      'hasMedia': true,
      'mediaCount': 5,
      'scheduledFor': DateTime.now().add(const Duration(hours: 3)),
      'status': 'pending',
    },
    {
      'id': '2',
      'title': '',
      'text':
          'Monday motivation! Let\'s start the week strong 💪 #MondayMotivation',
      'audience': 'Public',
      'hasMedia': true,
      'mediaCount': 1,
      'scheduledFor': DateTime.now().add(const Duration(days: 1)),
      'status': 'pending',
    },
    {
      'id': '3',
      'title': 'Team Meeting Reminder',
      'text': 'Don\'t forget about our team meeting today at 2 PM!',
      'audience': 'Friends',
      'hasMedia': false,
      'mediaCount': 0,
      'location': {'name': 'Office'},
      'scheduledFor': DateTime.now().add(const Duration(days: 2)),
      'status': 'pending',
    },
    {
      'id': '4',
      'title': 'Weekend Plans',
      'text': 'Planning a beach trip this weekend! Who\'s in? 🏖️',
      'audience': 'Friends',
      'hasMedia': true,
      'mediaCount': 3,
      'scheduledFor': DateTime.now().add(const Duration(days: 5)),
      'status': 'pending',
    },
  ];

  final List<Map<String, dynamic>> _publishedPosts = [
    {
      'id': '5',
      'title': 'Morning Coffee',
      'text': 'Coffee time ☕ Starting the day right!',
      'audience': 'Public',
      'hasMedia': true,
      'mediaCount': 1,
      'scheduledFor': DateTime.now().subtract(const Duration(hours: 2)),
      'publishedAt': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'published',
      'views': 1234,
      'likes': 89,
      'comments': 15,
    },
    {
      'id': '6',
      'title': '',
      'text': 'Friday vibes! 🎉 #TGIF',
      'audience': 'Public',
      'hasMedia': false,
      'mediaCount': 0,
      'scheduledFor': DateTime.now().subtract(const Duration(days: 1)),
      'publishedAt': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'published',
      'views': 2567,
      'likes': 156,
      'comments': 23,
    },
  ];

  final List<Map<String, dynamic>> _failedPosts = [
    {
      'id': '7',
      'title': 'Video Upload',
      'text': 'Check out this amazing video! #viral',
      'audience': 'Public',
      'hasMedia': true,
      'mediaCount': 1,
      'scheduledFor': DateTime.now().subtract(const Duration(hours: 5)),
      'status': 'failed',
      'errorMessage': 'Network error during upload',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Theme helper methods
  Color _getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0B0E13)
        : const Color(0xFFF6F7FB);
  }

  Color _getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1D24)
        : Colors.white;
  }

  Color _getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

  Color _getSubtitleColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white54
        : Colors.grey[600]!;
  }

  Color _getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white12
        : Colors.grey[300]!;
  }

  void _openScheduledPost(Map<String, dynamic> post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreatePostPage(draftData: post)),
    );

    if (result == true) {
      setState(() {
        _upcomingPosts.removeWhere((p) => p['id'] == post['id']);
      });
    }
  }

  void _cancelScheduledPost(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getCardColor(context),
        title: Text(
          'Cancel Scheduled Post?',
          style: TextStyle(color: _getTextColor(context)),
        ),
        content: Text(
          'This will cancel the scheduled post. You can find it in drafts.',
          style: TextStyle(color: _getSubtitleColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _upcomingPosts.removeWhere((p) => p['id'] == post['id']);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scheduled post cancelled and saved to drafts'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Cancel Post',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _retryFailedPost(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getCardColor(context),
        title: Text(
          'Retry Post?',
          style: TextStyle(color: _getTextColor(context)),
        ),
        content: Text(
          'Retry publishing this post?\n\nError: ${post['errorMessage']}',
          style: TextStyle(color: _getSubtitleColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                post['status'] = 'pending';
                post['scheduledFor'] = DateTime.now().add(
                  const Duration(minutes: 5),
                );
                _upcomingPosts.insert(0, post);
                _failedPosts.removeWhere((p) => p['id'] == post['id']);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Post rescheduled'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _deletePost(Map<String, dynamic> post, String listType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getCardColor(context),
        title: Text(
          'Delete Post?',
          style: TextStyle(color: _getTextColor(context)),
        ),
        content: Text(
          'This action cannot be undone.',
          style: TextStyle(color: _getSubtitleColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (listType == 'upcoming') {
                  _upcomingPosts.removeWhere((p) => p['id'] == post['id']);
                } else if (listType == 'failed') {
                  _failedPosts.removeWhere((p) => p['id'] == post['id']);
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Post deleted'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatScheduledTime(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.isNegative) {
      return DateFormat('MMM d, y · h:mm a').format(date);
    }

    if (difference.inDays > 0) {
      return 'In ${difference.inDays}d · ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours}h ${difference.inMinutes % 60}m';
    } else if (difference.inMinutes > 0) {
      return 'In ${difference.inMinutes}m';
    } else {
      return 'Publishing soon...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: _getCardColor(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _getTextColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scheduled Posts',
          style: TextStyle(color: _getTextColor(context)),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4A6CF7),
          labelColor: _getTextColor(context),
          unselectedLabelColor: _getSubtitleColor(context),
          tabs: [
            Tab(text: 'Upcoming (${_upcomingPosts.length})'),
            Tab(text: 'Published (${_publishedPosts.length})'),
            Tab(text: 'Failed (${_failedPosts.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingTab(),
          _buildPublishedTab(),
          _buildFailedTab(),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (_upcomingPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 80, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              'No upcoming posts',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Schedule posts to publish later',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Sort by scheduled time
    _upcomingPosts.sort(
      (a, b) => (a['scheduledFor'] as DateTime).compareTo(
        b['scheduledFor'] as DateTime,
      ),
    );

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _upcomingPosts.length,
      itemBuilder: (context, index) {
        final post = _upcomingPosts[index];
        return _buildUpcomingPostCard(post);
      },
    );
  }

  Widget _buildPublishedTab() {
    if (_publishedPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: _getSubtitleColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'No published posts',
              style: TextStyle(
                color: _getSubtitleColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _publishedPosts.length,
      itemBuilder: (context, index) {
        final post = _publishedPosts[index];
        return _buildPublishedPostCard(post);
      },
    );
  }

  Widget _buildFailedTab() {
    if (_failedPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: _getSubtitleColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'No failed posts',
              style: TextStyle(
                color: _getSubtitleColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _failedPosts.length,
      itemBuilder: (context, index) {
        final post = _failedPosts[index];
        return _buildFailedPostCard(post);
      },
    );
  }

  Widget _buildUpcomingPostCard(Map<String, dynamic> post) {
    final hasTitle = (post['title'] as String).isNotEmpty;
    final displayTitle = hasTitle ? post['title'] : post['text'];
    final displayText = hasTitle ? post['text'] : null;

    return GestureDetector(
      onTap: () => _openScheduledPost(post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _getCardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF4A6CF7).withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with time
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4A6CF7).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 16,
                    color: Color(0xFF4A6CF7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatScheduledTime(post['scheduledFor']),
                    style: const TextStyle(
                      color: Color(0xFF4A6CF7),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getAudienceColor(post['audience']),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      post['audience'],
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style: TextStyle(
                      color: _getTextColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (displayText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      displayText,
                      style: TextStyle(
                        color: _getSubtitleColor(context),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (post['hasMedia'] == true) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.image,
                          size: 14,
                          color: _getSubtitleColor(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post['mediaCount']} media',
                          style: TextStyle(
                            color: _getSubtitleColor(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Actions
            Divider(height: 1, color: _getBorderColor(context)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () => _openScheduledPost(post),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: _getTextColor(context),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _cancelScheduledPost(post),
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  ),
                  TextButton.icon(
                    onPressed: () => _deletePost(post, 'upcoming'),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishedPostCard(Map<String, dynamic> post) {
    final hasTitle = (post['title'] as String).isNotEmpty;
    final displayTitle = hasTitle ? post['title'] : post['text'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _getCardColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Published ${DateFormat('MMM d, y · h:mm a').format(post['publishedAt'])}',
                      style: TextStyle(
                        color: _getSubtitleColor(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  displayTitle,
                  style: TextStyle(
                    color: _getTextColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatChip(Icons.visibility, post['views'].toString()),
                    const SizedBox(width: 8),
                    _buildStatChip(Icons.favorite, post['likes'].toString()),
                    const SizedBox(width: 8),
                    _buildStatChip(Icons.comment, post['comments'].toString()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedPostCard(Map<String, dynamic> post) {
    final hasTitle = (post['title'] as String).isNotEmpty;
    final displayTitle = hasTitle ? post['title'] : post['text'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    post['errorMessage'],
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              displayTitle,
              style: TextStyle(
                color: _getTextColor(context),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Divider(height: 1, color: _getBorderColor(context)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _retryFailedPost(post),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                ),
                TextButton.icon(
                  onPressed: () => _deletePost(post, 'failed'),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
        ],
      ),
    );
  }

  Color _getAudienceColor(String audience) {
    switch (audience) {
      case 'Public':
        return Colors.blue;
      case 'Friends':
        return Colors.green;
      case 'Only me':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }
}
