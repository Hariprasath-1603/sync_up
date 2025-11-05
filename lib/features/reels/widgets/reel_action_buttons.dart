import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/reel_model.dart';

/// Action buttons column for reels (like, comment, share)
class ReelActionButtons extends StatelessWidget {
  final ReelModel reel;
  final bool isLiked;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;
  final VoidCallback onProfileTap;

  const ReelActionButtons({
    super.key,
    required this.reel,
    required this.isLiked,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onShareTap,
    required this.onProfileTap,
  });

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Profile Avatar
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipOval(
                child: reel.userPhotoUrl != null
                    ? Image.network(
                        reel.userPhotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Like Button
          _ActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            iconColor: isLiked ? Colors.red : Colors.white,
            count: _formatCount(reel.likesCount),
            onTap: onLikeTap,
            animate: isLiked,
          ),

          const SizedBox(height: 24),

          // Comment Button
          _ActionButton(
            icon: Icons.comment_outlined,
            iconColor: Colors.white,
            count: _formatCount(reel.commentsCount),
            onTap: onCommentTap,
          ),

          const SizedBox(height: 24),

          // Share Button
          _ActionButton(
            icon: Icons.send_outlined,
            iconColor: Colors.white,
            count: _formatCount(reel.sharesCount),
            onTap: onShareTap,
          ),

          const SizedBox(height: 24),

          // More Options
          _ActionButton(
            icon: Icons.more_vert,
            iconColor: Colors.white,
            count: null,
            onTap: () {
              // TODO: Show options bottom sheet
            },
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String? count;
  final VoidCallback onTap;
  final bool animate;

  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.onTap,
    this.animate = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) {
        setState(() => _isTapped = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isTapped = false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: _isTapped ? 0.85 : 1.0,
            duration: const Duration(milliseconds: 100),
            child:
                Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.iconColor,
                        size: 28,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    )
                    .animate(target: widget.animate ? 1 : 0)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.2, 1.2),
                      duration: 200.ms,
                      curve: Curves.easeOut,
                    )
                    .then()
                    .scale(
                      begin: const Offset(1.2, 1.2),
                      end: const Offset(1, 1),
                      duration: 200.ms,
                      curve: Curves.easeIn,
                    ),
          ),
          if (widget.count != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.count!,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.7), blurRadius: 4),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
