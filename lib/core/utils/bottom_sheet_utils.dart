import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../scaffold_with_nav_bar.dart';

/// Bottom Sheet Utilities with Smart Navigation Bar Management
/// 
/// Provides an enhanced bottom sheet experience with automatic navbar hiding,
/// optional blur effects, and smooth animations. This utility addresses the
/// common issue of bottom sheets overlapping with bottom navigation bars.
/// 
/// Key Features:
/// 1. **Automatic Navbar Management**: 
///    - Hides navbar when sheet opens
///    - Restores navbar when sheet closes (even on dismissal)
///    - Works with NavBarVisibilityScope from scaffold_with_nav_bar.dart
/// 
/// 2. **Optional Blur Effect**: 
///    - Background blur using BackdropFilter
///    - Creates modern, iOS-style visual effect
///    - Customizable blur intensity
///    - Note: May impact performance on older devices
/// 
/// 3. **Haptic Feedback**: 
///    - Subtle vibration when sheet opens
///    - Improves user experience with tactile response
/// 
/// 4. **Error Handling**: 
///    - Ensures navbar is restored even if bottom sheet throws error
///    - Uses try-finally pattern for cleanup
/// 
/// Usage Example:
/// ```dart
/// // Simple usage
/// await BottomSheetUtils.showAdaptiveBottomSheet(
///   context: context,
///   builder: (context) => MyBottomSheet(),
/// );
/// 
/// // With blur effect and custom styling
/// final result = await BottomSheetUtils.showAdaptiveBottomSheet<String>(
///   context: context,
///   builder: (context) => SelectionSheet(),
///   withBlur: true,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
/// );
/// ```
/// 
/// Performance Considerations:
/// - Blur effects use BackdropFilter which can be GPU-intensive
/// - On low-end devices, consider disabling withBlur parameter
/// - Test on target devices before enabling blur in production
/// 
/// Integration:
/// - Requires NavBarVisibilityScope in widget tree
/// - Works seamlessly with ScaffoldWithNavBar
/// - Compatible with all standard showModalBottomSheet parameters
class BottomSheetUtils {
  /// Shows a modal bottom sheet with automatic navbar hiding/showing
  ///
  /// Automatically hides the navbar when the bottom sheet opens and
  /// shows it again when the bottom sheet closes with smooth animations
  /// and haptic feedback.
  ///
  /// Usage:
  /// ```dart
  /// await BottomSheetUtils.showAdaptiveBottomSheet(
  ///   context: context,
  ///   builder: (context) => YourBottomSheetWidget(),
  /// );
  /// ```
  static Future<T?> showAdaptiveBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = false,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    Color? barrierColor,
    bool useRootNavigator = false,
    RouteSettings? routeSettings,
    AnimationController? transitionAnimationController,
    bool withBlur = false,
  }) async {
    final navVisibility = NavBarVisibilityScope.maybeOf(context);

    // Hide navbar when bottom sheet opens
    navVisibility?.value = false;

    // Add subtle haptic feedback
    HapticFeedback.lightImpact();

    try {
      return await showModalBottomSheet<T>(
        context: context,
        builder: (context) {
          if (withBlur) {
            return _BlurredBottomSheet(child: builder(context));
          }
          return builder(context);
        },
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        isScrollControlled: isScrollControlled,
        backgroundColor: backgroundColor ?? Colors.transparent,
        elevation: elevation,
        shape: shape,
        clipBehavior: clipBehavior,
        constraints: constraints,
        barrierColor: barrierColor,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
        transitionAnimationController: transitionAnimationController,
      );
    } finally {
      // Show navbar when bottom sheet closes with haptic feedback
      await Future.delayed(const Duration(milliseconds: 100));
      navVisibility?.value = true;
      HapticFeedback.selectionClick();
    }
  }

  /// Shows a custom modal with automatic navbar hiding
  ///
  /// Useful for custom modals that need more control than bottom sheets.
  /// Automatically handles navbar visibility and adds premium animations.
  static Future<T?> showCustomModal<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    bool withFadeTransition = true,
    bool withScaleTransition = false,
    bool withBlur = true,
  }) async {
    final navVisibility = NavBarVisibilityScope.maybeOf(context);

    // Hide navbar when modal opens
    navVisibility?.value = false;

    // Add haptic feedback
    HapticFeedback.mediumImpact();

    try {
      return await showGeneralDialog<T>(
        context: context,
        pageBuilder: (context, animation, secondaryAnimation) {
          Widget content = builder(context);

          if (withBlur) {
            content = BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: content,
            );
          }

          return content;
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          Widget result = child;

          if (withFadeTransition) {
            result = FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: result,
            );
          }

          if (withScaleTransition) {
            result = ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: result,
            );
          }

          return result;
        },
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor ?? Colors.black.withOpacity(0.5),
        barrierLabel:
            barrierLabel ??
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
        transitionDuration: const Duration(milliseconds: 300),
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
      );
    } finally {
      // Show navbar when modal closes
      await Future.delayed(const Duration(milliseconds: 100));
      navVisibility?.value = true;
      HapticFeedback.selectionClick();
    }
  }

  /// Creates a premium styled bottom sheet with blur effect
  ///
  /// Returns a widget that can be used as the child of showModalBottomSheet.
  /// Includes glassmorphic design with backdrop blur.
  static Widget createPremiumBottomSheet({
    required BuildContext context,
    required Widget child,
    double? height,
    EdgeInsets? padding,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.grey[900]!.withOpacity(0.95),
                  Colors.grey[850]!.withOpacity(0.9),
                ]
              : [
                  Colors.white.withOpacity(0.95),
                  Colors.grey[50]!.withOpacity(0.9),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Internal widget for creating blurred bottom sheets
class _BlurredBottomSheet extends StatelessWidget {
  final Widget child;

  const _BlurredBottomSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: child,
      ),
    );
  }
}

/// Extension on BuildContext for easy access to navbar visibility
extension NavBarVisibilityExtension on BuildContext {
  /// Hide the bottom navigation bar
  void hideNavBar() {
    NavBarVisibilityScope.maybeOf(this)?.value = false;
  }

  /// Show the bottom navigation bar
  void showNavBar() {
    NavBarVisibilityScope.maybeOf(this)?.value = true;
    HapticFeedback.selectionClick();
  }

  /// Toggle the bottom navigation bar visibility
  void toggleNavBar() {
    final visibility = NavBarVisibilityScope.maybeOf(this);
    if (visibility != null) {
      visibility.value = !visibility.value;
      if (visibility.value) {
        HapticFeedback.selectionClick();
      }
    }
  }

  /// Get current navbar visibility state
  bool get isNavBarVisible {
    return NavBarVisibilityScope.maybeOf(this)?.value ?? true;
  }
}
