import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/models/reel_model.dart';
import 'edit_reel_sheet.dart';

/// Creator control bar for own reels - provides edit, delete, insights options
class CreatorControlBar extends StatelessWidget {
  final ReelModel reel;
  final VoidCallback onDelete;
  final VoidCallback onEditCaption;
  final VoidCallback onChangeCover;
  final VoidCallback onToggleComments;
  final VoidCallback onToggleLikes;
  final VoidCallback onViewInsights;

  const CreatorControlBar({
    super.key,
    required this.reel,
    required this.onDelete,
    required this.onEditCaption,
    required this.onChangeCover,
    required this.onToggleComments,
    required this.onToggleLikes,
    required this.onViewInsights,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CreatorButton(
              icon: Icons.insights_outlined,
              label: 'Insights',
              onTap: onViewInsights,
            ),
            _CreatorButton(
              icon: Icons.edit_outlined,
              label: 'Edit',
              onTap: () => _showEditOptions(context),
            ),
            _CreatorButton(
              icon: Icons.share_outlined,
              label: 'Share',
              onTap: () => _shareReel(context),
            ),
            _CreatorButton(
              icon: Icons.more_horiz,
              label: 'More',
              onTap: () => _showMoreOptions(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => EditReelSheet(
        reel: reel,
        onEditCaption: onEditCaption,
        onChangeCover: onChangeCover,
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MoreOptionsSheet(
        reel: reel,
        onDelete: onDelete,
        onToggleComments: onToggleComments,
        onToggleLikes: onToggleLikes,
      ),
    );
  }

  void _shareReel(BuildContext context) {
    // TODO: Replace with actual deep link once implemented
    final reelUrl = 'https://syncup.app/reels/${reel.id}';
    Share.share(
      '${reel.caption ?? "Check out my reel!"}\n\n$reelUrl',
      subject: 'Check out my reel on SyncUp',
    );
  }
}

class _CreatorButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CreatorButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreOptionsSheet extends StatelessWidget {
  final ReelModel reel;
  final VoidCallback onDelete;
  final VoidCallback onToggleComments;
  final VoidCallback onToggleLikes;

  const _MoreOptionsSheet({
    required this.reel,
    required this.onDelete,
    required this.onToggleComments,
    required this.onToggleLikes,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _OptionTile(
              icon: Icons.comment_outlined,
              title: 'Toggle Comments',
              subtitle: 'Allow or disable comments',
              onTap: () {
                Navigator.pop(context);
                onToggleComments();
              },
            ),
            _OptionTile(
              icon: Icons.favorite_outline,
              title: 'Toggle Likes',
              subtitle: 'Show or hide like count',
              onTap: () {
                Navigator.pop(context);
                onToggleLikes();
              },
            ),
            const Divider(height: 1),
            _OptionTile(
              icon: Icons.archive_outlined,
              title: 'Archive Reel',
              subtitle: 'Hide from profile',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement archive
              },
            ),
            _OptionTile(
              icon: Icons.delete_outline,
              title: 'Delete Reel',
              subtitle: 'Permanently remove',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reel?'),
        content: const Text(
          'This action cannot be undone. Your reel will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? (isDark ? Colors.white : Colors.black87),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? (isDark ? Colors.white : Colors.black87),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontSize: 12,
        ),
      ),
      onTap: onTap,
    );
  }
}
