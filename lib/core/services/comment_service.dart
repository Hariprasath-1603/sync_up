import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

/// Model for a comment
class Comment {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String? userAvatar;
  final String text;
  final DateTime timestamp;
  final int likes;
  final bool isLiked;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.text,
    required this.timestamp,
    this.likes = 0,
    this.isLiked = false,
    this.replies = const [],
  });

  factory Comment.fromMap(Map<String, dynamic> map, String id) {
    return Comment(
      id: id,
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      userAvatar: map['userAvatar'],
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: map['likes'] ?? 0,
      isLiked: map['isLiked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
    };
  }
}

/// Service for handling comment operations
class CommentService {
  static final CommentService _instance = CommentService._internal();
  factory CommentService() => _instance;
  CommentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Post a comment
  Future<Comment?> postComment({
    required String postId,
    required String text,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return null;

    try {
      final commentData = {
        'postId': postId,
        'userId': user.uid,
        'username': user.username,
        'userAvatar': user.photoURL,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
      };

      // Add comment to Firestore
      final docRef = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add(commentData);

      // Increment comment count
      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(1),
      });

      // Return the created comment
      return Comment(
        id: docRef.id,
        postId: postId,
        userId: user.uid,
        username: user.username,
        userAvatar: user.photoURL,
        text: text,
        timestamp: DateTime.now(),
        likes: 0,
        isLiked: false,
      );
    } catch (e) {
      print('Error posting comment: $e');
      return null;
    }
  }

  /// Get comments for a post
  Stream<List<Comment>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Comment.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  /// Like a comment
  Future<bool> likeComment(String postId, String commentId) async {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    try {
      // Add to comment's likes collection
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .collection('likes')
          .doc(userId)
          .set({'userId': userId, 'timestamp': FieldValue.serverTimestamp()});

      // Increment like count
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .update({'likes': FieldValue.increment(1)});

      return true;
    } catch (e) {
      print('Error liking comment: $e');
      return false;
    }
  }

  /// Unlike a comment
  Future<bool> unlikeComment(String postId, String commentId) async {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    try {
      // Remove from comment's likes collection
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .collection('likes')
          .doc(userId)
          .delete();

      // Decrement like count
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .update({'likes': FieldValue.increment(-1)});

      return true;
    } catch (e) {
      print('Error unliking comment: $e');
      return false;
    }
  }

  /// Delete a comment
  Future<bool> deleteComment(String postId, String commentId) async {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    try {
      // Delete comment document
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // Decrement comment count
      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  /// Reply to a comment
  Future<Comment?> replyToComment({
    required String postId,
    required String commentId,
    required String text,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return null;

    try {
      final replyData = {
        'postId': postId,
        'userId': user.uid,
        'username': user.username,
        'userAvatar': user.photoURL,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
      };

      // Add reply to comment's replies collection
      final docRef = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .add(replyData);

      // Return the created reply
      return Comment(
        id: docRef.id,
        postId: postId,
        userId: user.uid,
        username: user.username,
        userAvatar: user.photoURL,
        text: text,
        timestamp: DateTime.now(),
        likes: 0,
        isLiked: false,
      );
    } catch (e) {
      print('Error posting reply: $e');
      return null;
    }
  }
}
