import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import 'create_post_page.dart';
import 'drafts_page.dart';
import 'scheduled_posts_page.dart';
import '../reels/create_reel_page.dart';
import '../live/go_live_page.dart';
import '../stories/create_story_page.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () {
          _animationController.reverse().then((_) => Navigator.pop(context));
        },
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: GestureDetector(
                  onTap: () {}, // Prevent closing when tapping the content
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Close button at top
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              _animationController.reverse().then(
                                (_) => Navigator.pop(context),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.black,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Create Post Option
                        _buildCreateOption(
                          icon: Icons.add_photo_alternate_outlined,
                          title: 'Create Post',
                          description: 'Share photos and thoughts',
                          gradient: LinearGradient(
                            colors: [kPrimary, kPrimary.withOpacity(0.7)],
                          ),
                          onTap: () {
                            _animationController.reverse().then((_) {
                              context.pop();
                              _showCreatePostSheet(context);
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Create Reel Option
                        _buildCreateOption(
                          icon: Icons.video_library_outlined,
                          title: 'Create Reel',
                          description: 'Record or upload video',
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE1306C), Color(0xFFC13584)],
                          ),
                          onTap: () {
                            _animationController.reverse().then((_) {
                              context.pop();
                              _showCreateReelSheet(context);
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Go Live Option
                        _buildCreateOption(
                          icon: Icons.video_call_outlined,
                          title: 'Go Live',
                          description: 'Start a live stream',
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)],
                          ),
                          onTap: () {
                            _animationController.reverse().then((_) {
                              context.pop();
                              _showGoLiveSheet(context);
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Create Story Option
                        _buildCreateOption(
                          icon: Icons.auto_awesome_outlined,
                          title: 'Create Story',
                          description: '24-hour story update',
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFCAF45), Color(0xFFF77737)],
                          ),
                          onTap: () {
                            _animationController.reverse().then((_) {
                              context.pop();
                              _showCreateStorySheet(context);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateOption({
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreatePostSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1D24) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey[600]!;
    final borderColor = isDark ? Colors.white12 : Colors.grey[300]!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Create Post',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildPostOption(
              context,
              Icons.post_add,
              'Create Post',
              'Create post with all options',
              textColor,
              subtitleColor,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePostPage(),
                  ),
                );
              },
            ),
            _buildPostOption(
              context,
              Icons.drafts,
              'Drafts',
              'View and edit saved drafts',
              textColor,
              subtitleColor,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DraftsPage()),
                );
              },
            ),
            _buildPostOption(
              context,
              Icons.schedule,
              'Scheduled Posts',
              'Manage scheduled content',
              textColor,
              subtitleColor,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScheduledPostsPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPostOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color textColor,
    Color subtitleColor,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: kPrimary),
      ),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: subtitleColor, fontSize: 12),
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: subtitleColor, size: 16),
      onTap: onTap,
    );
  }

  void _showCreateReelSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateReelPage()),
    );
  }

  void _showGoLiveSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GoLivePage()),
    );
  }

  void _showCreateStorySheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateStoryPage(),
      ),
    );
  }
}
