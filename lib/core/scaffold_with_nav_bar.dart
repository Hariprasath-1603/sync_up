/// Bottom Navigation Bar Architecture
/// 
/// This file implements a custom bottom navigation system with:
/// - Persistent navigation bar across tab switches
/// - Dynamic show/hide capability for immersive experiences
/// - Integrated with GoRouter for deep linking support
/// - Back button handling for nested navigation
/// 
/// Architecture Components:
/// 1. [NavBarVisibilityScope] - InheritedWidget for nav bar visibility state
/// 2. [ScaffoldWithNavBar] - Main scaffold container with bottom nav
/// 3. [BackButtonWrapper] - Handles Android back button behavior
/// 
/// Usage:
/// To hide/show nav bar from any child widget:
/// ```dart
/// final navBarVisible = NavBarVisibilityScope.of(context);
/// navBarVisible.value = false; // Hide nav bar
/// ```
import 'package:flutter/material.dart';
import 'package:sync_up/features/home/widgets/animated_nav_bar.dart';
import 'utils/back_button_handler.dart';

/// InheritedNotifier for managing bottom navigation bar visibility
/// 
/// Uses ValueNotifier to efficiently notify all listening widgets
/// when the navigation bar should be shown or hidden.
/// 
/// This pattern allows any widget in the tree to control nav bar
/// visibility without tight coupling or prop drilling.
class NavBarVisibilityScope extends InheritedNotifier<ValueNotifier<bool>> {
  const NavBarVisibilityScope({
    super.key,
    required ValueNotifier<bool> super.notifier,
    required super.child,
  });

  /// Safely access nav bar visibility notifier (returns null if not found)
  /// 
  /// Use this when the widget might not be wrapped in NavBarVisibilityScope,
  /// such as in dialogs or standalone pages.
  static ValueNotifier<bool>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<NavBarVisibilityScope>()
        ?.notifier;
  }

  /// Access nav bar visibility notifier (throws if not found)
  /// 
  /// Use this when you're certain the widget is wrapped in NavBarVisibilityScope.
  /// Throws a StateError if the scope is not found in the widget tree.
  /// 
  /// Example:
  /// ```dart
  /// // In any widget within ScaffoldWithNavBar
  /// final navBarNotifier = NavBarVisibilityScope.of(context);
  /// navBarNotifier.value = false; // Hide navigation bar
  /// ```
  static ValueNotifier<bool> of(BuildContext context) {
    final notifier = maybeOf(context);
    if (notifier == null) {
      throw StateError(
        'NavBarVisibilityScope.of() called with a context that does not contain NavBarVisibilityScope.',
      );
    }
    return notifier;
  }
}

class ScaffoldWithNavBar extends StatefulWidget {
  const ScaffoldWithNavBar({required this.child, super.key});

  final Widget child;

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  late final ValueNotifier<bool> _navIsVisible;

  @override
  void initState() {
    super.initState();
    _navIsVisible = ValueNotifier<bool>(true);
  }

  @override
  void dispose() {
    _navIsVisible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonWrapper(
      child: NavBarVisibilityScope(
        notifier: _navIsVisible,
        child: Scaffold(
          body: Stack(
            children: [
              widget.child,
              ValueListenableBuilder<bool>(
                valueListenable: _navIsVisible,
                builder: (context, isVisible, _) {
                  return AnimatedSlide(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    offset: isVisible ? Offset.zero : const Offset(0, 0.1),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      opacity: isVisible ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !isVisible,
                        child: const Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedNavBar(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
