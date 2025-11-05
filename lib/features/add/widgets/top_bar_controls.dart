import 'package:flutter/material.dart';

class TopBarControls extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onFlashToggle;
  final VoidCallback onSpeedToggle;
  final VoidCallback onTimerToggle;
  final VoidCallback onSettings;
  final bool isFlashOn;
  final String speed;

  const TopBarControls({
    super.key,
    required this.onClose,
    required this.onFlashToggle,
    required this.onSpeedToggle,
    required this.onTimerToggle,
    required this.onSettings,
    required this.isFlashOn,
    required this.speed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Close button
            _IconButton(icon: Icons.close_rounded, onTap: onClose),

            // Right side controls
            Row(
              children: [
                _IconButton(
                  icon: isFlashOn
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  onTap: onFlashToggle,
                  isActive: isFlashOn,
                ),
                const SizedBox(width: 12),
                _TextIconButton(text: speed, onTap: onSpeedToggle),
                const SizedBox(width: 12),
                _IconButton(icon: Icons.timer_outlined, onTap: onTimerToggle),
                const SizedBox(width: 12),
                _IconButton(icon: Icons.settings_outlined, onTap: onSettings),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _IconButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF7F00FF).withOpacity(0.3)
              : Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? const Color(0xFF7F00FF)
                : Colors.white.withOpacity(0.2),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _TextIconButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _TextIconButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
