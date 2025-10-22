import 'dart:math';
import 'package:flutter/material.dart';

/// Floating hearts that rise from a specific position (for post images)
class FloatingHeartsFromPosition extends StatefulWidget {
  final Offset? spawnPosition; // Position where hearts should spawn from

  const FloatingHeartsFromPosition({super.key, this.spawnPosition});

  @override
  State<FloatingHeartsFromPosition> createState() =>
      FloatingHeartsFromPositionState();
}

class FloatingHeartsFromPositionState extends State<FloatingHeartsFromPosition>
    with TickerProviderStateMixin {
  final List<_HeartItem> _hearts = [];
  final Random _random = Random();

  void addHeartsFromPosition(Offset position) {
    // Create multiple hearts (5-8 hearts) with different sizes
    final heartCount = 5 + _random.nextInt(4); // 5 to 8 hearts

    for (int i = 0; i < heartCount; i++) {
      // Very slight delay between hearts for staggered effect (reduced from 40ms to 15ms)
      Future.delayed(Duration(milliseconds: i * 15), () {
        if (!mounted) return;

        final controller = AnimationController(
          vsync: this,
          duration: Duration(
            milliseconds: 1500 + _random.nextInt(500),
          ), // 1500-2000ms
        );

        final heart = _HeartItem(
          controller: controller,
          startPosition: position,
          offsetX:
              (_random.nextDouble() - 0.5) *
              100, // -50 to 50 px horizontal spread
          offsetY: -200 - _random.nextDouble() * 150, // Rise 200-350px up
          size: 28.0 + _random.nextDouble() * 20, // 28 to 48 size
          rotation: (_random.nextDouble() - 0.5) * 0.4, // -0.2 to 0.2 radians
        );

        setState(() => _hearts.add(heart));

        controller.forward().then((_) {
          controller.dispose();
          if (mounted) {
            setState(() => _hearts.remove(heart));
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: _hearts.map((heart) {
          return AnimatedBuilder(
            animation: heart.controller,
            builder: (context, child) {
              final progress = heart.controller.value;

              // Smooth ease-out curve for upward movement
              final verticalProgress = Curves.easeOut.transform(progress);

              // Horizontal drift with sine wave for natural movement
              final horizontalDrift = sin(progress * pi * 2) * 15;

              // Calculate position (start from tap position)
              final x =
                  heart.startPosition.dx +
                  (heart.offsetX * progress) +
                  horizontalDrift;
              final y =
                  heart.startPosition.dy + (heart.offsetY * verticalProgress);

              // Fade out as it rises (start fading at 60% of animation)
              final opacity = progress < 0.6
                  ? 1.0
                  : (1.0 - (progress - 0.6) / 0.4);

              // Scale animation (grow slightly then shrink)
              final scale = progress < 0.15
                  ? 0.5 +
                        (progress * 3.33) // Grow from 0.5 to 1.0 quickly
                  : 1.0 - (progress * 0.3); // Shrink from 1.0 to 0.7

              return Positioned(
                left: x - (heart.size / 2),
                top: y - (heart.size / 2),
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: heart.rotation * progress,
                    child: Transform.scale(
                      scale: scale,
                      child: Icon(
                        Icons.favorite,
                        color: Colors.red.shade400,
                        size: heart.size,
                        shadows: const [
                          Shadow(color: Colors.black38, blurRadius: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    for (final heart in _hearts) {
      heart.controller.dispose();
    }
    super.dispose();
  }
}

class _HeartItem {
  _HeartItem({
    required this.controller,
    required this.startPosition,
    required this.offsetX,
    required this.offsetY,
    required this.size,
    required this.rotation,
  });

  final AnimationController controller;
  final Offset startPosition; // Where the heart starts (tap position)
  final double offsetX; // Horizontal offset from start
  final double offsetY; // Vertical offset (negative = upward)
  final double size; // Heart size
  final double rotation; // Rotation amount
}
