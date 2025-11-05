import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeftSidebarControls extends StatelessWidget {
  final VoidCallback onAudioTap;
  final VoidCallback onEffectsTap;
  final VoidCallback onLengthTap;
  final VoidCallback onGreenScreenTap;
  final VoidCallback onTouchUpTap;
  final String selectedLength;

  const LeftSidebarControls({
    super.key,
    required this.onAudioTap,
    required this.onEffectsTap,
    required this.onLengthTap,
    required this.onGreenScreenTap,
    required this.onTouchUpTap,
    required this.selectedLength,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0, top: 100, bottom: 120),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ControlItem(
              icon: Icons.music_note_rounded,
              label: 'Audio',
              isDark: isDark,
              onTap: onAudioTap,
            ),
            _ControlItem(
              icon: Icons.auto_awesome_rounded,
              label: 'Effects',
              isDark: isDark,
              onTap: onEffectsTap,
            ),
            _ControlItem(
              icon: Icons.timer_outlined,
              label: selectedLength,
              isDark: isDark,
              onTap: onLengthTap,
            ),
            _ControlItem(
              icon: Icons.grid_on_rounded,
              label: 'Green\nScreen',
              isDark: isDark,
              onTap: onGreenScreenTap,
            ),
            _ControlItem(
              icon: Icons.face_retouching_natural_rounded,
              label: 'Touch Up',
              isDark: isDark,
              showBadge: true,
              onTap: onTouchUpTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool showBadge;
  final VoidCallback onTap;

  const _ControlItem({
    required this.icon,
    required this.label,
    required this.isDark,
    this.showBadge = false,
    required this.onTap,
  });

  @override
  State<_ControlItem> createState() => _ControlItemState();
}

class _ControlItemState extends State<_ControlItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Stagger animation
    Future.delayed(Duration(milliseconds: 100 * widget.hashCode % 5), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(opacity: _fadeAnimation.value, child: child),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 24),
                  ),
                  if (widget.showBadge)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7F00FF), Color(0xFF00D4FF)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'NEW',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.2,
                  shadows: [const Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
