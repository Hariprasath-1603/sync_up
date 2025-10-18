import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

/// Scrolling music bar for reels
class MusicBar extends StatefulWidget {
  const MusicBar({super.key, required this.musicName, this.artist});

  final String musicName;
  final String? artist;

  @override
  State<MusicBar> createState() => _MusicBarState();
}

class _MusicBarState extends State<MusicBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.artist != null
        ? '${widget.musicName} • ${widget.artist}'
        : widget.musicName;

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to sound/music page or open create reel with this sound
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Use this sound coming soon!')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.music_note,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: SizedBox(
                height: 20,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment(_controller.value * 2 - 1, 0),
                          end: Alignment(_controller.value * 2, 0),
                          colors: const [
                            Colors.transparent,
                            Colors.white,
                            Colors.white,
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.1, 0.9, 1.0],
                        ).createShader(bounds);
                      },
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
