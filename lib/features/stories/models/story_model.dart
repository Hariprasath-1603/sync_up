/// Represents a user's story collection in the stories bar
class StoryItem {
  final String userId;
  final String username;
  final String userPhotoUrl;
  final List<StorySegment> segments;
  final DateTime lastUpdated;
  final bool isViewed;

  const StoryItem({
    required this.userId,
    required this.username,
    required this.userPhotoUrl,
    required this.segments,
    required this.lastUpdated,
    this.isViewed = false,
  });

  StoryItem copyWith({
    String? userId,
    String? username,
    String? userPhotoUrl,
    List<StorySegment>? segments,
    DateTime? lastUpdated,
    bool? isViewed,
  }) {
    return StoryItem(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      segments: segments ?? this.segments,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isViewed: isViewed ?? this.isViewed,
    );
  }

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    return StoryItem(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      userPhotoUrl: json['user_photo_url'] as String? ?? '',
      segments:
          (json['segments'] as List<dynamic>?)
              ?.map((e) => StorySegment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      isViewed: json['is_viewed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'user_photo_url': userPhotoUrl,
      'segments': segments.map((e) => e.toJson()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
      'is_viewed': isViewed,
    };
  }
}

/// Represents a single story segment (image or video)
class StorySegment {
  final String id;
  final String mediaUrl;
  final String? thumbnailUrl;
  final StoryMediaType mediaType;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int viewsCount;
  final List<String> viewerIds;
  final bool isViewed;

  const StorySegment({
    required this.id,
    required this.mediaUrl,
    this.thumbnailUrl,
    required this.mediaType,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
    this.viewsCount = 0,
    this.viewerIds = const [],
    this.isViewed = false,
  });

  Duration get duration {
    // Videos use their actual duration, images default to 5 seconds
    return mediaType == StoryMediaType.video
        ? const Duration(seconds: 10)
        : const Duration(seconds: 5);
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  StorySegment copyWith({
    String? id,
    String? mediaUrl,
    String? thumbnailUrl,
    StoryMediaType? mediaType,
    String? caption,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? viewsCount,
    List<String>? viewerIds,
    bool? isViewed,
  }) {
    return StorySegment(
      id: id ?? this.id,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      mediaType: mediaType ?? this.mediaType,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewsCount: viewsCount ?? this.viewsCount,
      viewerIds: viewerIds ?? this.viewerIds,
      isViewed: isViewed ?? this.isViewed,
    );
  }

  factory StorySegment.fromJson(Map<String, dynamic> json) {
    return StorySegment(
      id: json['id'] as String,
      mediaUrl: json['media_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      mediaType: StoryMediaType.values.firstWhere(
        (e) => e.name == json['media_type'],
        orElse: () => StoryMediaType.image,
      ),
      caption: json['caption'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      viewsCount: json['views_count'] as int? ?? 0,
      viewerIds:
          (json['viewer_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isViewed: json['is_viewed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'media_type': mediaType.name,
      'caption': caption,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'views_count': viewsCount,
      'viewer_ids': viewerIds,
      'is_viewed': isViewed,
    };
  }
}

/// Media type for story segment
enum StoryMediaType { image, video }

/// Viewer information for story insights
class StoryViewer {
  final String userId;
  final String username;
  final String photoUrl;
  final DateTime viewedAt;

  const StoryViewer({
    required this.userId,
    required this.username,
    required this.photoUrl,
    required this.viewedAt,
  });

  factory StoryViewer.fromJson(Map<String, dynamic> json) {
    return StoryViewer(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      photoUrl: json['photo_url'] as String? ?? '',
      viewedAt: DateTime.parse(json['viewed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'photo_url': photoUrl,
      'viewed_at': viewedAt.toIso8601String(),
    };
  }
}

/// Reply to a story
class StoryReply {
  final String id;
  final String storyId;
  final String senderId;
  final String senderUsername;
  final String senderPhotoUrl;
  final String message;
  final DateTime createdAt;

  const StoryReply({
    required this.id,
    required this.storyId,
    required this.senderId,
    required this.senderUsername,
    required this.senderPhotoUrl,
    required this.message,
    required this.createdAt,
  });

  factory StoryReply.fromJson(Map<String, dynamic> json) {
    return StoryReply(
      id: json['id'] as String,
      storyId: json['story_id'] as String,
      senderId: json['sender_id'] as String,
      senderUsername: json['sender_username'] as String,
      senderPhotoUrl: json['sender_photo_url'] as String? ?? '',
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'story_id': storyId,
      'sender_id': senderId,
      'sender_username': senderUsername,
      'sender_photo_url': senderPhotoUrl,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
