/// Represents a single piece of media inside a story timeline.
class StorySegment {
  StorySegment({
    required this.id,
    required this.mediaUrl,
    this.caption,
    this.duration = const Duration(seconds: 5),
    this.type = StoryMediaType.image,
  });

  final String id;
  final String mediaUrl;
  final String? caption;
  final Duration duration;
  final StoryMediaType type;
}

enum StoryMediaType { image, video }

class Story {
  Story({
    required this.imageUrl,
    required this.userName,
    required this.userAvatarUrl,
    required this.tag,
    this.viewers,
    List<StorySegment>? segments,
    DateTime? postedAt,
  }) : segments =
           segments ??
           [
             StorySegment(
               id: 'segment-${DateTime.now().microsecondsSinceEpoch}',
               mediaUrl: imageUrl,
             ),
           ],
       postedAt = postedAt ?? DateTime.now();

  final String imageUrl;
  final String userName;
  final String userAvatarUrl;
  final String tag;
  final String? viewers; // Nullable for non-live stories
  final List<StorySegment> segments;
  final DateTime postedAt;
}
