class Post {
  final String id; // Post ID for backend operations
  final String userId; // Post owner's ID
  final String imageUrl;
  final String userName;
  final String userHandle;
  final String userAvatarUrl;
  final String likes;
  final String comments;
  final String shares;
  final String? videoUrl;
  final String? thumbnailUrl;
  final int? videoDuration; // Duration in seconds
  final String? mediaType; // 'image', 'video', 'carousel'

  Post({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.userName,
    required this.userHandle,
    required this.userAvatarUrl,
    required this.likes,
    required this.comments,
    required this.shares,
    this.videoUrl,
    this.thumbnailUrl,
    this.videoDuration,
    this.mediaType,
  });

  bool get isVideo => mediaType == 'video' || videoUrl != null;
}
