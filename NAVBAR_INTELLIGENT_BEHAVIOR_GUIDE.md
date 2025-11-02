# Intelligent Bottom Navigation Bar Implementation Guide

## 🎯 Overview

This implementation provides an **intelligent bottom navigation bar** that automatically hides and shows with smooth animations when:
- The keyboard appears/disappears
- Bottom sheets are opened/closed
- Modals are displayed/dismissed
- Any UI element that should have the navbar out of the way

## ✨ Features

### 1. **Automatic Keyboard Detection**
The navbar automatically hides when the keyboard appears and reappears when dismissed, with no manual code needed.

### 2. **Smooth Animations**
- Slide animation (300ms) with easing curve
- Fade animation (250ms) for smooth opacity transitions
- Shadow softening for premium feel

### 3. **Haptic Feedback**
- Light haptic on navbar hide
- Selection click haptic on navbar show
- Enhanced UX like premium apps (Instagram, Telegram)

### 4. **Blur & Premium Effects**
- Optional backdrop blur for modals
- Glassmorphic bottom sheets
- Professional shadow transitions

## 📂 Files Modified/Created

### Core Files
1. **`lib/core/scaffold_with_nav_bar.dart`** - Enhanced with keyboard detection
2. **`lib/core/utils/bottom_sheet_utils.dart`** - New utility for automatic navbar management
3. **`lib/core/examples/navbar_behavior_examples.dart`** - Usage examples

### Updated Files
1. **`lib/features/profile/other_user_profile_page.dart`** - Demo implementation

## 🚀 Usage

### Method 1: Using BottomSheetUtils (Recommended)

```dart
import 'package:sync_up/core/utils/bottom_sheet_utils.dart';

// Simple bottom sheet with automatic navbar hiding
await BottomSheetUtils.showAdaptiveBottomSheet(
  context: context,
  builder: (context) => YourBottomSheetWidget(),
);

// Premium styled bottom sheet with blur
await BottomSheetUtils.showAdaptiveBottomSheet(
  context: context,
  withBlur: true,
  builder: (context) => BottomSheetUtils.createPremiumBottomSheet(
    context: context,
    child: YourContent(),
  ),
);

// Custom modal with animations
await BottomSheetUtils.showCustomModal(
  context: context,
  withBlur: true,
  withScaleTransition: true,
  builder: (context) => YourModalWidget(),
);
```

### Method 2: Using Context Extensions

```dart
import 'package:sync_up/core/utils/bottom_sheet_utils.dart';

// Manual control
context.hideNavBar();   // Hide navbar
context.showNavBar();   // Show navbar with haptic
context.toggleNavBar(); // Toggle visibility

// Check state
if (context.isNavBarVisible) {
  // Navbar is visible
}
```

### Method 3: Legacy Manual Control (If needed)

```dart
import 'package:sync_up/core/scaffold_with_nav_bar.dart';

final navVisibility = NavBarVisibilityScope.maybeOf(context);

// Hide
navVisibility?.value = false;

// Show
navVisibility?.value = true;
```

## 🎨 Implementation Details

### Automatic Keyboard Handling

The `ScaffoldWithNavBar` widget implements `WidgetsBindingObserver` to monitor keyboard state changes:

```dart
@override
void didChangeMetrics() {
  final isKeyboardVisible = View.of(context).viewInsets.bottom > 0;
  
  if (isKeyboardVisible && !_wasKeyboardVisible) {
    // Keyboard appeared - hide navbar
    _navIsVisible.value = false;
  } else if (!isKeyboardVisible && _wasKeyboardVisible) {
    // Keyboard dismissed - show navbar
    _navIsVisible.value = true;
    HapticFeedback.selectionClick();
  }
}
```

### Animation Configuration

```dart
// Slide animation
AnimatedSlide(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeOutCubic,
  offset: isVisible ? Offset.zero : const Offset(0, 1.2),
  child: ...
)

// Fade animation
AnimatedOpacity(
  duration: const Duration(milliseconds: 250),
  curve: Curves.easeInOut,
  opacity: isVisible ? 1 : 0,
  child: ...
)
```

## 📋 Migration Guide

### Updating Existing Bottom Sheets

