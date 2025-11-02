import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget that controls screenshot permission for its child
/// Use this to wrap sensitive pages where screenshots should be blocked
class ScreenshotProtection extends StatefulWidget {
  final Widget child;
  final bool preventScreenshots;

  const ScreenshotProtection({
    super.key,
    required this.child,
    this.preventScreenshots = false,
  });

  @override
  State<ScreenshotProtection> createState() => _ScreenshotProtectionState();
}

class _ScreenshotProtectionState extends State<ScreenshotProtection> {
  static const platform = MethodChannel('com.example.sync_up/screenshot');

  @override
  void initState() {
    super.initState();
    _updateScreenshotPermission();
  }

  @override
  void didUpdateWidget(ScreenshotProtection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preventScreenshots != widget.preventScreenshots) {
      _updateScreenshotPermission();
    }
  }

  @override
  void dispose() {
    // Always enable screenshots when leaving protected page
    _setScreenshotPermission(false);
    super.dispose();
  }

  Future<void> _updateScreenshotPermission() async {
    await _setScreenshotPermission(widget.preventScreenshots);
  }

  Future<void> _setScreenshotPermission(bool prevent) async {
    try {
      await platform.invokeMethod('setScreenshotProtection', {
        'prevent': prevent,
      });
    } catch (e) {
      debugPrint('Error setting screenshot protection: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
