enum StoryMediaType { image, video, text, boomerang }

enum StoryAudience { public, friendsOnly, closeFriends, custom }

enum StoryStatus { active, expired, archived, deleted }

class StoryModel {
  final String id;
  final String userId;
  final String username;
  final String? userAvatarUrl;
  final bool isUserVerified;
  final StoryMediaType mediaType;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? caption;
  final double? duration; // For videos, in seconds
  final StoryAudience audience;
  final String? location;
  final List<String> mentions;
  final List<String> hashtags;
  final List<StoryInteraction> interactions;
  final DateTime createdAt;
  final DateTime expiresAt;
  final StoryStatus status;

  // Privacy & engagement
  final bool allowReplies;
  final bool allowSharing;
  final bool addedToHighlights;

  // Analytics
  final int viewCount;
  final int reactionCount;
  final int replyCount;

  // Creative elements (stored as JSON in real app)
  final Map<String, dynamic>? textLayers;
  final Map<String, dynamic>? stickerLayers;
  final Map<String, dynamic>? filters;
  final String? musicTrack;

  StoryModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userAvatarUrl,
    this.isUserVerified = false,
    required this.mediaType,
    this.mediaUrl,
    this.thumbnailUrl,
    this.caption,
    this.duration,
    this.audience = StoryAudience.public,
    this.location,
    this.mentions = const [],
    this.hashtags = const [],
    this.interactions = const [],
    required this.createdAt,
    required this.expiresAt,
    this.status = StoryStatus.active,
    this.allowReplies = true,
    this.allowSharing = true,
    this.addedToHighlights = false,
    this.viewCount = 0,
    this.reactionCount = 0,
    this.replyCount = 0,
    this.textLayers,
    this.stickerLayers,
    this.filters,
    this.musicTrack,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isSeen => false; // TODO: Check against user's view history

  StoryModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? userAvatarUrl,
    bool? isUserVerified,
    StoryMediaType? mediaType,
    String? mediaUrl,
    String? thumbnailUrl,
    String? caption,
    double? duration,
    StoryAudience? audience,
    String? location,
    List<String>? mentions,
    List<String>? hashtags,
    List<StoryInteraction>? interactions,
    DateTime? createdAt,
    DateTime? expiresAt,
    StoryStatus? status,
    bool? allowReplies,
    bool? allowSharing,
    bool? addedToHighlights,
    int? viewCount,
    int? reactionCount,
    int? replyCount,
    Map<String, dynamic>? textLayers,
    Map<String, dynamic>? stickerLayers,
    Map<String, dynamic>? filters,
    String? musicTrack,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      isUserVerified: isUserVerified ?? this.isUserVerified,
      mediaType: mediaType ?? this.mediaType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      duration: duration ?? this.duration,
      audience: audience ?? this.audience,
      location: location ?? this.location,
      mentions: mentions ?? this.mentions,
      hashtags: hashtags ?? this.hashtags,
      interactions: interactions ?? this.interactions,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      allowReplies: allowReplies ?? this.allowReplies,
      allowSharing: allowSharing ?? this.allowSharing,
      addedToHighlights: addedToHighlights ?? this.addedToHighlights,
      viewCount: viewCount ?? this.viewCount,
      reactionCount: reactionCount ?? this.reactionCount,
      replyCount: replyCount ?? this.replyCount,
      textLayers: textLayers ?? this.textLayers,
      stickerLayers: stickerLayers ?? this.stickerLayers,
      filters: filters ?? this.filters,
      musicTrack: musicTrack ?? this.musicTrack,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'user_avatar_url': userAvatarUrl,
      'is_user_verified': isUserVerified,
      'media_type': mediaType.name,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'caption': caption,
      'duration': duration,
      'audience': audience.name,
      'location': location,
      'mentions': mentions,
      'hashtags': hashtags,
      'interactions': interactions.map((i) => i.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'status': status.name,
      'allow_replies': allowReplies,
      'allow_sharing': allowSharing,
      'added_to_highlights': addedToHighlights,
      'view_count': viewCount,
      'reaction_count': reactionCount,
      'reply_count': replyCount,
      'text_layers': textLayers,
      'sticker_layers': stickerLayers,
      'filters': filters,
      'music_track': musicTrack,
    };
  }

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'],
      userId: json['user_id'],
      username: json['username'],
      userAvatarUrl: json['user_avatar_url'],
      isUserVerified: json['is_user_verified'] ?? false,
      mediaType: StoryMediaType.values.firstWhere(
        (e) => e.name == json['media_type'],
        orElse: () => StoryMediaType.image,
      ),
      mediaUrl: json['media_url'],
      thumbnailUrl: json['thumbnail_url'],
      caption: json['caption'],
      duration: json['duration']?.toDouble(),
      audience: StoryAudience.values.firstWhere(
        (e) => e.name == json['audience'],
        orElse: () => StoryAudience.public,
      ),
      location: json['location'],
      mentions: List<String>.from(json['mentions'] ?? []),
      hashtags: List<String>.from(json['hashtags'] ?? []),
      interactions:
          (json['interactions'] as List?)
              ?.map((i) => StoryInteraction.fromJson(i))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      status: StoryStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => StoryStatus.active,
      ),
      allowReplies: json['allow_replies'] ?? true,
      allowSharing: json['allow_sharing'] ?? true,
      addedToHighlights: json['added_to_highlights'] ?? false,
      viewCount: json['view_count'] ?? 0,
      reactionCount: json['reaction_count'] ?? 0,
      replyCount: json['reply_count'] ?? 0,
      textLayers: json['text_layers'],
      stickerLayers: json['sticker_layers'],
      filters: json['filters'],
      musicTrack: json['music_track'],
    );
  }
}

