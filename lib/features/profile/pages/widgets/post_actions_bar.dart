import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../models/post_model.dart';

/// Vertical action buttons bar (like, comment, share, save)
class PostActionsBar extends StatelessWidget {
  const PostActionsBar({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onSave,
    required this.likeAnimation,
    required this.saveAnimation,
  });

  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final AnimationController likeAnimation;
  final AnimationController saveAnimation;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
          color: post.isLiked ? Colors.red : Colors.white,
          label: _formatNumber(post.likes),
          onTap: onLike,
          animation: likeAnimation,
        ),
        const SizedBox(height: 20),
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          color: Colors.white,
          label: _formatNumber(post.comments),
          onTap: onComment,
        ),
        const SizedBox(height: 20),
        _ActionButton(
          icon: Icons.share_outlined,
          color: Colors.white,
          label: _formatNumber(post.shares),
          onTap: onShare,
        ),
        const SizedBox(height: 20),
        _ActionButton(
          icon: post.isSaved ? Icons.bookmark : Icons.bookmark_border,
          color: post.isSaved ? kPrimary : Colors.white,
          onTap: onSave,
          animation: saveAnimation,
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    this.label,
    required this.onTap,
    this.animation,
  });

  final IconData icon;
  final Color color;
  final String? label;
  final VoidCallback onTap;
  final AnimationController? animation;

  @override
  Widget build(BuildContext context) {
    Widget button = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );

    if (animation != null) {
      button = ScaleTransition(
        scale: Tween<double>(
          begin: 1.0,
          end: 1.2,
        ).animate(CurvedAnimation(parent: animation!, curve: Curves.easeOut)),
        child: button,
      );
    }

    return GestureDetector(onTap: onTap, child: button);
  }
}
