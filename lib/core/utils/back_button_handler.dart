import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Handles back button behavior with double-tap to exit and smart navigation
class BackButtonHandler {
  static DateTime? _lastBackPress;
  static const Duration _exitTimeGap = Duration(seconds: 2);

  /// Main screens that require double-tap to exit
  static const List<String> _mainScreens = [
    '/home',
    '/search',
    '/reels',
    '/profile',
  ];

  /// Handles back button press with smart navigation
  /// Returns true if the back press was handled, false otherwise
  static Future<bool> handleBackPress(BuildContext context) async {
    final currentLocation = GoRouterState.of(context).uri.path;

    // Check if we're on a main screen
    if (_mainScreens.contains(currentLocation)) {
      return await _handleMainScreenBack(context, currentLocation);
    } else {
      // Secondary screen - just go back normally
      if (context.canPop()) {
        context.pop();
        return true;
      } else {
        // If can't pop, go to home
        context.go('/home');
        return true;
      }
    }
  }

  /// Handles back press on main screens (Profile, Search, Reels, Home)
  static Future<bool> _handleMainScreenBack(
    BuildContext context,
    String currentLocation,
  ) async {
    // If not on home, go to home first
    if (currentLocation != '/home') {
      context.go('/home');
      _showNavigationSnackBar(context, 'Press back again to exit');
      return true;
    }

    // On home screen - check for double tap
    final now = DateTime.now();

    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > _exitTimeGap) {
      // First tap - show message
      _lastBackPress = now;
      _showExitSnackBar(context);
      return true;
    } else {
      // Second tap within time gap - exit app
      SystemNavigator.pop();
      return false;
    }
  }

  /// Shows snackbar for exit confirmation
  static void _showExitSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 12),
            Text('Press back again to exit', style: TextStyle(fontSize: 14)),
          ],
        ),
        duration: _exitTimeGap,
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Shows snackbar for navigation to home
  static void _showNavigationSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.home_outlined, color: Colors.white),
            const SizedBox(width: 12),
            Text(message, style: const TextStyle(fontSize: 14)),
          ],
        ),
        duration: const Duration(seconds: 1, milliseconds: 500),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Resets the back press timer (useful when navigating)
  static void reset() {
    _lastBackPress = null;
  }

  /// Check if user is on a main screen
  static bool isMainScreen(String location) {
    return _mainScreens.contains(location);
  }

  /// Get the appropriate route to navigate to when back is pressed
  static String? getBackRoute(String currentLocation) {
    if (currentLocation != '/home' && _mainScreens.contains(currentLocation)) {
      return '/home';
    }
    return null;
  }
}

/// Widget wrapper that handles back button automatically
class BackButtonWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onBackPressed;

  const BackButtonWrapper({super.key, required this.child, this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (onBackPressed != null) {
          onBackPressed!();
        } else {
          await BackButtonHandler.handleBackPress(context);
        }
      },
      child: child,
    );
  }
}
