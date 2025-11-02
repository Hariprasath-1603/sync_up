import 'package:flutter/material.dart';
import '../../../core/services/moderation_service.dart';
import '../../../core/services/interaction_service.dart';

class PostActionsMenu extends StatelessWidget {
  final String postId;
  final String postOwnerId;
  final String currentUserId;
  final bool isOwnPost;
  final VoidCallback? onPostDeleted;
  final VoidCallback? onPostReported;
  final VoidCallback? onUserBlocked;

  const PostActionsMenu({
    super.key,
    required this.postId,
    required this.postOwnerId,
    required this.currentUserId,
    required this.isOwnPost,
    this.onPostDeleted,
    this.onPostReported,
    this.onUserBlocked,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moderationService = ModerationService();
    final interactionService = InteractionService();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D24) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white30 : Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Own post actions
          if (isOwnPost) ...[
            _MenuItem(
              icon: Icons.delete_outline,
              label: 'Delete Post',
              color: Colors.red,
              onTap: () async {
                Navigator.pop(context);
                final confirm = await _showDeleteConfirmation(context);
                if (confirm == true) {
                  // TODO: Implement delete post
                  onPostDeleted?.call();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Post deleted'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            _MenuItem(
              icon: Icons.edit_outlined,
              label: 'Edit Post',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to edit post page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit feature coming soon'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            _MenuItem(
              icon: Icons.archive_outlined,
              label: 'Archive Post',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement archive
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post archived'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            _MenuItem(
              icon: Icons.comments_disabled_outlined,
              label: 'Turn Off Commenting',
              onTap: () {
                Navigator.pop(context);
                // TODO: Toggle comments
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Commenting turned off'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ]
          // Other user's post actions
          else ...[
            _MenuItem(
              icon: Icons.bookmark_border,
              label: 'Save Post',
              onTap: () async {
                Navigator.pop(context);
                await interactionService.toggleSave(postId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post saved'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            _MenuItem(
              icon: Icons.share_outlined,
              label: 'Share Post',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share feature coming soon'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            _MenuItem(
              icon: Icons.link_outlined,
              label: 'Copy Link',
              onTap: () {
                Navigator.pop(context);
                // TODO: Copy link to clipboard
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            _MenuItem(
              icon: Icons.person_remove_outlined,
              label: 'Unfollow',
              onTap: () async {
                Navigator.pop(context);
                await interactionService.toggleFollow(postOwnerId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Unfollowed user'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            _MenuItem(
              icon: Icons.volume_off_outlined,
              label: 'Mute',
              onTap: () async {
                Navigator.pop(context);
                await moderationService.muteUser(postOwnerId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'User muted. You won\'t see their posts anymore',
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            _MenuItem(
              icon: Icons.info_outline,
              label: 'Why am I seeing this?',
              onTap: () {
                Navigator.pop(context);
                _showWhySeeing(context);
              },
            ),
            _MenuItem(
              icon: Icons.not_interested_outlined,
              label: 'Not Interested',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('We\'ll show you fewer posts like this'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            _MenuItem(
              icon: Icons.report_outlined,
              label: 'Report Post',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(context, moderationService);
              },
            ),
            _MenuItem(
              icon: Icons.block_outlined,
              label: 'Block User',
              color: Colors.red,
              onTap: () async {
                Navigator.pop(context);
                final confirm = await _showBlockConfirmation(context);
                if (confirm == true) {
                  final success = await moderationService.blockUser(
                    postOwnerId,
                  );
                  if (success) {
                    onUserBlocked?.call();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User blocked successfully'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showBlockConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User?'),
        content: const Text(
          'This user won\'t be able to see your profile, posts, or stories. They won\'t be notified that you blocked them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showWhySeeing(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Why am I seeing this?'),
        content: const Text(
          'You\'re seeing this post because:\n\n'
          '• It\'s from someone you follow\n'
          '• It\'s popular and trending\n'
          '• Based on your interests and activity\n'
          '• Recommended by our algorithm',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(
    BuildContext context,
    ModerationService moderationService,
  ) {
    final reportTypes = moderationService.getReportTypes();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report Post',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Why are you reporting this post?',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: reportTypes.length,
                  itemBuilder: (context, index) {
                    final type = reportTypes[index];
                    return ListTile(
                      title: Text(type['label']!),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        Navigator.pop(context);
                        final success = await moderationService.reportPost(
                          postId: postId,
                          reportType: type['value']!,
                        );
                        if (success) {
                          onPostReported?.call();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Thank you for your report'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = color ?? (isDark ? Colors.white : Colors.black87);

    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(label, style: TextStyle(color: textColor)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
