import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/reel_model.dart';

/// Dynamic 3-dot menu options sheet
/// Shows different options based on ownership (creator vs viewer)
class DynamicOptionsSheet extends StatelessWidget {
  final ReelModel reel;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onChangeCover;
  final VoidCallback? onEditPrivacy;
  final VoidCallback? onChangeCategory;
  final VoidCallback? onTagPeople;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final VoidCallback? onToggleComments;
  final VoidCallback? onToggleLikes;
  final VoidCallback? onViewInsights;
  final VoidCallback? onShare;
  final VoidCallback? onHideFromExplore;
  final VoidCallback? onReport;
  final VoidCallback? onWhyAmISeeingThis;
  final VoidCallback? onInterested;
  final VoidCallback? onNotInterested;
  final VoidCallback? onSave;
  final VoidCallback? onCopyLink;

  const DynamicOptionsSheet({
    super.key,
    required this.reel,
    required this.isOwner,
    this.onEdit,
    this.onChangeCover,
    this.onEditPrivacy,
    this.onChangeCategory,
    this.onTagPeople,
    this.onDelete,
    this.onArchive,
    this.onToggleComments,
    this.onToggleLikes,
    this.onViewInsights,
    this.onShare,
    this.onHideFromExplore,
    this.onReport,
    this.onWhyAmISeeingThis,
    this.onInterested,
    this.onNotInterested,
    this.onSave,
    this.onCopyLink,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1D24).withOpacity(0.98),
                  const Color(0xFF0D0F14).withOpacity(0.98),
                ]
              : [
                  Colors.white.withOpacity(0.98),
                  Colors.grey[50]!.withOpacity(0.98),
                ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    isOwner ? 'Creator Controls' : 'Options',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),

