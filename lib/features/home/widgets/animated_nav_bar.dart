import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AnimatedNavBar extends StatefulWidget {
  const AnimatedNavBar({super.key});

  @override
  State<AnimatedNavBar> createState() => _AnimatedNavBarState();
}

class _AnimatedNavBarState extends State<AnimatedNavBar> {
  // The list now includes both outlined and filled icons for animation
  final List<NavBarItem> _items = [
    NavBarItem(outlinedIcon: Icons.home_outlined, filledIcon: Icons.home, path: '/home'),
    NavBarItem(outlinedIcon: Icons.search_outlined, filledIcon: Icons.search, path: '/search'),
    NavBarItem(outlinedIcon: Icons.add_circle_outline, filledIcon: Icons.add_circle, path: '/add'),
    NavBarItem(outlinedIcon: Icons.smart_display_outlined, filledIcon: Icons.smart_display, path: '/reels'),
    NavBarItem(outlinedIcon: Icons.person_outline, filledIcon: Icons.person, path: '/profile'),
  ];

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouter.of(context).routerDelegate.currentConfiguration.fullPath;
    final index = _items.indexWhere((item) => item.path == location);
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GoRouter.of(context).routerDelegate,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final int selectedIndex = _getSelectedIndex(context);

        return Container(
          height: 70,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double iconSlotWidth = constraints.maxWidth / _items.length;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // The animated "bubble" that slides behind the icons
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: selectedIndex * iconSlotWidth,
                    width: iconSlotWidth,
                    child: Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  // The row of icons with animation and alignment fixes
                  Row(
                    children: _items.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final NavBarItem item = entry.value;
                      final bool isSelected = selectedIndex == index;

                      // Use Expanded to ensure each icon has an equal, centered slot
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => context.go(item.path),
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(scale: animation, child: child);
                            },
                            child: Icon(
                              // Use a unique key to trigger the animation
                              key: ValueKey<bool>(isSelected),
                              isSelected ? item.filledIcon : item.outlinedIcon,
                              size: 28,
                              color: isSelected ? Theme.of(context).colorScheme.primary : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// Updated class to hold both icon states
class NavBarItem {
  final IconData outlinedIcon;
  final IconData filledIcon;
  final String path;
  NavBarItem({
    required this.outlinedIcon,
    required this.filledIcon,
    required this.path,
  });
}