**Before:**
```dart
final navVisibility = NavBarVisibilityScope.maybeOf(context);
navVisibility?.value = false;

showModalBottomSheet(
  context: context,
  builder: (context) => YourWidget(),
).whenComplete(() {
  navVisibility?.value = true;
});
```

**After:**
```dart
BottomSheetUtils.showAdaptiveBottomSheet(
  context: context,
  builder: (context) => YourWidget(),
);
```

### Benefits of Migration:
- ✅ Less boilerplate code
- ✅ Automatic haptic feedback
- ✅ Consistent animations
- ✅ Built-in blur effects
- ✅ Better error handling

## 🎯 Real-World Examples

### Example 1: Update Profile Photo Menu
```dart
Future<void> showUpdateProfilePhotoMenu(BuildContext context) async {
  await BottomSheetUtils.showAdaptiveBottomSheet(
    context: context,
    builder: (context) => BottomSheetUtils.createPremiumBottomSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('Take Photo'),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Choose from Gallery'),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
        ],
      ),
    ),
  );
}
```

### Example 2: Comment Input Sheet
```dart
Future<String?> showCommentInput(BuildContext context) async {
  final controller = TextEditingController();
  
  return await BottomSheetUtils.showAdaptiveBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: BottomSheetUtils.createPremiumBottomSheet(
        context: context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(hintText: 'Add a comment...'),
              autofocus: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text('Post'),
            ),
          ],
        ),
      ),
    ),
  );
}
```

### Example 3: Post Options Menu
```dart
void showPostOptions(BuildContext context) {
  BottomSheetUtils.showAdaptiveBottomSheet(
    context: context,
    builder: (context) => BottomSheetUtils.createPremiumBottomSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit Post'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete Post', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}
```

## 🔧 Customization Options

### Custom Animation Durations
```dart
// In scaffold_with_nav_bar.dart, modify:
AnimatedSlide(
  duration: const Duration(milliseconds: 300), // Change this
  curve: Curves.easeOutCubic,                  // Or change curve
  ...
)
```

### Custom Haptic Feedback
```dart
// In bottom_sheet_utils.dart, modify:
HapticFeedback.lightImpact();     // Light
HapticFeedback.mediumImpact();    // Medium
HapticFeedback.heavyImpact();     // Heavy
HapticFeedback.selectionClick();  // Selection
```

### Custom Blur Intensity
```dart
BottomSheetUtils.showAdaptiveBottomSheet(
  context: context,
  withBlur: true,  // Uses default blur
  builder: (context) => BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Custom intensity
    child: YourWidget(),
  ),
);
```

## 📊 Performance Considerations

1. **Smooth 60 FPS animations** - Optimized curve and duration
2. **Minimal rebuilds** - Uses ValueNotifier for state management
3. **Keyboard detection** - Native platform metrics, zero overhead
4. **Haptic feedback** - Lightweight, non-blocking calls

## 🐛 Troubleshooting

### Navbar not hiding automatically?
- Ensure you're using `BottomSheetUtils.showAdaptiveBottomSheet()`
- Check that the widget is within `ScaffoldWithNavBar` context

### Keyboard doesn't hide navbar?
- Make sure your Scaffold has `resizeToAvoidBottomInset: true`
- Verify `ScaffoldWithNavBar` is your root scaffold

### Animations feel choppy?
- Check for heavy widgets in your bottom sheet
- Use `const` constructors where possible
- Profile with Flutter DevTools Performance tab

### Haptic not working?
- Verify platform permissions (iOS/Android)
- Check device settings for haptic feedback
- Test on physical device (simulators may not support haptics)

## 🎨 Design Philosophy

This implementation follows modern app design principles:

1. **Telegram-style** - Smooth, fast, predictable
2. **Instagram-like** - Premium blur effects
3. **TikTok-inspired** - Responsive, fluid animations
4. **WhatsApp approach** - Contextual, intelligent hiding

## 📈 Future Enhancements

Potential additions:
- [ ] Gesture-based dismiss with navbar sync
- [ ] Custom transition builders
- [ ] Navbar color adaptation
- [ ] Smart scroll-based hiding
- [ ] Multi-level sheet support

## 🙌 Credits

Implemented with Flutter best practices and modern UX patterns inspired by leading social media apps.

---

**Questions?** Check the examples in `lib/core/examples/navbar_behavior_examples.dart`
