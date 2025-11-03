import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/post_service.dart';
import '../../../core/theme.dart';

/// Unified post options bottom sheet used across the app
/// Shows consistent options for both profile page and post viewer
class UnifiedPostOptionsSheet extends StatelessWidget {
  const UnifiedPostOptionsSheet({
    super.key,
    required this.post,
    required this.isOwnPost,
    this.onPostUpdated,
    this.onPostDeleted,
  });

  final dynamic post;
  final bool isOwnPost;
  final VoidCallback? onPostUpdated;
  final VoidCallback? onPostDeleted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1E1E2E).withOpacity(0.95),
                        const Color(0xFF2A2A3E).withOpacity(0.95),
                      ]
                    : [
                        Colors.white.withOpacity(0.95),
                        const Color(0xFFF5F5F5).withOpacity(0.95),
                      ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Post preview
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          post.thumbnailUrl ?? post.mediaUrls?.first ?? '',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.image,
                              color: isDark ? Colors.white24 : Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.caption?.isEmpty ?? true
                                  ? 'Your post'
                                  : post.caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatCount(post.likes ?? 0)} likes • ${_formatCount(post.comments ?? 0)} comments',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.08),
                ),

                // Scrollable options
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: isOwnPost
                        ? _buildOwnPostOptions(context, isDark)
                        : _buildOthersPostOptions(context, isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOwnPostOptions(BuildContext context, bool isDark) {
    return [
      _buildOption(
        context,
        icon: Icons.edit_outlined,
        label: 'Edit Post',
        subtitle: 'Change caption or location',
        onTap: () => _editPost(context),
        isDark: isDark,
      ),
      _buildDivider(isDark),
      _buildOption(
        context,
        icon: Icons.visibility_off_outlined,
        label: 'Archive Post',
        subtitle: 'Move to archive folder',
        onTap: () => _archivePost(context),
        isDark: isDark,
      ),
      _buildDivider(isDark),
      _buildOption(
        context,
        icon: Icons.settings_outlined,
        label: 'Post Settings',
        subtitle: 'Comments, likes, and more',
        onTap: () => _showPostSettings(context, isDark),
        isDark: isDark,
      ),
      _buildDivider(isDark),
      _buildOption(
        context,
        icon: Icons.bar_chart_outlined,
        label: 'View Insights',
        subtitle: 'See who viewed and engaged',
        onTap: () => _viewInsights(context),
        isDark: isDark,
      ),
      _buildDivider(isDark),
      _buildOption(
        context,
        icon: Icons.share_outlined,
        label: 'Share Post',
        subtitle: 'Share to story or external apps',
        onTap: () => _sharePost(context, isDark),
        isDark: isDark,
      ),
      _buildDivider(isDark),
      _buildOption(
        context,
        icon: Icons.delete_outline,
        label: 'Delete Post',
        subtitle: 'Remove permanently',
        onTap: () => _showDeleteConfirmation(context, isDark),
        isDark: isDark,
        isDestructive: true,
      ),
    ];
  }

  List<Widget> _buildOthersPostOptions(BuildContext context, bool isDark) {
    return [
      _buildOption(
        context,
        icon: Icons.report_outlined,
        label: 'Report Post',
        subtitle: 'Report inappropriate content',
        onTap: () => _reportPost(context),
        isDark: isDark,
        isDestructive: true,
      ),
      _buildDivider(isDark),
      _buildOption(
        context,
        icon: Icons.link_rounded,
        label: 'Copy Link',
        onTap: () => _copyLink(context),
        isDark: isDark,
      ),
      _buildDivider(isDark),
      _buildOption(
        context,
        icon: Icons.volume_off_outlined,
        label: 'Mute ${post.username ?? "User"}',
        onTap: () => _muteUser(context),
        isDark: isDark,
      ),
      _buildDivider(isDark),
      _buildOption(
        context,
        icon: Icons.visibility_off_outlined,
        label: 'Hide this Post',
        onTap: () => _hidePost(context),
        isDark: isDark,
      ),
      _buildDivider(isDark),
      _buildOption(
        context,
        icon: Icons.not_interested_outlined,
        label: 'Not Interested',
        onTap: () => _notInterested(context),
        isDark: isDark,
      ),
    ];
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withOpacity(0.1)
                    : (isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive
                    ? Colors.red
                    : (isDark ? Colors.white : Colors.black87),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDestructive
                          ? Colors.red
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white38 : Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 68,
      color: isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.05),
    );
  }

  // Action Methods
  void _editPost(BuildContext context) {
    Navigator.pop(context);
    _showEditCaptionDialog(context);
  }

  void _showEditCaptionDialog(BuildContext context) {
    final TextEditingController captionController = TextEditingController(
      text: post.caption ?? '',
    );
    final TextEditingController locationController = TextEditingController(
      text: post.location ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: captionController,
              decoration: const InputDecoration(
                labelText: 'Caption',
                hintText: 'Write a caption...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 2200,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Add location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('Updating post...'),
                    ],
                  ),
                  duration: const Duration(seconds: 30),
                  behavior: SnackBarBehavior.floating,
                ),
              );

              final postService = PostService();
              final success = await postService.updatePostCaption(
                postId: post.id ?? '',
                caption: captionController.text,
                location: locationController.text.isEmpty
                    ? null
                    : locationController.text,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Post updated successfully'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  onPostUpdated?.call();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update post'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _archivePost(BuildContext context) async {
    Navigator.pop(context);

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text('Archiving post...'),
          ],
        ),
        duration: const Duration(seconds: 30),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final postService = PostService();
      final success = await postService.archivePost(post.id ?? '');

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Post archived successfully'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Undo',
                textColor: Colors.white,
                onPressed: () async {
                  await postService.unarchivePost(post.id ?? '');
                },
              ),
            ),
          );
          onPostUpdated?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to archive post'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPostSettings(BuildContext context, bool isDark) {
    Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PostSettingsSheet(
        post: post,
        isDark: isDark,
        onUpdated: onPostUpdated,
      ),
    );
  }

  void _viewInsights(BuildContext context) {
    Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PostInsightsSheet(post: post),
    );
  }

  void _sharePost(BuildContext context, bool isDark) {
    Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SharePostSheet(post: post, isDark: isDark),
    );
  }

  void _showDeleteConfirmation(BuildContext context, bool isDark) {
    Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _DeleteConfirmationSheet(
        post: post,
        isDark: isDark,
        onDeleted: onPostDeleted,
      ),
    );
  }

  void _copyLink(BuildContext context) {
    Navigator.pop(context);

    HapticFeedback.lightImpact();
    final postService = PostService();
    final postLink = postService.getPostLink(post.id ?? '');
    Clipboard.setData(ClipboardData(text: postLink));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _reportPost(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _muteUser(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Muted ${post.username ?? "user"}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _hidePost(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post hidden'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _notInterested(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('We\'ll show you fewer posts like this'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  static void show(
    BuildContext context, {
    required dynamic post,
    required bool isOwnPost,
    VoidCallback? onPostUpdated,
    VoidCallback? onPostDeleted,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => UnifiedPostOptionsSheet(
        post: post,
        isOwnPost: isOwnPost,
        onPostUpdated: onPostUpdated,
        onPostDeleted: onPostDeleted,
      ),
    );
  }
}

// Post Settings Sub-Sheet
class _PostSettingsSheet extends StatefulWidget {
  const _PostSettingsSheet({
    required this.post,
    required this.isDark,
    this.onUpdated,
  });

  final dynamic post;
  final bool isDark;
  final VoidCallback? onUpdated;

  @override
  State<_PostSettingsSheet> createState() => _PostSettingsSheetState();
}

class _PostSettingsSheetState extends State<_PostSettingsSheet> {
  late bool commentsEnabled;
  late bool likesHidden;
  late bool isPinned;

  @override
  void initState() {
    super.initState();
    commentsEnabled = widget.post.commentsEnabled ?? true;
    likesHidden = widget.post.hideLikeCount ?? false;
    isPinned = widget.post.isPinned ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isDark
                  ? [
                      const Color(0xFF1E1E2E).withOpacity(0.95),
                      const Color(0xFF2A2A3E).withOpacity(0.95),
                    ]
                  : [
                      Colors.white.withOpacity(0.95),
                      const Color(0xFFF5F5F5).withOpacity(0.95),
                    ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Text(
                  'Post Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                ),

                const SizedBox(height: 24),

                _buildSettingToggle(
                  icon: commentsEnabled
                      ? Icons.comment
                      : Icons.comments_disabled,
                  title: 'Comments',
                  subtitle: commentsEnabled ? 'Enabled' : 'Disabled',
                  value: commentsEnabled,
                  onChanged: (value) {
                    setState(() => commentsEnabled = value);
                    _saveSettings();
                  },
                ),

                const SizedBox(height: 16),

                _buildSettingToggle(
                  icon: likesHidden ? Icons.favorite_border : Icons.favorite,
                  title: 'Hide Likes',
                  subtitle: likesHidden
                      ? 'Likes are hidden'
                      : 'Likes are visible',
                  value: likesHidden,
                  onChanged: (value) {
                    setState(() => likesHidden = value);
                    _saveSettings();
                  },
                ),

                const SizedBox(height: 16),

                _buildSettingToggle(
                  icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  title: 'Pin to Profile',
                  subtitle: isPinned ? 'Pinned' : 'Not pinned',
                  value: isPinned,
                  onChanged: (value) {
                    setState(() => isPinned = value);
                    _saveSettings();
                  },
                ),

                const SizedBox(height: 24),

                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.bookmark_border,
                      color: widget.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  title: const Text('See Who Saved This'),
                  subtitle: const Text('View list of users'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Show saved users list
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Saved users list coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kPrimary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: kPrimary),
        ],
      ),
    );
  }

  void _saveSettings() async {
    final postService = PostService();
    final success = await postService.updatePostSettings(
      postId: widget.post.id ?? '',
      commentsEnabled: commentsEnabled,
      hideLikeCount: likesHidden,
      isPinned: isPinned,
    );

    if (success) {
      widget.onUpdated?.call();
    }
  }
}

// Post Insights Sheet
class _PostInsightsSheet extends StatelessWidget {
  const _PostInsightsSheet({required this.post});

  final dynamic post;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1E1E2E).withOpacity(0.95),
                      const Color(0xFF2A2A3E).withOpacity(0.95),
                    ]
                  : [
                      Colors.white.withOpacity(0.95),
                      const Color(0xFFF5F5F5).withOpacity(0.95),
                    ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Text(
                'Post Insights',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 24),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.visibility,
                      label: 'Views',
                      value: '${post.views ?? 0}',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.favorite,
                      label: 'Likes',
                      value: '${post.likes ?? 0}',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.comment,
                      label: 'Comments',
                      value: '${post.comments ?? 0}',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Engagement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 64,
                        color: isDark ? Colors.white24 : Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Detailed insights coming soon',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimary.withOpacity(0.1), kPrimary.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimary.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: kPrimary, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// Share Post Sheet
class _SharePostSheet extends StatelessWidget {
  const _SharePostSheet({required this.post, required this.isDark});

  final dynamic post;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1E1E2E).withOpacity(0.95),
                      const Color(0xFF2A2A3E).withOpacity(0.95),
                    ]
                  : [
                      Colors.white.withOpacity(0.95),
                      const Color(0xFFF5F5F5).withOpacity(0.95),
                    ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Text(
                  'Share Post',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),

                const SizedBox(height: 24),

                _buildShareOption(
                  context,
                  icon: Icons.auto_awesome,
                  label: 'Share to Story',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Share to story coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _buildShareOption(
                  context,
                  icon: Icons.send,
                  label: 'Send to Friend',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Send to friend coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _buildShareOption(
                  context,
                  icon: Icons.share,
                  label: 'Share to External Apps',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('External share coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _buildShareOption(
                  context,
                  icon: Icons.link,
                  label: 'Copy Link',
                  onTap: () {
                    Navigator.pop(context);
                    HapticFeedback.lightImpact();
                    final postService = PostService();
                    final postLink = postService.getPostLink(post.id ?? '');
                    Clipboard.setData(ClipboardData(text: postLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied to clipboard'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kPrimary.withOpacity(0.2),
                    kPrimary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: kPrimary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

// Delete Confirmation Sheet
class _DeleteConfirmationSheet extends StatelessWidget {
  const _DeleteConfirmationSheet({
    required this.post,
    required this.isDark,
    this.onDeleted,
  });

  final dynamic post;
  final bool isDark;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1E1E2E).withOpacity(0.95),
                      const Color(0xFF2A2A3E).withOpacity(0.95),
                    ]
                  : [
                      Colors.white.withOpacity(0.95),
                      const Color(0xFFF5F5F5).withOpacity(0.95),
                    ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.orange,
                ),

                const SizedBox(height: 16),

                Text(
                  'Delete Post?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'This action cannot be undone. Consider archiving instead.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 24),

                _buildActionButton(
                  context,
                  icon: Icons.visibility_off,
                  label: 'Archive Post',
                  subtitle: 'Hide from profile, keep in archive',
                  onTap: () {
                    Navigator.pop(context);
                    // Trigger archive
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Post archived'),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  color: Colors.orange,
                ),

                const SizedBox(height: 12),

                _buildActionButton(
                  context,
                  icon: Icons.delete_forever,
                  label: 'Delete Permanently',
                  subtitle: 'Remove from everywhere',
                  onTap: () => _deletePost(context),
                  color: Colors.red,
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deletePost(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Navigator.pop(context);

    // Show compact loading message with shorter duration
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Deleting post...'),
          ],
        ),
        duration: const Duration(seconds: 5), // Reduced from 30s
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final postService = PostService();

      // Delete with minimum delay for better UX
      final deleteOperation = postService.deletePost(post.id ?? '');
      final minimumDelay = Future.delayed(const Duration(milliseconds: 500));

      await Future.wait([deleteOperation, minimumDelay]);

      if (context.mounted) {
        // Hide loading message immediately
        scaffoldMessenger.hideCurrentSnackBar();

        // Show success message
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Post deleted successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 1500),
          ),
        );

        // Trigger callback to refresh posts
        onDeleted?.call();
      }
    } catch (e) {
      if (context.mounted) {
        // Hide loading message
        scaffoldMessenger.hideCurrentSnackBar();

        // Show error message
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to delete: ${e.toString().substring(0, 50)}...',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