                // Divider
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                ),

                // Options list
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: isOwner
                        ? _buildCreatorOptions(context, isDark)
                        : _buildViewerOptions(context, isDark),
                  ),
                ),

                // Cancel button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _buildCancelButton(context, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Creator (Own Reel) Options
  Widget _buildCreatorOptions(BuildContext context, bool isDark) {
    return Column(
      children: [
        _buildOption(
          context,
          icon: Icons.edit_outlined,
          title: 'Edit Reel Info',
          subtitle: 'Change caption, hashtags, or location',
          iconColor: const Color(0xFF7C3AED),
          onTap: onEdit,
          isDark: isDark,
        ),
        _buildOption(
          context,
          icon: Icons.photo_library_outlined,
          title: 'Change Cover Image',
          subtitle: 'Pick a new thumbnail',
          iconColor: const Color(0xFF3B82F6),
          onTap: onChangeCover,
          isDark: isDark,
        ),
        _buildOption(
          context,
          icon: Icons.lock_outline,
          title: 'Edit Privacy',
          subtitle: 'Public, Followers, or Private',
          iconColor: const Color(0xFF10B981),
          onTap: onEditPrivacy,
          isDark: isDark,
        ),
        _buildOption(
          context,
          icon: Icons.category_outlined,
          title: 'Change Category',
          subtitle: 'Tag to a different topic',
          iconColor: const Color(0xFFF59E0B),
          onTap: onChangeCategory,
          isDark: isDark,
        ),
        _buildOption(
          context,
          icon: Icons.people_outline,
          title: 'Tag People',
          subtitle: 'Add or remove tags',
          iconColor: const Color(0xFF8B5CF6),
          onTap: onTagPeople,
          isDark: isDark,
        ),
        _buildDivider(isDark),
        _buildOption(
          context,
          icon: Icons.bar_chart_outlined,
          title: 'View Insights',
          subtitle: 'See analytics and performance',
          iconColor: const Color(0xFF06B6D4),
          onTap: onViewInsights,
          isDark: isDark,
        ),
        _buildOption(
          context,
          icon: Icons.chat_bubble_outline,
          title: 'Toggle Comments',
          subtitle: 'Enable or disable comments',
          iconColor: const Color(0xFF14B8A6),
          onTap: onToggleComments,
          isDark: isDark,
        ),
        _buildOption(
          context,
          icon: Icons.favorite_border,
          title: 'Toggle Likes',
          subtitle: 'Show or hide like count',
          iconColor: const Color(0xFFEF4444),
          onTap: onToggleLikes,
          isDark: isDark,
        ),
        _buildDivider(isDark),
        _buildOption(
          context,
          icon: Icons.visibility_off_outlined,
          title: 'Hide from Explore',
          subtitle: 'Remove from recommendations',
          iconColor: Colors.grey,
          onTap: onHideFromExplore,
          isDark: isDark,
        ),
        _buildOption(
          context,
          icon: Icons.archive_outlined,
          title: 'Archive Reel',
          subtitle: 'Hide from public view',
          iconColor: const Color(0xFF6366F1),
          onTap: onArchive,
          isDark: isDark,
        ),
        _buildOption(
          context,
          icon: Icons.share_outlined,
          title: 'Share Reel',
          subtitle: 'Send to friends or other apps',
          iconColor: const Color(0xFF0EA5E9),
          onTap: onShare,
          isDark: isDark,
        ),
        _buildDivider(isDark),
        _buildOption(
          context,
          icon: Icons.delete_outline,
          title: 'Delete Reel',
          subtitle: 'Permanently remove this reel',
          iconColor: const Color(0xFFDC2626),
          onTap: onDelete,
          isDark: isDark,
          isDestructive: true,
        ),
      ],
    );
  }

  /// Viewer (Other User's Reel) Options
  Widget _buildViewerOptions(BuildContext context, bool isDark) {
    return Column(
      children: [
        _buildOption(
          context,
          icon: reel.isSaved ? Icons.bookmark : Icons.bookmark_border,
          title: reel.isSaved ? 'Remove from Saved' : 'Save Reel',
          subtitle: reel.isSaved
              ? 'Remove from your collection'
              : 'Add to your favorites',
          iconColor: const Color(0xFFF59E0B),
          onTap: onSave,
          isDark: isDark,
        ),
        _buildOption(
          context,
          icon: Icons.share_outlined,
          title: 'Share Reel',
          subtitle: 'Send to friends or other apps',
          iconColor: const Color(0xFF0EA5E9),
          onTap: onShare,
          isDark: isDark,
        ),
        _buildOption(
          context,
          icon: Icons.link,
          title: 'Copy Link',
          subtitle: 'Copy URL to clipboard',
          iconColor: const Color(0xFF8B5CF6),
          onTap: onCopyLink,
          isDark: isDark,
        ),
        _buildDivider(isDark),
        _buildOption(
          context,
          icon: Icons.thumb_up_outlined,
          title: 'Interested',
          subtitle: 'See more like this',
          iconColor: const Color(0xFF10B981),
          onTap: onInterested,
          isDark: isDark,
        ),
        _buildOption(
          context,
          icon: Icons.thumb_down_outlined,
          title: 'Not Interested',
          subtitle: 'Show less content like this',
          iconColor: const Color(0xFFEF4444),
          onTap: onNotInterested,
          isDark: isDark,
        ),
        _buildOption(
          context,
          icon: Icons.help_outline,
          title: 'Why am I seeing this?',
          subtitle: 'Learn about recommendations',
          iconColor: const Color(0xFF6B7280),
          onTap: onWhyAmISeeingThis,
          isDark: isDark,
        ),
        _buildDivider(isDark),
        _buildOption(
          context,
          icon: Icons.report_outlined,
          title: 'Report',
          subtitle: 'Report inappropriate content',
          iconColor: const Color(0xFFDC2626),
          onTap: onReport,
          isDark: isDark,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    VoidCallback? onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
          onTap?.call();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Icon with glow effect
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      iconColor.withOpacity(0.15),
                      iconColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDestructive
                            ? const Color(0xFFDC2626)
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white.withOpacity(0.5)
                            : Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? Colors.white.withOpacity(0.3)
                    : Colors.black.withOpacity(0.3),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
              : [
                  Colors.black.withOpacity(0.05),
                  Colors.black.withOpacity(0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
