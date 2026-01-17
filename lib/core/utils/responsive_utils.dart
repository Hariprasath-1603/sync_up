import 'package:flutter/material.dart';

/// Responsive Design Utilities for Cross-Device Compatibility
/// 
/// Provides a comprehensive set of methods for building responsive UIs that
/// adapt seamlessly across different screen sizes and device types.
/// 
/// Design Philosophy:
/// - Uses a reference design size (375x812 - iPhone X dimensions)
/// - Scales all dimensions proportionally based on actual screen size
/// - Implements smart clamping for font sizes to maintain readability
/// - Separates concerns: width, height, fonts, spacing, and radius
/// 
/// Key Features:
/// 1. **Proportional Scaling**: All dimensions scale relative to design mockups
/// 2. **Font Size Clamping**: Prevents text from becoming too small or large (0.85x - 1.3x)
/// 3. **Device Detection**: Tablet and orientation detection utilities
/// 4. **Type Safety**: Specific methods for different use cases
/// 
/// Usage Examples:
/// ```dart
/// // In your widget
/// Container(
///   width: ResponsiveUtils.width(context, 200),   // 200px in design
///   height: ResponsiveUtils.height(context, 100),  // 100px in design
///   padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
///   child: Text(
///     'Hello',
///     style: TextStyle(
///       fontSize: ResponsiveUtils.fontSize(context, 18),
///     ),
///   ),
/// )
/// 
/// // Responsive layouts
/// if (ResponsiveUtils.isTablet(context)) {
///   return TabletLayout();
/// } else {
///   return PhoneLayout();
/// }
/// ```
/// 
/// Design Reference:
/// - Base Width: 375px (standard mobile)
/// - Base Height: 812px (iPhone X/11/12/13 Pro)
/// - Tablet Breakpoint: 600dp shortest side
/// 
/// Best Practices:
/// - Always use these utilities instead of hardcoded pixel values
/// - Test on multiple screen sizes (small phone, large phone, tablet)
/// - Consider using spacing() for consistent padding/margins
/// - Use isTablet() for layout variations rather than manual checks
class ResponsiveUtils {
  /// Design reference width (based on a standard phone screen)
  static const double _designWidth = 375.0;
  static const double _designHeight = 812.0;

  /// Get responsive width based on screen size
  static double width(BuildContext context, double size) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (size / _designWidth) * screenWidth;
  }

  /// Get responsive height based on screen size
  static double height(BuildContext context, double size) {
    final screenHeight = MediaQuery.of(context).size.height;
    return (size / _designHeight) * screenHeight;
  }

  /// Get responsive font size
  static double fontSize(BuildContext context, double size) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / _designWidth;
    // Limit scaling between 0.85 and 1.3 for readability
    final clampedScale = scale.clamp(0.85, 1.3);
    return size * clampedScale;
  }

  /// Get responsive spacing
  static double spacing(BuildContext context, double size) {
    return width(context, size);
  }

  /// Get responsive radius
  static double radius(BuildContext context, double size) {
    return width(context, size);
  }

  /// Check if device is a tablet
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.shortestSide >= 600;
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get safe grid columns based on screen width
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    if (width >= 600) return 3;
    return 2; // Default for phones
  }

  /// Get responsive padding
  static EdgeInsets padding(
    BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) {
    return EdgeInsets.only(
      left: width(context, left ?? horizontal ?? all ?? 0),
      right: width(context, right ?? horizontal ?? all ?? 0),
      top: height(context, top ?? vertical ?? all ?? 0),
      bottom: height(context, bottom ?? vertical ?? all ?? 0),
    );
  }

  /// Get responsive button height
  static double buttonHeight(BuildContext context) {
    return height(context, 48);
  }

  /// Get responsive icon size
  static double iconSize(BuildContext context, double size) {
    return width(context, size);
  }

  /// Get responsive avatar size
  static double avatarSize(BuildContext context, double size) {
    return width(context, size);
  }
}

/// Extension on BuildContext for easier access
extension ResponsiveExtension on BuildContext {
  double rWidth(double size) => ResponsiveUtils.width(this, size);
  double rHeight(double size) => ResponsiveUtils.height(this, size);
  double rFontSize(double size) => ResponsiveUtils.fontSize(this, size);
  double rSpacing(double size) => ResponsiveUtils.spacing(this, size);
  double rRadius(double size) => ResponsiveUtils.radius(this, size);
  double rIconSize(double size) => ResponsiveUtils.iconSize(this, size);
  double rAvatarSize(double size) => ResponsiveUtils.avatarSize(this, size);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isLandscape => ResponsiveUtils.isLandscape(this);
  int get gridColumns => ResponsiveUtils.getGridColumns(this);
  EdgeInsets rPadding({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) => ResponsiveUtils.padding(
    this,
    all: all,
    horizontal: horizontal,
    vertical: vertical,
    left: left,
    right: right,
    top: top,
    bottom: bottom,
  );
}
