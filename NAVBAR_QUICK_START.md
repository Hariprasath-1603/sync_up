# 🚀 Quick Start - Intelligent Navbar Behavior

## ⚡ 30-Second Implementation

### Step 1: Import the utility
```dart
import 'package:sync_up/core/utils/bottom_sheet_utils.dart';
```

### Step 2: Replace your showModalBottomSheet
```dart
// Before
showModalBottomSheet(context: context, builder: (ctx) => Widget());

// After
BottomSheetUtils.showAdaptiveBottomSheet(
  context: context, 
  builder: (ctx) => Widget()
);
```

### That's it! 🎉
- ✅ Navbar automatically hides
- ✅ Smooth animations
- ✅ Haptic feedback
- ✅ Returns when closed

---

## 📱 Common Use Cases

### 1️⃣ Basic Menu
```dart
void showMenu(BuildContext context) {
  BottomSheetUtils.showAdaptiveBottomSheet(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(title: Text('Option 1'), onTap: () {}),
        ListTile(title: Text('Option 2'), onTap: () {}),
      ],
    ),
  );
}
```

### 2️⃣ Premium Styled Sheet
```dart
void showPremiumMenu(BuildContext context) {
  BottomSheetUtils.showAdaptiveBottomSheet(
    context: context,
    builder: (context) => BottomSheetUtils.createPremiumBottomSheet(
      context: context,
      child: YourContent(),
    ),
  );
}
```

### 3️⃣ Input Sheet (Keyboard Auto-Hides Navbar)
```dart
void showCommentInput(BuildContext context) {
  BottomSheetUtils.showAdaptiveBottomSheet(
    context: context,
    isScrollControlled: true,  // Important for keyboard!
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: TextField(
        decoration: InputDecoration(hintText: 'Type comment...'),
      ),
    ),
  );
}
```

### 4️⃣ Manual Control
```dart
// Hide navbar
context.hideNavBar();

// Show navbar (with haptic)
context.showNavBar();

// Toggle
context.toggleNavBar();

// Check status
if (context.isNavBarVisible) {
  // navbar is visible
}
```

---

## 🎯 Key Features

| Feature | Status | Notes |
|---------|--------|-------|
| Auto keyboard detection | ✅ | No code needed |
| Auto bottom sheet | ✅ | Use BottomSheetUtils |
| Smooth animations | ✅ | 300ms slide + fade |
| Haptic feedback | ✅ | On show/hide |
| Dark mode support | ✅ | Automatic |
| Premium effects | ✅ | Add `withBlur: true` |

---

## 📝 Examples by Feature

### Photo Picker Menu
```dart
BottomSheetUtils.showAdaptiveBottomSheet(
  context: context,
  builder: (context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ListTile(
        leading: Icon(Icons.camera_alt),
        title: Text('Take Photo'),
        onTap: () => Navigator.pop(context, 'camera'),
      ),
      ListTile(
        leading: Icon(Icons.photo_library),
        title: Text('Gallery'),
        onTap: () => Navigator.pop(context, 'gallery'),
      ),
    ],
  ),
);
```

### Post Options
```dart
BottomSheetUtils.showAdaptiveBottomSheet(
  context: context,
  builder: (context) => BottomSheetUtils.createPremiumBottomSheet(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(title: Text('Edit'), onTap: () {}),
        ListTile(title: Text('Share'), onTap: () {}),
        ListTile(
          title: Text('Delete', style: TextStyle(color: Colors.red)),
          onTap: () {},
        ),
      ],
    ),
  ),
);
```

---

## 🔥 Pro Tips

1. **For tall content:** Add `isScrollControlled: true`
2. **For input fields:** Wrap in `Padding` with `viewInsets.bottom`
3. **For premium look:** Use `createPremiumBottomSheet()`
4. **For custom modals:** Use `showCustomModal()` instead

---

## 🧪 Test Your Implementation

1. Run the app: `flutter run`
2. Open any text field → Navbar should hide
3. Dismiss keyboard → Navbar should appear
4. Open a bottom sheet → Navbar should hide
5. Close the sheet → Navbar should appear with haptic

---

## 📚 Full Documentation

- **Complete Guide**: `NAVBAR_INTELLIGENT_BEHAVIOR_GUIDE.md`
- **Examples**: `lib/core/examples/navbar_behavior_examples.dart`
- **Test Page**: `lib/features/test/navbar_behavior_test_page.dart`

---

## ❓ Troubleshooting

### Navbar not hiding?
✅ Make sure you're using `BottomSheetUtils.showAdaptiveBottomSheet()`

### Keyboard not working?
✅ Add `resizeToAvoidBottomInset: true` to your Scaffold

### No haptic feedback?
✅ Test on a real device (simulators may not support haptics)

---

**That's it! You're ready to go! 🎉**

Your navbar is now intelligent and will automatically hide/show based on context!
