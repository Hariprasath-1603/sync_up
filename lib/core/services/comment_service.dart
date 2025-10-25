import 'package:supabase_flutter/supabase_flutter.dart';

/// Comment Model
class Comment {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String? userAvatar;
  final String text;
  final DateTime timestamp;
  final int likes;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.text,
    required this.timestamp,
    this.likes = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'username': username,
      'user_avatar': userAvatar,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'likes': likes,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] ?? '',
      postId: map['post_id'] ?? '',
      userId: map['user_id'] ?? '',
      username: map['username'] ?? '',
      userAvatar: map['user_avatar'],
      text: map['text'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
      likes: map['likes'] ?? 0,
    );
  }
}

/// Simplified CommentService - Firestore features temporarily disabled
/// TODO: Full migration from Firestore to Supabase pending
class CommentService {
  static final CommentService _instance = CommentService._internal();
  factory CommentService() => _instance;
  CommentService._internal();

  // ignore: unused_field
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stub methods to prevent compilation errors
  Future<void> addComment(String postId, String text) async {
    print('TODO: Implement add comment with Supabase');
    // TODO: Implement with Supabase
  }

  Future<List<Comment>> getComments(String postId) async {
    print('TODO: Implement get comments with Supabase');
    return []; // TODO: Implement with Supabase
  }

  Future<void> deleteComment(String commentId, String postId) async {
    print('TODO: Implement delete comment with Supabase');
    // TODO: Implement with Supabase
  }

  Future<void> likeComment(String commentId, String postId) async {
    print('TODO: Implement like comment with Supabase');
    // TODO: Implement with Supabase
  }
}
