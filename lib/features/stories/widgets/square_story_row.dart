import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../enhanced_story_viewer_v2.dart';
import '../story_creator_page.dart';
import '../models/story_model.dart';

/// Square Story Row - Modern tile-based story UI
/// Shows square cards instead of circular bubbles
class SquareStoryRow extends StatefulWidget {
  const SquareStoryRow({Key? key}) : super(key: key);

  @override
  State<SquareStoryRow> createState() => _SquareStoryRowState();
}

class _SquareStoryRowState extends State<SquareStoryRow>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<StoryItem> _storyItems = [];
  StoryItem? _currentUserStory;
  bool _isLoading = true;
  RealtimeChannel? _storyChannel;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchStories();
    _subscribeToRealtimeUpdates();
    _logToTerminal('📱 Square Story Row initialized');
  }

  @override
  void dispose() {
    _storyChannel?.unsubscribe();
    _animationController.dispose();
    _logToTerminal('🔴 Square Story Row disposed');
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  void _logToTerminal(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    print('[$timestamp] 🎬 STORY: $message');
  }

  Future<void> _fetchStories() async {
    _logToTerminal('🔄 Fetching stories from Supabase...');
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        _logToTerminal('⚠️ No authenticated user found');
        setState(() => _isLoading = false);
        return;
      }

      _logToTerminal('👤 Current user ID: ${currentUserId.substring(0, 8)}...');

      // Fetch all active stories with user info
      final response = await _supabase
          .from('stories')
          .select('*, users!inner(uid, username, photo_url, username_display)')
          .gt('expires_at', DateTime.now().toIso8601String())
          .eq('is_archived', false)
          .order('created_at', ascending: false);

      final stories = response as List;
      _logToTerminal('✅ Fetched ${stories.length} active stories');

      // Group stories by user
      final Map<String, StoryItem> groupedStories = {};

      for (final storyData in stories) {
        final userId = storyData['user_id'] as String;
        final username =
            storyData['users']['username_display'] ??
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

      if (_currentUserStory != null) {
        _logToTerminal(
          '✅ Current user has ${_currentUserStory!.segments.length} story segment(s)',
        );
      } else {
        _logToTerminal('ℹ️ Current user has no active story');
      }
      _logToTerminal('✅ Loaded ${_storyItems.length} other users\' stories');

      // Trigger animation
      _animationController.forward(from: 0);
    } catch (e) {
      _logToTerminal('❌ Error fetching stories: $e');
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
    _logToTerminal('🔔 Subscribing to real-time story updates...');
    _storyChannel = _supabase
        .channel('square_stories_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'stories',
          callback: (payload) {
            _logToTerminal('🆕 New story inserted - refreshing...');
            _fetchStories();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'stories',
          callback: (payload) {
            _logToTerminal('🗑️ Story deleted - refreshing...');
            _fetchStories();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'stories',
          callback: (payload) {
            _logToTerminal('📝 Story updated - refreshing...');
            _fetchStories();
          },
        )
        .subscribe();

    _logToTerminal('✅ Real-time subscription active');
  }

  void _openStoryViewer(StoryItem storyItem, int initialSegmentIndex) {
    final currentUserId = _supabase.auth.currentUser?.id ?? '';
    final isOwnStory = storyItem.userId == currentUserId;

    _logToTerminal(
      '▶️ Opening enhanced V2 story viewer for ${isOwnStory ? "own" : storyItem.username}\'s story',
    );

    // Convert StoryItem segments to List<Map<String, dynamic>> for viewer
    final storySegments = storyItem.segments.map((segment) {
      return {
        'id': segment.id,
        'user_id': storyItem.userId,
        'media_url': segment.mediaUrl,
        'media_type': segment.mediaType.name,
        'caption': segment.caption,
        'created_at': segment.createdAt.toIso8601String(),
        'views_count': segment.viewsCount,
      };
    }).toList();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EnhancedStoryViewerV2(
              stories: storySegments,
              initialIndex: initialSegmentIndex,
              userName: storyItem.username,
              userAvatar: storyItem.userPhotoUrl,
              userId: storyItem.userId,
              onClose: () {
                _logToTerminal(
                  '⏹️ Story viewer V2 closed - refreshing data...',
                );
                _fetchStories();
              },
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
        opaque: false,
      ),
    );
  }

  void _openStoryCreator() {
    _logToTerminal('➕ Opening story creator...');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StoryCreatorPage()),
    ).then((_) {
      _logToTerminal('⏹️ Story creator closed - refreshing data...');
      _fetchStories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return _buildLoadingSkeleton(isDark);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizedBox(
        height: 145,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          itemCount: _storyItems.length + 1, // +1 for current user
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              // Current user square card
              return _buildCurrentUserSquareCard(isDark);
            } else {
              // Other users' story cards
              final storyItem = _storyItems[index - 1];
              return _buildStorySquareCard(storyItem, isDark);
            }
          },
        ),
      ),
    );
  }

  Widget _buildCurrentUserSquareCard(bool isDark) {
    final hasStory = _currentUserStory != null;
    final thumbnailUrl = hasStory
        ? (_currentUserStory!.segments.first.thumbnailUrl ??
              _currentUserStory!.segments.first.mediaUrl)
        : null;

    return GestureDetector(
      onTap: hasStory
          ? () => _openStoryViewer(_currentUserStory!, 0)
          : _openStoryCreator,
      onLongPress: hasStory ? () => _showStoryManagementOptions() : null,
      child: Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: !hasStory
              ? const LinearGradient(
                  colors: [Color(0xFF7B9EFF), Color(0xFF637AFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          image: hasStory
              ? DecorationImage(
                  image: CachedNetworkImageProvider(thumbnailUrl!),
                  fit: BoxFit.cover,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gradient overlay for better text visibility
            if (hasStory)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),

            // Content
            if (hasStory)
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Story',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_currentUserStory!.segments.length} segment${_currentUserStory!.segments.length > 1 ? "s" : ""}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 10,
                          shadows: const [
                            Shadow(blurRadius: 5, color: Colors.black),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add, color: Colors.white, size: 32),
                    SizedBox(height: 6),
                    Text(
                      'Add Story',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            // Unviewed indicator
            if (hasStory && !_currentUserStory!.isViewed)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: kPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorySquareCard(StoryItem storyItem, bool isDark) {
    final thumbnailUrl =
        storyItem.segments.first.thumbnailUrl ??
        storyItem.segments.first.mediaUrl;

    return GestureDetector(
      onTap: () => _openStoryViewer(storyItem, 0),
      child: Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: CachedNetworkImageProvider(thumbnailUrl),
            fit: BoxFit.cover,
          ),
          border: !storyItem.isViewed
              ? Border.all(color: kPrimary, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),

            // Username
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  color: Colors.black.withOpacity(0.3),
                ),
                child: Text(
                  storyItem.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Unviewed indicator
            if (!storyItem.isViewed)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return SizedBox(
      height: 145,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Container(
            width: 100,
            height: 140,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  void _showStoryManagementOptions() {
    _logToTerminal('⚙️ Opening story management menu...');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _StoryManagementSheet(
        onViewInsights: () {
          Navigator.pop(context);
          _logToTerminal('📊 Insights requested (coming soon)');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Story insights coming soon!')),
          );
        },
        onArchive: () async {
          Navigator.pop(context);
          _logToTerminal('📦 Archiving story...');
          try {
            if (_currentUserStory != null) {
              for (final segment in _currentUserStory!.segments) {
                await _supabase
                    .from('stories')
                    .update({'is_archived': true})
                    .eq('id', segment.id);
              }
              _logToTerminal('✅ Story archived successfully');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Story archived successfully')),
              );
              _fetchStories();
            }
          } catch (e) {
            _logToTerminal('❌ Error archiving story: $e');
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
            _logToTerminal('🗑️ Deleting story...');
            try {
              for (final segment in _currentUserStory!.segments) {
                await _supabase.from('stories').delete().eq('id', segment.id);
              }
              _logToTerminal('✅ Story deleted successfully');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Story deleted successfully')),
              );
              _fetchStories();
            } catch (e) {
              _logToTerminal('❌ Error deleting story: $e');
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
