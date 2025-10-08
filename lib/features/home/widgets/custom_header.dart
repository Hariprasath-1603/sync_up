import 'package:flutter/material.dart';

class CustomHeader extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const CustomHeader({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Get the app's theme
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildTab(context, 'Following', 0),
              const SizedBox(width: 24),
              _buildTab(context, 'For You', 1),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              // Use the theme's primary color
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, String text, int index) {
    final bool isActive = selectedIndex == index;
    // Get the app's theme
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              // Use the theme's primary color for the active state
              color: isActive ? theme.colorScheme.primary : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          if (isActive)
            Container(
              height: 3,
              width: 24,
              decoration: BoxDecoration(
                // Use the theme's primary color for the underline
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}