import 'package:flutter/foundation.dart';
import '../../features/profile/models/post_model.dart';
import '../services/post_fetch_service.dart';
import 'dart:async';

/// Provider for managing posts state
class PostProvider extends ChangeNotifier {
  final PostFetchService _postFetchService = PostFetchService();

  // Home feed posts
  List<PostModel> _forYouPosts = [];
  List<PostModel> _followingPosts = [];

  // Explore posts
  List<PostModel> _explorePosts = [];

  // User-specific posts
  final Map<String, List<PostModel>> _userPostsCache = {};

  // Loading states
  bool _isLoadingForYou = false;
  bool _isLoadingFollowing = false;
  bool _isLoadingExplore = false;

  // Error states
  String? _error;

  // Stream subscriptions
  StreamSubscription<List<PostModel>>? _forYouSubscription;
  StreamSubscription<List<PostModel>>? _followingSubscription;
  StreamSubscription<List<PostModel>>? _exploreSubscription;
  final Map<String, StreamSubscription<List<PostModel>>>
  _userPostsSubscriptions = {};

  // Getters
  List<PostModel> get forYouPosts => _forYouPosts;
  List<PostModel> get followingPosts => _followingPosts;
  List<PostModel> get explorePosts => _explorePosts;
  bool get isLoadingForYou => _isLoadingForYou;
  bool get isLoadingFollowing => _isLoadingFollowing;
  bool get isLoadingExplore => _isLoadingExplore;
  String? get error => _error;

  /// Get cached user posts
  List<PostModel> getUserPosts(String userId) {
    return _userPostsCache[userId] ?? [];
  }

  /// Initialize and load For You posts
  void loadForYouPosts() {
    _isLoadingForYou = true;
    _error = null;
    notifyListeners();

    _forYouSubscription?.cancel();
    _forYouSubscription = _postFetchService.getForYouPosts().listen(
      (posts) {
        _forYouPosts = posts;
        _isLoadingForYou = false;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoadingForYou = false;
        notifyListeners();
      },
    );
  }

  /// Initialize and load Following posts
  void loadFollowingPosts() {
    _isLoadingFollowing = true;
    _error = null;
    notifyListeners();

    _followingSubscription?.cancel();
    _followingSubscription = _postFetchService.getFollowingPosts().listen(
      (posts) {
        _followingPosts = posts;
        _isLoadingFollowing = false;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoadingFollowing = false;
        notifyListeners();
      },
    );
  }

  /// Initialize and load Explore posts
  void loadExplorePosts() {
    _isLoadingExplore = true;
    _error = null;
    notifyListeners();

    _exploreSubscription?.cancel();
    _exploreSubscription = _postFetchService.getExplorePosts().listen(
      (posts) {
        _explorePosts = posts;
        _isLoadingExplore = false;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoadingExplore = false;
        notifyListeners();
      },
    );
  }

  /// Load posts for a specific user
  void loadUserPosts(String userId) {
    _userPostsSubscriptions[userId]?.cancel();
    _userPostsSubscriptions[userId] = _postFetchService
        .getUserPosts(userId)
        .listen(
          (posts) {
            _userPostsCache[userId] = posts;
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            notifyListeners();
          },
        );
  }

  /// Get a single post by ID
  Future<PostModel?> getPostById(String postId) async {
    // Check cache first
    for (final posts in [_forYouPosts, _followingPosts, _explorePosts]) {
      final post = posts.firstWhere(
        (p) => p.id == postId,
        orElse: () => PostModel(
          id: '',
          userId: '',
          type: PostType.image,
          mediaUrls: [],
          thumbnailUrl: '',
          username: '',
          userAvatar: '',
          timestamp: DateTime.now(),
        ),
      );
      if (post.id.isNotEmpty) return post;
    }

    // If not in cache, fetch from Firestore
    return await _postFetchService.getPostById(postId);
  }

  /// Update a post in all cached lists
  void updatePost(PostModel updatedPost) {
    _updatePostInList(_forYouPosts, updatedPost);
    _updatePostInList(_followingPosts, updatedPost);
    _updatePostInList(_explorePosts, updatedPost);

    for (final userId in _userPostsCache.keys) {
      _updatePostInList(_userPostsCache[userId]!, updatedPost);
    }

    notifyListeners();
  }

  void _updatePostInList(List<PostModel> list, PostModel updatedPost) {
    final index = list.indexWhere((p) => p.id == updatedPost.id);
    if (index != -1) {
      list[index] = updatedPost;
    }
  }

  /// Remove a post from all cached lists
  void removePost(String postId) {
    _forYouPosts.removeWhere((p) => p.id == postId);
    _followingPosts.removeWhere((p) => p.id == postId);
    _explorePosts.removeWhere((p) => p.id == postId);

    for (final userId in _userPostsCache.keys) {
      _userPostsCache[userId]!.removeWhere((p) => p.id == postId);
    }

    notifyListeners();
  }

  /// Clear user posts cache
  void clearUserPostsCache(String userId) {
    _userPostsSubscriptions[userId]?.cancel();
    _userPostsSubscriptions.remove(userId);
    _userPostsCache.remove(userId);
    notifyListeners();
  }

  /// Refresh all posts
  void refreshAll() {
    loadForYouPosts();
    loadFollowingPosts();
    loadExplorePosts();
  }

  @override
  void dispose() {
    _forYouSubscription?.cancel();
    _followingSubscription?.cancel();
    _exploreSubscription?.cancel();
    for (final subscription in _userPostsSubscriptions.values) {
      subscription.cancel();
    }
    super.dispose();
  }
}
