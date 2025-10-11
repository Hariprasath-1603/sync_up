// HOW TO USE THE MODERN CREATE REEL UI
// ======================================

import 'package:flutter/material.dart';
import 'package:sync_up/features/reels/create_reel_modern.dart';

// OPTION 1: From a Button/FAB
// ----------------------------
class ExampleUsage1 extends StatelessWidget {
  const ExampleUsage1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Create Reel
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateReelModern()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// OPTION 2: From a List Tile
// ---------------------------
class ExampleUsage2 extends StatelessWidget {
  const ExampleUsage2({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF3B5C), Color(0xFFFF6B9D)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.video_camera_back, color: Colors.white),
      ),
      title: const Text('Create Reel'),
      subtitle: const Text('Share your moment'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateReelModern()),
        );
      },
    );
  }
}

// OPTION 3: From Profile Page
// ----------------------------
class ExampleUsage3 extends StatelessWidget {
  const ExampleUsage3({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Modern gradient button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateReelModern(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF3B5C), Color(0xFFFF6B9D)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF3B5C).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Create Reel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// OPTION 4: With Go Router
// -------------------------
// Add to your app_router.dart:
/*
GoRoute(
  path: '/create-reel',
  builder: (context, state) => const CreateReelModern(),
),

// Then navigate:
context.go('/create-reel');
*/

// OPTION 5: Bottom Sheet Launch
// ------------------------------
class ExampleUsage5 extends StatelessWidget {
  const ExampleUsage5({super.key});

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1D24)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Create Reel Option
            ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF3B5C), Color(0xFFFF6B9D)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.videocam, color: Colors.white),
              ),
              title: const Text('Create Reel'),
              subtitle: const Text('Record or upload video'),
              onTap: () {
                Navigator.pop(context); // Close sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateReelModern(),
                  ),
                );
              },
            ),
            // Add more options...
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.add_box_outlined),
      onPressed: () => _showCreateOptions(context),
    );
  }
}

// SCREENS IN THE FLOW:
// ====================
// 1. CreateReelModern() - Camera screen with recording controls
// 2. ReelEditingModern() - Editing with 6 tabs (Audio, Text, Stickers, Filters, Effects, Trim)
// 3. ReelPreviewModern() - Preview and publish with caption, tags, location, visibility

// NAVIGATION FLOW:
// ================
// Camera -> Editing -> Preview -> Success Dialog -> Home
//   ↓         ↓          ↓
// Effects   Audio      Publish
// Music     Text
// Upload    Stickers
//           Filters
//           Effects
//           Trim

// FEATURES AVAILABLE:
// ===================
// ✅ Dark theme with modern gradients
// ✅ Camera interface with speed controls (0.5x, 1x, 2x, 3x)
// ✅ 9 AR effects (Green Screen, Beauty, Blur, etc.)
// ✅ Music library with search
// ✅ Upload from gallery/videos
// ✅ Text overlays with 4 styles
// ✅ 20+ emoji stickers
// ✅ 8 professional filters
// ✅ 6 video effects
// ✅ Trim and speed controls
// ✅ Caption with hashtags
// ✅ Tag people, add location, music
// ✅ Visibility options (Public/Friends/Private)
// ✅ Success confirmation dialog

// CUSTOMIZATION:
// ==============
// To change brand colors, search and replace:
// Color(0xFFFF3B5C) -> Your primary color
// Color(0xFFFF6B9D) -> Your secondary color

// For detailed documentation, see:
// MODERN_REEL_UI_GUIDE.md
