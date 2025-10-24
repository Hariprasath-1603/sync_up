import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/profile/models/post_model.dart';
import 'auth_service.dart';

/// Service for fetching posts from Firestore
class PostFetchService {
  static final PostFetchService _instance = PostFetchService._internal();
  factory PostFetchService() => _instance;
  PostFetchService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Fetch posts for home feed (For You)
  Stream<List<PostModel>> getForYouPosts({int limit = 20}) {
    return _firestore
        .collection('posts')
        .where('isArchived', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return _postModelFromFirestore(doc);
          }).toList();
        });
  }

  /// Fetch posts from users the current user follows
  Stream<List<PostModel>> getFollowingPosts({int limit = 20}) {
    final currentUser = _authService.currentUser;
    if (currentUser == null || currentUser.following.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('posts')
        .where('userId', whereIn: currentUser.following)
        .where('isArchived', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return _postModelFromFirestore(doc);
          }).toList();
        });
  }

  /// Fetch posts for a specific user (profile page)
  Stream<List<PostModel>> getUserPosts(String userId, {int limit = 50}) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .where('isArchived', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return _postModelFromFirestore(doc);
          }).toList();
        });
  }

  /// Fetch explore/trending posts
  Stream<List<PostModel>> getExplorePosts({int limit = 30}) {
    return _firestore
        .collection('posts')
        .where('isArchived', isEqualTo: false)
        .orderBy('views', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return _postModelFromFirestore(doc);
          }).toList();
        });
  }

  /// Fetch a single post by ID
  Future<PostModel?> getPostById(String postId) async {
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      if (!doc.exists) return null;
      return _postModelFromFirestore(doc);
    } catch (e) {
      print('Error fetching post: $e');
      return null;
    }
  }

  /// Fetch saved posts for current user
  Stream<List<PostModel>> getSavedPosts() async* {
    final userId = _authService.currentUserId;
    if (userId == null) {
      yield [];
      return;
    }

    await for (final savedSnapshot
        in _firestore
            .collection('users')
            .doc(userId)
            .collection('savedPosts')
            .orderBy('timestamp', descending: true)
            .snapshots()) {
      final postIds = savedSnapshot.docs.map((doc) => doc.id).toList();

      if (postIds.isEmpty) {
        yield [];
        continue;
      }

      // Fetch posts in batches (Firestore 'in' query limit is 10)
      final posts = <PostModel>[];
      for (var i = 0; i < postIds.length; i += 10) {
        final batch = postIds.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection('posts')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        posts.addAll(snapshot.docs.map((doc) => _postModelFromFirestore(doc)));
      }

      yield posts;
    }
  }

  /// Search posts by caption or tags
  Stream<List<PostModel>> searchPosts(String query, {int limit = 20}) {
    if (query.isEmpty) {
      return Stream.value([]);
    }

    // For better search, implement Algolia or similar
    // This is a basic implementation
    return _firestore
        .collection('posts')
        .where('isArchived', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(limit * 3) // Get more to filter client-side
        .snapshots()
        .map((snapshot) {
          final allPosts = snapshot.docs.map((doc) {
            return _postModelFromFirestore(doc);
          }).toList();

          // Filter by caption or username containing query
          final filtered = allPosts.where((post) {
            final lowerQuery = query.toLowerCase();
            return post.caption.toLowerCase().contains(lowerQuery) ||
                post.username.toLowerCase().contains(lowerQuery) ||
                post.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
          }).toList();

          return filtered.take(limit).toList();
        });
  }

  /// Check if current user liked a post
  Future<bool> isPostLikedByCurrentUser(String postId) async {
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
      return false;
    }
  }

  /// Check if current user saved a post
  Future<bool> isPostSavedByCurrentUser(String postId) async {
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
      return false;
    }
  }

  /// Convert Firestore document to PostModel
  PostModel _postModelFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final currentUserId = _authService.currentUserId;

    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: _parsePostType(data['type']),
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      username: data['username'] ?? '',
      userAvatar: data['userAvatar'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      caption: data['caption'] ?? '',
      location: data['location'],
      musicName: data['musicName'],
      musicArtist: data['musicArtist'],
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      shares: data['shares'] ?? 0,
      saves: data['saves'] ?? 0,
      views: data['views'] ?? 0,
      isLiked: false, // Will be updated separately
      isSaved: false, // Will be updated separately
      isFollowing:
          data['userId'] != currentUserId &&
          (_authService.currentUser?.following.contains(data['userId']) ??
              false),
      commentsEnabled: data['commentsEnabled'] ?? true,
      isPinned: data['isPinned'] ?? false,
      isArchived: data['isArchived'] ?? false,
      hideLikeCount: data['hideLikeCount'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  /// Parse post type from string
  PostType _parsePostType(String? type) {
    switch (type) {
      case 'video':
        return PostType.video;
      case 'carousel':
        return PostType.carousel;
      case 'reel':
        return PostType.reel;
      default:
        return PostType.image;
    }
  }

  /// Create a new post
  Future<String?> createPost({
    required PostType type,
    required List<String> mediaUrls,
    required String thumbnailUrl,
    String caption = '',
    String? location,
    String? musicName,
    String? musicArtist,
    List<String> tags = const [],
  }) async {
    final user = _authService.currentUser;
    if (user == null) return null;

    try {
      final postData = {
        'userId': user.uid,
        'username': user.username,
        'userAvatar': user.photoURL ?? '',
        'type': type.toString().split('.').last,
        'mediaUrls': mediaUrls,
        'thumbnailUrl': thumbnailUrl,
        'caption': caption,
        'location': location,
        'musicName': musicName,
        'musicArtist': musicArtist,
        'tags': tags,
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'saves': 0,
        'views': 0,
        'commentsEnabled': true,
        'isPinned': false,
        'isArchived': false,
        'hideLikeCount': false,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('posts').add(postData);

      // Update user's posts count
      await _firestore.collection('users').doc(user.uid).update({
        'postsCount': FieldValue.increment(1),
      });

      return docRef.id;
    } catch (e) {
      print('Error creating post: $e');
      return null;
    }
  }
}
