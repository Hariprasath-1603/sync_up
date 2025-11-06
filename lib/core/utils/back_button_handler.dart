import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vibration/vibration.dart';
import '../services/back_navigation_settings_service.dart';

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
  /// Returns true if the app should exit, false otherwise
  static Future<bool> handleBackPress(BuildContext context) async {
    final settings = BackNavigationSettingsService.instance;
    final currentLocation = GoRouterState.of(context).uri.path;

    // Check if we're on a main screen
    if (_mainScreens.contains(currentLocation)) {
      return await _handleMainScreenBack(context, currentLocation, settings);
    } else {
      // Secondary screen - just go back normally
      if (context.canPop()) {
        context.pop();
        return false;
      } else {
        // If can't pop, go to home
        context.go('/home');
        return false;
      }
    }
  }

  /// Handles back press on main screens (Profile, Search, Reels, Home)
  static Future<bool> _handleMainScreenBack(
    BuildContext context,
    String currentLocation,
    BackNavigationSettingsService settings,
  ) async {
    // If auto-return to home is enabled and not on home, go to home first
    if (settings.autoReturnHomeEnabled && currentLocation != '/home') {
      context.go('/home');

      // Vibrate if enabled
      if (settings.vibrateOnBackEnabled) {
        await _performVibration();
      }

      // Show toast if enabled
      if (settings.showToastEnabled) {
        _showToast('Returning to Home');
      }

      return false;
    }

    // On home screen - check for double tap if enabled
    if (settings.doubleTapExitEnabled) {
      final now = DateTime.now();

      if (_lastBackPress == null ||
          now.difference(_lastBackPress!) > _exitTimeGap) {
        // First tap - show message
        _lastBackPress = now;

        // Vibrate if enabled
        if (settings.vibrateOnBackEnabled) {
          await _performVibration();
        }

        // Show toast if enabled
        if (settings.showToastEnabled) {
          _showExitToast();
        }

        return false;
      } else {
        // Second tap within time gap - exit app
        SystemNavigator.pop();
        return true;
      }
    } else {
      // Double-tap disabled, exit immediately
      SystemNavigator.pop();
      return true;
    }
  }

  /// Performs haptic vibration feedback
  static Future<void> _performVibration() async {
    try {
      // Check if device has vibration capability
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        // Light haptic feedback (40ms)
        await Vibration.vibrate(duration: 40);
      } else {
        // Fallback to system haptic feedback
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      // Fallback to system haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  /// Shows toast for exit confirmation
  static void _showExitToast() {
    Fluttertoast.showToast(
      msg: "Press again to exit",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  /// Shows toast with custom message
  static void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 14.0,
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
