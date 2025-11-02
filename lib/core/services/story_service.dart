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
}
