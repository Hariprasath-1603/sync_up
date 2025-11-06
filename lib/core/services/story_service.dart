import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/home/models/story_model.dart';

/// Service for managing stories with Supabase backend
class StoryService {
  final _supabase = Supabase.instance.client;

  /// Upload a story to Supabase
  Future<Map<String, dynamic>> uploadStory({
    required String mediaUrl,
    required String mediaType, // 'image' or 'video'
    String? caption,
    String? mood,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Insert story into database
      final response = await _supabase
          .from('stories')
          .insert({
            'user_id': userId,
            'media_url': mediaUrl,
            'media_type': mediaType,
            'caption': caption,
            'mood': mood,
            'views_count': 0,
            'created_at': DateTime.now().toIso8601String(),
            'expires_at': DateTime.now()
                .add(const Duration(hours: 24))
                .toIso8601String(),
          })
          .select()
          .single();

      // Update user's has_stories flag to true
      await _supabase
          .from('users')
          .update({'has_stories': true})
          .eq('uid', userId);

      return response;
    } catch (e) {
      print('❌ Error uploading story: $e');
      rethrow;
    }
  }

  /// Get active stories (not expired) for a specific user
  Future<List<Map<String, dynamic>>> getUserStories(String userId) async {
    try {
      final response = await _supabase
          .from('stories')
          .select()
          .eq('user_id', userId)
          .gte('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting user stories: $e');
      return [];
    }
  }

