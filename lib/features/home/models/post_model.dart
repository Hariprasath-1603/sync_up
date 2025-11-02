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
  });
}
