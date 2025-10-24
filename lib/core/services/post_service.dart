import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

/// Service for handling post-related operations
class PostService {
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;
  PostService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Like a post
  Future<bool> likePost(String postId) async {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    try {
      // Add to post's likes collection
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .set({'userId': userId, 'timestamp': FieldValue.serverTimestamp()});

      // Increment like count
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      print('Error liking post: $e');
      return false;
    }
  }

  /// Unlike a post
  Future<bool> unlikePost(String postId) async {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    try {
      // Remove from post's likes collection
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .delete();

      // Decrement like count
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      print('Error unliking post: $e');
      return false;
    }
  }

  /// Save/bookmark a post
  Future<bool> savePost(String postId) async {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    try {
      // Add to user's saved posts collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .doc(postId)
          .set({'postId': postId, 'timestamp': FieldValue.serverTimestamp()});

      // Increment save count
      await _firestore.collection('posts').doc(postId).update({
        'saves': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      print('Error saving post: $e');
      return false;
    }
  }

  /// Unsave/unbookmark a post
  Future<bool> unsavePost(String postId) async {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    try {
      // Remove from user's saved posts collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .doc(postId)
          .delete();

      // Decrement save count
      await _firestore.collection('posts').doc(postId).update({
        'saves': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      print('Error unsaving post: $e');
      return false;
    }
  }

  /// Check if post is liked by current user
  Future<bool> isPostLiked(String postId) async {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    try {
      final doc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking if post is liked: $e');
      return false;
    }
  }

  /// Check if post is saved by current user
  Future<bool> isPostSaved(String postId) async {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .doc(postId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking if post is saved: $e');
      return false;
    }
  }

  /// Delete a post (owner only)
  Future<bool> deletePost(String postId, String postOwnerId) async {
    final userId = _authService.currentUserId;
    if (userId == null || userId != postOwnerId) return false;

    try {
      // Delete post document
      await _firestore.collection('posts').doc(postId).delete();

      // TODO: Delete associated media from storage
      // TODO: Delete subcollections (likes, comments, etc.)

      // Decrement user's posts count
      await _firestore.collection('users').doc(userId).update({
        'postsCount': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  /// Update post caption
  Future<bool> updatePostCaption(String postId, String newCaption) async {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    try {
      await _firestore.collection('posts').doc(postId).update({
        'caption': newCaption,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating post caption: $e');
      return false;
    }
  }

  /// Archive a post
  Future<bool> archivePost(String postId) async {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    try {
      await _firestore.collection('posts').doc(postId).update({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error archiving post: $e');
      return false;
    }
  }

  /// Unarchive a post
  Future<bool> unarchivePost(String postId) async {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    try {
      await _firestore.collection('posts').doc(postId).update({
        'isArchived': false,
        'archivedAt': null,
      });

      return true;
    } catch (e) {
      print('Error unarchiving post: $e');
      return false;
    }
  }

  /// Pin a post to profile
  Future<bool> pinPost(String postId) async {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    try {
      await _firestore.collection('posts').doc(postId).update({
        'isPinned': true,
        'pinnedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error pinning post: $e');
      return false;
    }
  }

  /// Unpin a post from profile
  Future<bool> unpinPost(String postId) async {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    try {
      await _firestore.collection('posts').doc(postId).update({
        'isPinned': false,
        'pinnedAt': null,
      });

      return true;
    } catch (e) {
      print('Error unpinning post: $e');
      return false;
    }
  }

  /// Report a post
  Future<bool> reportPost({
    required String postId,
    required String reason,
    String? description,
  }) async {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    try {
      await _firestore.collection('reports').add({
        'postId': postId,
        'reportedBy': userId,
        'reason': reason,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'type': 'post',
      });

      return true;
    } catch (e) {
      print('Error reporting post: $e');
      return false;
    }
  }

  /// Block a user
  Future<bool> blockUser(String userId) async {
    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) return false;

    try {
      // Add to blocked users collection
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(userId)
          .set({'userId': userId, 'timestamp': FieldValue.serverTimestamp()});

      // Unfollow if following
      await _authService.unfollowUser(userId);

      return true;
    } catch (e) {
      print('Error blocking user: $e');
      return false;
    }
  }

  /// Get post link
  String getPostLink(String postId) {
    // TODO: Use actual app domain and deep link structure
    return 'https://syncup.app/post/$postId';
  }
}
