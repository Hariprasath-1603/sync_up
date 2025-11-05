import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SideBarButton: animated circular button with an icon and label
class SideBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const SideBarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF5B3FFF)
                  : Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? const Color(0xFF00E0FF)
                    : Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF5B3FFF).withOpacity(0.6),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              shadows: [
                const Shadow(color: Colors.black, blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