  /// Get all active stories from followed users (for feed)
  Stream<List<Story>> getFollowingStories() {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      return _supabase
          .from('stories')
          .stream(primaryKey: ['id'])
          .eq('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .asyncMap((storiesData) async {
            final stories = <Story>[];

            for (final storyData in storiesData) {
              // Get user data for each story
              final userData = await _supabase
                  .from('users')
                  .select('username, photo_url')
                  .eq('uid', storyData['user_id'])
                  .single();

              stories.add(
                Story(
                  imageUrl: storyData['media_url'] ?? '',
                  userName: userData['username'] ?? 'User',
                  userAvatarUrl: userData['photo_url'] ?? '',
                  tag: storyData['mood'] ?? '',
                  postedAt: DateTime.parse(storyData['created_at']),
                  segments: [
                    StorySegment(
                      id: storyData['id'],
                      mediaUrl: storyData['media_url'] ?? '',
                      caption: storyData['caption'],
                      type: storyData['media_type'] == 'video'
                          ? StoryMediaType.video
                          : StoryMediaType.image,
                    ),
                  ],
                ),
              );
            }

            return stories;
          });
    } catch (e) {
      print('❌ Error getting following stories: $e');
      return Stream.value([]);
    }
  }

  /// Get current user's active stories
  Future<List<Map<String, dynamic>>> getMyActiveStories() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      return await getUserStories(userId);
    } catch (e) {
      print('❌ Error getting my stories: $e');
      return [];
    }
  }

  /// Increment view count for a story
  Future<void> incrementStoryViews(String storyId) async {
    try {
      await _supabase.rpc(
        'increment_story_views',
        params: {'story_id': storyId},
      );
    } catch (e) {
      print('❌ Error incrementing story views: $e');
      // Fallback to manual increment
      try {
        final currentStory = await _supabase
            .from('stories')
            .select('views_count')
            .eq('id', storyId)
            .single();

        await _supabase
            .from('stories')
            .update({'views_count': (currentStory['views_count'] ?? 0) + 1})
            .eq('id', storyId);
      } catch (fallbackError) {
        print('❌ Fallback increment also failed: $fallbackError');
      }
    }
  }

  /// Delete a story (manual deletion before 24h expiry)
  Future<void> deleteStory(String storyId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('stories')
          .delete()
          .eq('id', storyId)
          .eq('user_id', userId);

      // Check if user has any remaining stories
      final remainingStories = await getUserStories(userId);
      if (remainingStories.isEmpty) {
        // Update has_stories flag to false
        await _supabase
            .from('users')
            .update({'has_stories': false})
            .eq('uid', userId);
      }
    } catch (e) {
      print('❌ Error deleting story: $e');
      rethrow;
    }
  }

  /// Automatically clean up expired stories (call this periodically)
  Future<void> cleanupExpiredStories() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Delete expired stories
      await _supabase
          .from('stories')
          .delete()
          .eq('user_id', userId)
          .lt('expires_at', DateTime.now().toIso8601String());

      // Check if user has any remaining stories
      final remainingStories = await getUserStories(userId);
      if (remainingStories.isEmpty) {
        await _supabase
            .from('users')
            .update({'has_stories': false})
            .eq('uid', userId);
      }
    } catch (e) {
      print('❌ Error cleaning up expired stories: $e');
    }
  }

  /// Check if current user has active stories
  Future<bool> hasActiveStories() async {
    try {
      final stories = await getMyActiveStories();
      return stories.isNotEmpty;
    } catch (e) {
      print('❌ Error checking active stories: $e');
      return false;
    }
  }

  /// Get story by ID
  Future<Map<String, dynamic>?> getStoryById(String storyId) async {
    try {
      final response = await _supabase
          .from('stories')
          .select()
          .eq('id', storyId)
          .single();

      return response;
    } catch (e) {
      print('❌ Error getting story by ID: $e');
      return null;
    }
  }

  // ==================== STORY INSIGHTS & INTERACTIONS ====================

  /// Add story view tracking
  Future<void> addStoryView(String storyId, String viewerId) async {
    try {
      // Check if already viewed
      final existingView = await _supabase
          .from('story_viewers')
          .select()
          .eq('story_id', storyId)
          .eq('viewer_id', viewerId)
          .maybeSingle();

      if (existingView == null) {
        // Insert new view record
        await _supabase.from('story_viewers').insert({
          'story_id': storyId,
          'viewer_id': viewerId,
          'viewed_at': DateTime.now().toIso8601String(),
        });

        // Increment views count on story
        await incrementStoryViews(storyId);
      }
    } catch (e) {
      print('❌ Error adding story view: $e');
    }
  }

  /// Get list of viewers for a story (with user data)
  Future<List<Map<String, dynamic>>> getStoryViewers(String storyId) async {
    try {
      final viewers = await _supabase
          .from('story_viewers')
          .select('viewer_id, viewed_at, users(username, photo_url)')
          .eq('story_id', storyId)
          .order('viewed_at', ascending: false);

      // Flatten the data structure
      return viewers.map((viewer) {
        final userData = viewer['users'] as Map<String, dynamic>?;
        return {
          'user_id': viewer['viewer_id'],
          'username': userData?['username'] ?? 'Unknown',
          'photo_url': userData?['photo_url'],
          'viewed_at': viewer['viewed_at'],
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting story viewers: $e');
      return [];
    }
  }

  /// Get story analytics
  Future<Map<String, dynamic>> getStoryAnalytics(String storyId) async {
    try {
      // Get total views (count rows)
      final viewersData = await _supabase
          .from('story_viewers')
          .select()
          .eq('story_id', storyId);
      final viewsCount = viewersData.length;

      // Get reactions count
      final reactionsData = await _supabase
          .from('story_reactions')
          .select()
          .eq('story_id', storyId);
      final reactionsCount = reactionsData.length;

      // Get replies count
      final repliesData = await _supabase
          .from('story_replies')
          .select()
          .eq('story_id', storyId);
      final repliesCount = repliesData.length;

      // Get top reactions
      final Map<String, int> emojiCounts = {};
      for (final reaction in reactionsData) {
        final emoji = reaction['emoji'] as String?;
        if (emoji != null) {
          emojiCounts[emoji] = (emojiCounts[emoji] ?? 0) + 1;
        }
      }

      return {
        'total_views': viewsCount,
        'reactions_count': reactionsCount,
        'replies_count': repliesCount,
        'top_reactions': emojiCounts,
        'average_watch_duration': 0.0, // TODO: Implement duration tracking
      };
    } catch (e) {
      print('❌ Error getting story analytics: $e');
      return {
        'total_views': 0,
        'reactions_count': 0,
        'replies_count': 0,
        'top_reactions': <String, int>{},
        'average_watch_duration': 0.0,
      };
    }
  }

  /// Send a reply to a story
  Future<void> sendStoryReply({
    required String storyId,
    required String receiverId,
    required String message,
    String? emoji,
  }) async {
    try {
      final senderId = _supabase.auth.currentUser?.id;
      if (senderId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.from('story_replies').insert({
        'story_id': storyId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': message.isNotEmpty ? message : null,
        'emoji': emoji,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Story reply sent successfully');
    } catch (e) {
      print('❌ Error sending story reply: $e');
      rethrow;
    }
  }

  /// Add emoji reaction to a story
  Future<void> addStoryReaction({
    required String storyId,
    required String emoji,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if user already reacted
      final existingReaction = await _supabase
          .from('story_reactions')
          .select()
          .eq('story_id', storyId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingReaction != null) {
        // Update existing reaction
        await _supabase
            .from('story_reactions')
            .update({
              'emoji': emoji,
              'created_at': DateTime.now().toIso8601String(),
            })
            .eq('story_id', storyId)
            .eq('user_id', userId);
      } else {
        // Insert new reaction
        await _supabase.from('story_reactions').insert({
          'story_id': storyId,
          'user_id': userId,
          'emoji': emoji,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      print('✅ Story reaction added successfully');
    } catch (e) {
      print('❌ Error adding story reaction: $e');
      rethrow;
    }
  }

  /// Get replies for a story (for creator to view)
  Future<List<Map<String, dynamic>>> getStoryReplies(String storyId) async {
    try {
      final replies = await _supabase
          .from('story_replies')
          .select('*, users!sender_id(username, photo_url)')
          .eq('story_id', storyId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(replies);
    } catch (e) {
      print('❌ Error getting story replies: $e');
      return [];
    }
  }

  /// Subscribe to real-time story views
  RealtimeChannel subscribeToStoryViews(
    String storyId,
    Function(List<Map<String, dynamic>>) onViewersUpdate,
  ) {
    final channel = _supabase.channel('story_viewers:$storyId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'story_viewers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'story_id',
            value: storyId,
          ),
          callback: (payload) async {
            // Fetch updated viewers list
            final viewers = await getStoryViewers(storyId);
            onViewersUpdate(viewers);
          },
        )
        .subscribe();

    return channel;
  }

  /// Subscribe to real-time reactions
  RealtimeChannel subscribeToStoryReactions(
    String storyId,
    Function(Map<String, dynamic>) onReactionAdded,
  ) {
    final channel = _supabase.channel('story_reactions:$storyId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'story_reactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'story_id',
            value: storyId,
          ),
          callback: (payload) {
            onReactionAdded(payload.newRecord);
          },
        )
        .subscribe();

    return channel;
  }

  // ==================== STORY ARCHIVE SYSTEM ====================

  /// Automatically archive expired stories (older than 24 hours)
  Future<List<String>> archiveExpiredStories() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Find expired stories for current user
      final expiredStories = await _supabase
          .from('stories')
          .select()
          .eq('user_id', userId)
          .lt('expires_at', DateTime.now().toIso8601String());

      if (expiredStories.isEmpty) {
        print('✅ No expired stories to archive');
        return [];
      }

      final archivedIds = <String>[];

      for (final story in expiredStories) {
        try {
          // Get viewers data
          final viewers = await _supabase
              .from('story_viewers')
              .select()
              .eq('story_id', story['id']);

          // Get reactions data
          final reactions = await _supabase
              .from('story_reactions')
              .select()
              .eq('story_id', story['id']);

          // Insert into archive
          await _supabase.from('story_archive').insert({
            'original_story_id': story['id'],
            'user_id': story['user_id'],
            'media_url': story['media_url'],
            'thumbnail_url': story['thumbnail_url'],
            'media_type': story['media_type'],
            'caption': story['caption'],
            'created_at': story['created_at'],
            'archived_at': DateTime.now().toIso8601String(),
            'viewers': viewers,
            'reactions': reactions,
            'views_count': story['views_count'] ?? 0,
            'restored': false,
          });

          // Delete from active stories
          await _supabase.from('stories').delete().eq('id', story['id']);

          archivedIds.add(story['id'] as String);
          print('✅ Archived story: ${story['id']}');
        } catch (e) {
          print('❌ Error archiving story ${story['id']}: $e');
        }
      }

      // Update user's has_stories flag if no active stories remain
      final remainingStories = await getUserStories(userId);
      if (remainingStories.isEmpty) {
        await _supabase
            .from('users')
            .update({'has_stories': false})
            .eq('uid', userId);
      }

      print('✅ Archived ${archivedIds.length} expired stories');
      return archivedIds;
    } catch (e) {
      print('❌ Error archiving expired stories: $e');
      return [];
    }
  }

  /// Get archived stories for current user
  Future<List<Map<String, dynamic>>> getArchivedStories({
    String? filterType, // 'all', 'image', 'video'
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      var query = _supabase
          .from('story_archive')
          .select()
          .eq('user_id', userId);

      // Apply filter if specified
      if (filterType != null && filterType != 'all') {
        query = query.eq('media_type', filterType);
      }

      final archives = await query.order('archived_at', ascending: false);
      return List<Map<String, dynamic>>.from(archives);
    } catch (e) {
      print('❌ Error getting archived stories: $e');
      return [];
    }
  }

  /// Get single archived story by ID
  Future<Map<String, dynamic>?> getArchivedStoryById(String archiveId) async {
    try {
      final archive = await _supabase
          .from('story_archive')
          .select()
          .eq('id', archiveId)
          .single();

      return archive;
    } catch (e) {
      print('❌ Error getting archived story: $e');
      return null;
    }
  }

  /// Restore archived story back to active stories
  Future<String?> restoreStory(String archiveId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get archived story
      final archive = await getArchivedStoryById(archiveId);
      if (archive == null) {
        throw Exception('Archived story not found');
      }

      // Verify ownership
      if (archive['user_id'] != userId) {
        throw Exception('Unauthorized: Not your story');
      }

      // Insert back into active stories with new expiration
      final restoredStory = await _supabase
          .from('stories')
          .insert({
            'user_id': archive['user_id'],
            'media_url': archive['media_url'],
            'thumbnail_url': archive['thumbnail_url'],
            'media_type': archive['media_type'],
            'caption': archive['caption'],
            'created_at': DateTime.now().toIso8601String(),
            'expires_at': DateTime.now()
                .add(const Duration(hours: 24))
                .toIso8601String(),
            'views_count': 0, // Reset view count for restored story
            'is_archived': false,
          })
          .select()
          .single();

      // Mark as restored in archive
      await _supabase
          .from('story_archive')
          .update({'restored': true})
          .eq('id', archiveId);

      // Update user's has_stories flag
      await _supabase
          .from('users')
          .update({'has_stories': true})
          .eq('uid', userId);

      print('✅ Story restored successfully');
      return restoredStory['id'] as String;
    } catch (e) {
      print('❌ Error restoring story: $e');
      rethrow;
    }
  }

  /// Delete archived story permanently
  Future<void> deleteArchivedStory(String archiveId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Verify ownership before deletion
      final archive = await getArchivedStoryById(archiveId);
      if (archive == null) {
        throw Exception('Archived story not found');
      }

      if (archive['user_id'] != userId) {
        throw Exception('Unauthorized: Not your story');
      }

      // Delete from archive
      await _supabase.from('story_archive').delete().eq('id', archiveId);

      print('✅ Archived story deleted permanently');
    } catch (e) {
      print('❌ Error deleting archived story: $e');
      rethrow;
    }
  }

  /// Clear all archived stories for current user
  Future<void> clearAllArchivedStories() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.from('story_archive').delete().eq('user_id', userId);

      print('✅ All archived stories cleared');
    } catch (e) {
      print('❌ Error clearing archived stories: $e');
      rethrow;
    }
  }

  /// Get archive statistics
  Future<Map<String, int>> getArchiveStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final archives = await _supabase
          .from('story_archive')
          .select()
          .eq('user_id', userId);

      final stats = {
        'total': archives.length,
        'images': archives.where((a) => a['media_type'] == 'image').length,
        'videos': archives.where((a) => a['media_type'] == 'video').length,
        'restored': archives.where((a) => a['restored'] == true).length,
      };

      return stats;
    } catch (e) {
      print('❌ Error getting archive stats: $e');
      return {'total': 0, 'images': 0, 'videos': 0, 'restored': 0};
    }
  }

  /// Check if user has auto-archive enabled (from settings)
  Future<bool> isAutoArchiveEnabled() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return true; // Default to enabled

      final settings = await _supabase
          .from('user_settings')
          .select('auto_archive')
          .eq('user_id', userId)
          .maybeSingle();

      return settings?['auto_archive'] ?? true;
    } catch (e) {
      print('❌ Error checking auto-archive setting: $e');
      return true; // Default to enabled on error
    }
  }

  /// Update auto-archive setting
  Future<void> setAutoArchive(bool enabled) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.from('user_settings').upsert({
        'user_id': userId,
        'auto_archive': enabled,
      });

      print('✅ Auto-archive setting updated: $enabled');
    } catch (e) {
      print('❌ Error updating auto-archive setting: $e');
      rethrow;
    }
  }
}
