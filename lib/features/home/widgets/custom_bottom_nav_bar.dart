import 'dart:ui'; // For blur effect
import 'package:flutter/material.dart';

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the theme's primary color
    final theme = Theme.of(context);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 30, // Move navbar slightly up
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32.5),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 65,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.35),
                borderRadius: BorderRadius.circular(32.5),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    offset: Offset(0, 4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    // Changed to theme color
                    icon: Icon(Icons.home, color: theme.colorScheme.primary),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.blur_circular_outlined, color: Colors.grey),
                    onPressed: () {},
                  ),

                  // Plus Button inside the nav bar
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      // Changed to theme color
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          // Changed to theme color
                          color: theme.colorScheme.primary.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white, size: 28),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_outline, color: Colors.grey),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}