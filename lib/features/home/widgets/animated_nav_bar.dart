import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../add/add_page.dart';

class AnimatedNavBar extends StatefulWidget {
  const AnimatedNavBar({super.key});

  @override
  State<AnimatedNavBar> createState() => _AnimatedNavBarState();
}

class _AnimatedNavBarState extends State<AnimatedNavBar> {
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
        final double screenWidth = MediaQuery.of(context).size.width;

        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 65,
            width: screenWidth * 0.9,
            margin: const EdgeInsets.only(bottom: 25),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              Colors.white.withOpacity(0.15),
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.05),
                            ]
                          : [
                              Colors.white.withOpacity(0.95),
                              Colors.white.withOpacity(0.85),
                              Colors.white.withOpacity(0.75),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.25)
                          : Colors.white.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                        spreadRadius: -5,
                      ),
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.4)
                            : Colors.grey.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated selection indicator
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        left: (screenWidth * 0.9 / _items.length) * selectedIndex + 
                              (screenWidth * 0.9 / _items.length - 54) / 2,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutBack,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 0.8 + (value * 0.2),
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      kPrimary,
                                      kPrimary.withOpacity(0.8),
                                      kPrimary.withOpacity(0.6),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: kPrimary.withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: kPrimary.withOpacity(0.3),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Navigation items
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _items.asMap().entries.map((entry) {
                          final int index = entry.key;
                          final NavBarItem item = entry.value;
                          final bool isSelected = selectedIndex == index;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // Special handling for Add button (index 2)
                                if (index == 2) {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      opaque: false,
                                      pageBuilder: (context, animation, secondaryAnimation) => const AddPage(),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                } else {
                                  context.go(item.path);
                                }
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Center(
                                child: AnimatedScale(
                                  scale: isSelected ? 1.0 : 0.85,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutBack,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    transitionBuilder: (child, animation) {
                                      return ScaleTransition(
                                        scale: animation,
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      isSelected ? item.filledIcon : item.outlinedIcon,
                                      key: ValueKey<bool>(isSelected),
                                      size: 28,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? Colors.white60 : Colors.black.withOpacity(0.6)),
                                      shadows: isSelected
                                          ? [
                                              Shadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 8,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// NavBar item class
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