import 'package:flutter/material.dart';
import '../utils/bottom_sheet_utils.dart';

/// Example implementations of intelligent bottom navigation bar behavior
///
/// This file demonstrates various use cases for automatic navbar hiding
/// when showing bottom sheets, modals, and input fields.

/// Example 1: Simple bottom sheet with automatic navbar hiding
Future<void> showSimpleBottomSheet(BuildContext context) async {
  await BottomSheetUtils.showAdaptiveBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Simple Bottom Sheet'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    ),
  );
}

/// Example 2: Premium styled bottom sheet with blur effect
Future<void> showPremiumBottomSheet(BuildContext context) async {
  await BottomSheetUtils.showAdaptiveBottomSheet(
    context: context,
    withBlur: true,
    isScrollControlled: true,
    builder: (context) => BottomSheetUtils.createPremiumBottomSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Premium Bottom Sheet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('With glassmorphic design and blur effect'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    ),
  );
}

/// Example 3: Bottom sheet with text input (keyboard automatically hides navbar)
Future<void> showInputBottomSheet(BuildContext context) async {
  final textController = TextEditingController();

  await BottomSheetUtils.showAdaptiveBottomSheet(
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
            const Text(
              'Enter your comment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Type something...',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final text = textController.text;
                    Navigator.pop(context, text);
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Example 4: Custom modal with blur and scale animation
Future<void> showCustomModal(BuildContext context) async {
  await BottomSheetUtils.showCustomModal(
    context: context,
    withBlur: true,
    withScaleTransition: true,
    withFadeTransition: true,
    builder: (context) => Center(
      child: Container(
        margin: const EdgeInsets.all(40),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Success!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Your action was completed successfully'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Example 5: Using context extension methods for manual control
class ManualNavbarControlExample extends StatelessWidget {
  const ManualNavbarControlExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Control')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => context.hideNavBar(),
              child: const Text('Hide Navbar'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.showNavBar(),
              child: const Text('Show Navbar'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.toggleNavBar(),
              child: const Text('Toggle Navbar'),
            ),
            const SizedBox(height: 24),
            Text(
              'Navbar is ${context.isNavBarVisible ? 'visible' : 'hidden'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example 6: Photo picker with crop - realistic use case
Future<void> showUpdateProfilePhotoMenu(BuildContext context) async {
  await BottomSheetUtils.showAdaptiveBottomSheet(
    context: context,
    builder: (context) => BottomSheetUtils.createPremiumBottomSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Update Profile Photo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          _buildMenuOption(
            context,
            icon: Icons.camera_alt,
            label: 'Take Photo',
            onTap: () {
              Navigator.pop(context);
              // Handle camera
            },
          ),
          _buildMenuOption(
            context,
            icon: Icons.photo_library,
            label: 'Choose from Gallery',
            onTap: () {
              Navigator.pop(context);
              // Handle gallery
            },
          ),
          _buildMenuOption(
            context,
            icon: Icons.delete_outline,
            label: 'Remove Photo',
            isDestructive: true,
            onTap: () {
              Navigator.pop(context);
              // Handle remove
            },
          ),
        ],
      ),
    ),
  );
}

Widget _buildMenuOption(
  BuildContext context, {
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  bool isDestructive = false,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive
                  ? Colors.red
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isDestructive
                    ? Colors.red
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Example 7: Post creation modal
Future<void> showCreatePostModal(BuildContext context) async {
  await BottomSheetUtils.showAdaptiveBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return BottomSheetUtils.createPremiumBottomSheet(
          context: context,
          child: ListView(
            controller: scrollController,
            children: [
              const Text(
                'Create Post',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  hintText: "What's on your mind?",
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.photo), onPressed: () {}),
                  IconButton(
                    icon: const Icon(Icons.videocam),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.location_on),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Post'),
              ),
            ],
          ),
        );
      },
    ),
  );
}
