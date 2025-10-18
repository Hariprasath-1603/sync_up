import 'dart:math';
import 'package:flutter/material.dart';

/// Floating reactions that drift upward (hearts, emojis)
class FloatingReactions extends StatefulWidget {
  const FloatingReactions({super.key});

  @override
  State<FloatingReactions> createState() => FloatingReactionsState();
}

class FloatingReactionsState extends State<FloatingReactions>
    with TickerProviderStateMixin {
  final List<_ReactionItem> _reactions = [];

  void addReaction(String emoji) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    final reaction = _ReactionItem(
      emoji: emoji,
      controller: controller,
      startX: Random().nextDouble() * 0.8 + 0.1, // 0.1 to 0.9
      endX: Random().nextDouble() * 0.4 + 0.3, // 0.3 to 0.7
    );

    setState(() => _reactions.add(reaction));

    controller.forward().then((_) {
      controller.dispose();
      setState(() => _reactions.remove(reaction));
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: _reactions.map((reaction) {
        return AnimatedBuilder(
          animation: reaction.controller,
          builder: (context, child) {
            final progress = reaction.controller.value;
            final curve = Curves.easeOut.transform(progress);

            final x =
                size.width *
                (reaction.startX +
                    (reaction.endX - reaction.startX) * sin(progress * pi));
            final y = size.height * (1 - curve);

            return Positioned(
              left: x,
              top: y,
              child: Opacity(
                opacity: 1 - progress,
                child: Transform.scale(
                  scale: 0.8 + (progress * 0.4),
                  child: Text(
                    reaction.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    for (final reaction in _reactions) {
      reaction.controller.dispose();
    }
    super.dispose();
  }
}

class _ReactionItem {
  _ReactionItem({
    required this.emoji,
    required this.controller,
    required this.startX,
    required this.endX,
  });

  final String emoji;
  final AnimationController controller;
  final double startX;
  final double endX;
}
