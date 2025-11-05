import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomModeSelector extends StatelessWidget {
  final String selectedMode; // 'POST', 'STORY', 'REEL'
  final ValueChanged<String> onModeChanged;
  final VoidCallback onFlipCamera;

  const BottomModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
    required this.onFlipCamera,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 160.0, left: 20, right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Mode selector
            Row(
              children: [
                _ModeButton(
                  label: 'POST',
                  isSelected: selectedMode == 'POST',
                  onTap: () => onModeChanged('POST'),
                ),
                const SizedBox(width: 20),
                _ModeButton(
                  label: 'STORY',
                  isSelected: selectedMode == 'STORY',
                  onTap: () => onModeChanged('STORY'),
                ),
                const SizedBox(width: 20),
                _ModeButton(
                  label: 'REEL',
                  isSelected: selectedMode == 'REEL',
                  onTap: () => onModeChanged('REEL'),
                ),
              ],
            ),

            // Flip camera button
            GestureDetector(
              onTap: onFlipCamera,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.flip_camera_ios_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ModeButton> createState() => _ModeButtonState();
}

class _ModeButtonState extends State<_ModeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(_ModeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) {
                  if (widget.isSelected) {
                    return const LinearGradient(
                      colors: [Color(0xFF7F00FF), Color(0xFF00D4FF)],
                    ).createShader(bounds);
                  }
                  return const LinearGradient(
                    colors: [Colors.white70, Colors.white70],
                  ).createShader(bounds);
                },
                child: Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    fontSize: widget.isSelected ? 16 : 14,
                    fontWeight: widget.isSelected
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: Colors.white,
                    shadows: [
                      const Shadow(color: Colors.black54, blurRadius: 4),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                height: 3,
                width: widget.isSelected ? 24 : 0,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7F00FF), Color(0xFF00D4FF)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