enum InteractionType { poll, question, quiz, emojiSlider, countdown, link }

class StoryInteraction {
  final String id;
  final InteractionType type;
  final Map<String, dynamic> data;
  final int responseCount;

  StoryInteraction({
    required this.id,
    required this.type,
    required this.data,
    this.responseCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'data': data,
      'response_count': responseCount,
    };
  }

  factory StoryInteraction.fromJson(Map<String, dynamic> json) {
    return StoryInteraction(
      id: json['id'],
      type: InteractionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InteractionType.poll,
      ),
      data: json['data'],
      responseCount: json['response_count'] ?? 0,
    );
  }
}

class StoryView {
  final String id;
  final String storyId;
  final String viewerId;
  final String viewerUsername;
  final String? viewerAvatarUrl;
  final DateTime viewedAt;

  StoryView({
    required this.id,
    required this.storyId,
    required this.viewerId,
    required this.viewerUsername,
    this.viewerAvatarUrl,
    required this.viewedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'story_id': storyId,
      'viewer_id': viewerId,
      'viewer_username': viewerUsername,
      'viewer_avatar_url': viewerAvatarUrl,
      'viewed_at': viewedAt.toIso8601String(),
    };
  }

  factory StoryView.fromJson(Map<String, dynamic> json) {
    return StoryView(
      id: json['id'],
      storyId: json['story_id'],
      viewerId: json['viewer_id'],
      viewerUsername: json['viewer_username'],
      viewerAvatarUrl: json['viewer_avatar_url'],
      viewedAt: DateTime.parse(json['viewed_at']),
    );
  }
}

class StoryReaction {
  final String id;
  final String storyId;
  final String userId;
  final String username;
  final String? userAvatarUrl;
  final String emoji;
  final DateTime createdAt;

  StoryReaction({
    required this.id,
    required this.storyId,
    required this.userId,
    required this.username,
    this.userAvatarUrl,
    required this.emoji,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'story_id': storyId,
      'user_id': userId,
      'username': username,
      'user_avatar_url': userAvatarUrl,
      'emoji': emoji,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StoryReaction.fromJson(Map<String, dynamic> json) {
    return StoryReaction(
      id: json['id'],
      storyId: json['story_id'],
      userId: json['user_id'],
      username: json['username'],
      userAvatarUrl: json['user_avatar_url'],
      emoji: json['emoji'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Highlight {
  final String id;
  final String userId;
  final String title;
  final String? coverUrl;
  final List<String> storyIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Highlight({
    required this.id,
    required this.userId,
    required this.title,
    this.coverUrl,
    required this.storyIds,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'cover_url': coverUrl,
      'story_ids': storyIds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      coverUrl: json['cover_url'],
      storyIds: List<String>.from(json['story_ids'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
