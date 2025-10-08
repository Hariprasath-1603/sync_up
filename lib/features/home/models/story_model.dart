class Story {
  final String imageUrl;
  final String userName;
  final String userAvatarUrl;
  final String tag;
  final String? viewers; // Nullable for non-live stories

  Story({
    required this.imageUrl,
    required this.userName,
    required this.userAvatarUrl,
    required this.tag,
    this.viewers,
  });
}