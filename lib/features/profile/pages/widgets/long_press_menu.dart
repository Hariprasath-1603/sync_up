import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme.dart';
import '../../models/post_model.dart';

/// Glassmorphism long-press popup menu with quick actions
class LongPressPostMenu extends StatelessWidget {
  const LongPressPostMenu({
    super.key,
    required this.post,
    required this.onDismiss,
    required this.onPreview,
    required this.onEdit,
    required this.onDelete,
    required this.onSave,
    required this.onShare,
    required this.onInsights,
  });

  final PostModel post;
  final VoidCallback onDismiss;
  final VoidCallback onPreview;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onInsights;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: _buildMenuCard(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withOpacity(0.15),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Preview thumbnail
              _buildThumbnail(),
              // Actions grid
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MenuButton(
                            icon: Icons.visibility_outlined,
                            label: 'Preview',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onDismiss();
                              onPreview();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _MenuButton(
                            icon: Icons.edit_outlined,
                            label: 'Edit',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onDismiss();
                              onEdit();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MenuButton(
                            icon: post.isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            label: post.isSaved ? 'Saved' : 'Save',
                            color: post.isSaved ? kPrimary : null,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onDismiss();
                              onSave();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _MenuButton(
                            icon: Icons.share_outlined,
                            label: 'Share',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onDismiss();
                              onShare();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MenuButton(
                            icon: Icons.bar_chart_rounded,
                            label: 'Insights',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onDismiss();
                              onInsights();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _MenuButton(
                            icon: Icons.delete_outline,
                            label: 'Delete',
                            color: Colors.red,
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              onDismiss();
                              onDelete();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return Stack(
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            image: DecorationImage(
              image: NetworkImage(post.thumbnailUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Gradient overlay
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
            ),
          ),
        ),
        // Type indicator
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  post.isVideo
                      ? Icons.play_circle_outline
                      : post.isCarousel
                      ? Icons.collections_outlined
                      : Icons.image_outlined,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  post.isVideo
                      ? 'Video'
                      : post.isCarousel
                      ? '${post.mediaUrls.length}'
                      : 'Photo',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (color ?? defaultColor).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? defaultColor, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color ?? defaultColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
