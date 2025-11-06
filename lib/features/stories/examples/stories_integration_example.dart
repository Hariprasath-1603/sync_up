import 'package:flutter/material.dart';
import '../widgets/enhanced_story_bar.dart';
import '../models/story_model.dart';
import '../pages/story_media_selection_page.dart';
import '../../../core/services/story_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Example integration of Story Upload Flow with Enhanced Story Bar
/// Add this to your HomePage or create a dedicated Stories Feed page
class StoriesIntegrationExample extends StatefulWidget {
  const StoriesIntegrationExample({super.key});

  @override
  State<StoriesIntegrationExample> createState() =>
      _StoriesIntegrationExampleState();
}

class _StoriesIntegrationExampleState extends State<StoriesIntegrationExample> {
  final StoryService _storyService = StoryService();
  List<StoryItem> _stories = [];
  bool _hasMyStory = false;
  bool _isLoading = true;
  String? _currentUserPhotoUrl;
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    try {
      setState(() => _isLoading = true);

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Load current user info
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('username, photo_url')
          .eq('uid', currentUser.id)
          .single();

      _currentUsername = userResponse['username'];
      _currentUserPhotoUrl = userResponse['photo_url'];

      // Check if current user has active stories
      _hasMyStory = await _storyService.hasActiveStories();

      // Load following users' stories (simplified example)
      // In production, you'd query stories from followed users
      final storiesData = await Supabase.instance.client
          .from('stories')
          .select('*, users(username, photo_url)')
          .gte('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      // Group stories by user
      final Map<String, List<Map<String, dynamic>>> groupedByUser = {};
      for (final story in storiesData) {
        final userId = story['user_id'] as String;
        if (!groupedByUser.containsKey(userId)) {
          groupedByUser[userId] = [];
        }
        groupedByUser[userId]!.add(story);
      }

      // Convert to StoryItem objects
      final stories = <StoryItem>[];
      for (final entry in groupedByUser.entries) {
        final userStories = entry.value;
        if (userStories.isEmpty) continue;

        final firstStory = userStories.first;
        final userData = firstStory['users'] as Map<String, dynamic>?;

        stories.add(
          StoryItem(
            userId: entry.key,
            username: userData?['username'] ?? 'Unknown',
            userPhotoUrl: userData?['photo_url'] ?? '',
            segments: userStories
                .map(
                  (s) => StorySegment(
                    id: s['id'] as String,
                    mediaUrl: s['media_url'] as String,
                    mediaType: s['media_type'] == 'video'
                        ? StoryMediaType.video
                        : StoryMediaType.image,
                    caption: s['caption'] as String?,
                    createdAt: DateTime.parse(s['created_at'] as String),
                    expiresAt: DateTime.parse(s['expires_at'] as String),
                    viewsCount: s['views_count'] as int? ?? 0,
                  ),
                )
                .toList(),
            lastUpdated: DateTime.parse(
              userStories.first['created_at'] as String,
            ),
            isViewed: false, // TODO: Track viewed stories
          ),
        );
      }

      setState(() {
        _stories = stories;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading stories: $e');
      setState(() => _isLoading = false);
    }
  }

  void _handleAddStory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StoryMediaSelectionPage()),
    ).then((_) {
      // Refresh stories after returning from upload
      _loadStories();
    });
  }

  void _handleViewStory(StoryItem story) {
    // TODO: Navigate to Story Viewer Page
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => StoryViewerPage(story: story),
    //   ),
    // );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Story Viewer - Coming Soon! 🎬'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleViewMyStory() {
    // TODO: Navigate to Story Viewer with creator controls
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => StoryViewerPage(
    //       story: myStory,
    //       isOwnStory: true,
    //     ),
    //   ),
    // );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your Story Viewer - Coming Soon! 👁️'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stories Bar
        if (_isLoading)
          const SizedBox(
            height: 105,
            child: Center(child: CircularProgressIndicator()),
          )
        else
          EnhancedStoryBar(
            stories: _stories,
            currentUserId: Supabase.instance.client.auth.currentUser?.id ?? '',
            currentUserPhotoUrl: _currentUserPhotoUrl,
            currentUsername: _currentUsername,
            hasMyStory: _hasMyStory,
            onAddStory: _handleAddStory,
            onViewStory: _handleViewStory,
            onViewMyStory: _handleViewMyStory,
          ),

        // Refresh button (for testing)
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _loadStories,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh Stories'),
        ),
      ],
    );
  }
}

// Usage in your HomePage:
//
// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     body: CustomScrollView(
//       slivers: [
//         SliverToBoxAdapter(
//           child: StoriesIntegrationExample(),
//         ),
//         // Your feed posts...
//       ],
//     ),
//   );
// }
