import 'package:flutter/material.dart';
import 'package:sync_up/features/home/widgets/animated_nav_bar.dart';

class NavBarVisibilityScope extends InheritedNotifier<ValueNotifier<bool>> {
  const NavBarVisibilityScope({
    super.key,
    required ValueNotifier<bool> notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static ValueNotifier<bool>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<NavBarVisibilityScope>()
        ?.notifier;
  }

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
    return NavBarVisibilityScope(
      notifier: _navIsVisible,
      child: Scaffold(
        body: Stack(
          children: [
            widget.child,
            ValueListenableBuilder<bool>(
              valueListenable: _navIsVisible,
              builder: (context, isVisible, _) {
                return IgnorePointer(
                  ignoring: !isVisible,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    offset: isVisible ? Offset.zero : const Offset(0, 0.1),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeInOut,
                      opacity: isVisible ? 1 : 0,
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
    );
  }
}
