import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../pages/story_viewer_page.dart';
import '../story_creator_page.dart';
import '../models/story_model.dart';

/// Dynamic Story Row - Instagram-style story bar
/// Shows current user's story or + button, then other users' stories
class DynamicStoryRow extends StatefulWidget {
  const DynamicStoryRow({Key? key}) : super(key: key);

  @override
  State<DynamicStoryRow> createState() => _DynamicStoryRowState();
}

class _DynamicStoryRowState extends State<DynamicStoryRow>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<StoryItem> _storyItems = [];
  StoryItem? _currentUserStory;
  bool _isLoading = true;
  RealtimeChannel? _storyChannel;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchStories();
    _subscribeToRealtimeUpdates();
  }

  @override
  void dispose() {
    _storyChannel?.unsubscribe();
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
  }

  Future<void> _fetchStories() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Fetch all active stories with user info
      final response = await _supabase
          .from('stories')
          .select('*, users!inner(uid, username, photo_url, usernameDisplay)')
          .gt('expires_at', DateTime.now().toIso8601String())
          .eq('is_archived', false)
          .order('created_at', ascending: false);

      final stories = response as List;

      // Group stories by user
      final Map<String, StoryItem> groupedStories = {};

      for (final storyData in stories) {
        final userId = storyData['user_id'] as String;
        final username =
            storyData['users']['usernameDisplay'] ??
            storyData['users']['username'] ??
            'User';
        final photoUrl = storyData['users']['photo_url'] as String? ?? '';

        if (!groupedStories.containsKey(userId)) {
          groupedStories[userId] = StoryItem(
            userId: userId,
            username: username,
            userPhotoUrl: photoUrl,
            segments: [],
            lastUpdated: DateTime.parse(storyData['created_at'] as String),
            isViewed: false,
          );
        }

        // Create segment
        final segment = StorySegment(
          id: storyData['id'] as String,
          mediaUrl: storyData['media_url'] as String,
          thumbnailUrl: storyData['thumbnail_url'] as String?,
          mediaType: storyData['media_type'] == 'video'
              ? StoryMediaType.video
              : StoryMediaType.image,
          caption: storyData['caption'] as String?,
          createdAt: DateTime.parse(storyData['created_at'] as String),
          expiresAt: DateTime.parse(storyData['expires_at'] as String),
          viewsCount: storyData['views_count'] as int? ?? 0,
          isViewed: await _hasViewedSegment(
            storyData['id'] as String,
            currentUserId,
          ),
        );

        groupedStories[userId] = groupedStories[userId]!.copyWith(
          segments: [...groupedStories[userId]!.segments, segment],
        );
      }

      // Check if current user has viewed all segments in each story
      for (final entry in groupedStories.entries) {
        final hasViewedAll = entry.value.segments.every(
          (segment) => segment.isViewed,
        );
        groupedStories[entry.key] = entry.value.copyWith(
          isViewed: hasViewedAll,
        );
      }

      setState(() {
        // Separate current user's story
        _currentUserStory = groupedStories.remove(currentUserId);

        // Sort others by created_at (most recent first)
        _storyItems = groupedStories.values.toList()
          ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

        _isLoading = false;
      });

      // Trigger animation for new stories
      _animationController.forward(from: 0);
    } catch (e) {
      print('Error fetching stories: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _hasViewedSegment(String storyId, String viewerId) async {
    try {
      final viewed = await _supabase
          .from('story_viewers')
          .select('id')
          .eq('story_id', storyId)
          .eq('viewer_id', viewerId)
          .maybeSingle();

      return viewed != null;
    } catch (e) {
      return false;
    }
  }

  void _subscribeToRealtimeUpdates() {
    _storyChannel = _supabase
        .channel('stories_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'stories',
          callback: (payload) => _fetchStories(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'stories',
          callback: (payload) => _fetchStories(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'stories',
          callback: (payload) => _fetchStories(),
        )
        .subscribe();
  }

  void _openStoryViewer(StoryItem storyItem, int initialSegmentIndex) {
    final currentUserId = _supabase.auth.currentUser?.id ?? '';

    // Combine all stories for navigation
    final allStories = [
      if (_currentUserStory != null) _currentUserStory!,
      ..._storyItems,
    ];

    // Find the index of this story item in the combined list
    final initialStoryIndex = allStories.indexWhere(
      (item) => item.userId == storyItem.userId,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryViewerPage(
          stories: allStories,
          initialIndex: initialStoryIndex >= 0 ? initialStoryIndex : 0,
          currentUserId: currentUserId,
        ),
      ),
    ).then((_) => _fetchStories()); // Refresh after viewing
  }

  void _openStoryCreator() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StoryCreatorPage()),
    ).then((_) => _fetchStories()); // Refresh after posting
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return _buildLoadingSkeleton(isDark);
    }

    return Container(
      height: 110,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        physics: const BouncingScrollPhysics(),
        itemCount: _storyItems.length + 1, // +1 for current user
        itemBuilder: (context, index) {
          if (index == 0) {
            // Current user bubble
            return _buildCurrentUserBubble(isDark);
          } else {
            // Other users' stories
            final storyItem = _storyItems[index - 1];
            return _buildStoryBubble(storyItem, isDark);
          }
        },
      ),
    );
  }

  Widget _buildCurrentUserBubble(bool isDark) {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    final hasStory = _currentUserStory != null;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: hasStory
                  ? () => _openStoryViewer(_currentUserStory!, 0)
                  : _openStoryCreator,
              onLongPress: hasStory
                  ? () => _showStoryManagementOptions()
                  : null,
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasStory
                      ? LinearGradient(
                          colors: [
                            Colors.orange.shade400,
                            Colors.pink.shade400,
                            Colors.purple.shade400,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  border: !hasStory
                      ? Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                          width: 2,
                        )
                      : null,
                ),
                padding: const EdgeInsets.all(2),
                child: Stack(
                  children: [
                    // Profile picture
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? kDarkBackground : Colors.white,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child:
                            _currentUserStory?.userPhotoUrl != null &&
                                _currentUserStory!.userPhotoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _currentUserStory!.userPhotoUrl,
                                width: 62,
                                height: 62,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Container(
                                width: 62,
                                height: 62,
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    // Add button overlay (if no story)
                    if (!hasStory)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: kPrimary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? kDarkBackground : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 70,
              child: Text(
                hasStory ? 'Your Story' : 'Add Story',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryBubble(StoryItem storyItem, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _openStoryViewer(storyItem, 0),
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: !storyItem.isViewed
                    ? LinearGradient(
                        colors: [
                          Colors.orange.shade400,
                          Colors.pink.shade400,
                          Colors.purple.shade400,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: storyItem.isViewed
                    ? Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                        width: 2,
                      )
                    : null,
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? kDarkBackground : Colors.white,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: storyItem.userPhotoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: storyItem.userPhotoUrl,
                          width: 62,
                          height: 62,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Container(
                          width: 62,
                          height: 62,
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              storyItem.username,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return Container(
      height: 110,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 50,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showStoryManagementOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _StoryManagementSheet(
        onViewInsights: () {
          Navigator.pop(context);
          // TODO: Navigate to story insights page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Story insights coming soon!')),
          );
        },
        onArchive: () async {
          Navigator.pop(context);
          try {
            if (_currentUserStory != null) {
              for (final segment in _currentUserStory!.segments) {
                await _supabase
                    .from('stories')
                    .update({'is_archived': true})
                    .eq('id', segment.id);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Story archived successfully')),
              );
              _fetchStories();
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error archiving story: $e')),
            );
          }
        },
        onDelete: () async {
          Navigator.pop(context);
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Story?'),
              content: const Text('This story will be permanently deleted.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );

          if (confirmed == true && _currentUserStory != null) {
            try {
              for (final segment in _currentUserStory!.segments) {
                await _supabase.from('stories').delete().eq('id', segment.id);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Story deleted successfully')),
              );
              _fetchStories();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error deleting story: $e')),
              );
            }
          }
        },
      ),
    );
  }
}

/// Story Management Bottom Sheet
class _StoryManagementSheet extends StatelessWidget {
  final VoidCallback onViewInsights;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _StoryManagementSheet({
    required this.onViewInsights,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.insights_rounded, color: kPrimary),
              title: const Text('View Insights'),
              onTap: onViewInsights,
            ),
            ListTile(
              leading: const Icon(Icons.archive_rounded, color: Colors.blue),
              title: const Text('Archive Story'),
              onTap: onArchive,
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('Delete Story'),
              onTap: onDelete,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
