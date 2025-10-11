enum LiveStreamStatus { scheduled, live, ended, archived }

enum MonetizationType { none, tips, ticket, subscription }

enum StreamPrivacy { public, friendsOnly, private, paid }

class LiveStreamModel {
  final String id;
  final String hostId;
  final String hostUsername;
  final String? hostAvatarUrl;
  final bool isHostVerified;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final String? category;
  final List<String> tags;
  final LiveStreamStatus status;
  final StreamPrivacy privacy;
  final MonetizationType monetizationType;
  final double? ticketPrice;

  // Streaming URLs
  final String? ingestUrl;
  final String? playbackUrl;
  final String? streamKey;

  // Timestamps
  final DateTime? scheduledFor;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;

  // Stats
  final int viewerCount;
  final int totalViews;
  final int likeCount;
  final int commentCount;
  final double totalTips;

  // Settings
  final bool allowComments;
  final bool allowReactions;
  final bool allowGuestRequests;
  final bool isRecording;
  final List<String> allowedViewerIds;
  final List<String> mutedUserIds;
  final List<String> blockedUserIds;

  // VOD
  final String? vodUrl;
  final int? vodDuration;

  LiveStreamModel({
    required this.id,
    required this.hostId,
    required this.hostUsername,
    this.hostAvatarUrl,
    this.isHostVerified = false,
    required this.title,
    this.description,
    this.coverImageUrl,
    this.category,
    this.tags = const [],
    this.status = LiveStreamStatus.scheduled,
    this.privacy = StreamPrivacy.public,
    this.monetizationType = MonetizationType.none,
    this.ticketPrice,
    this.ingestUrl,
    this.playbackUrl,
    this.streamKey,
    this.scheduledFor,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
    this.viewerCount = 0,
    this.totalViews = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.totalTips = 0.0,
    this.allowComments = true,
    this.allowReactions = true,
    this.allowGuestRequests = true,
    this.isRecording = true,
    this.allowedViewerIds = const [],
    this.mutedUserIds = const [],
    this.blockedUserIds = const [],
    this.vodUrl,
    this.vodDuration,
  });

  LiveStreamModel copyWith({
    String? id,
    String? hostId,
    String? hostUsername,
    String? hostAvatarUrl,
    bool? isHostVerified,
    String? title,
    String? description,
    String? coverImageUrl,
    String? category,
    List<String>? tags,
    LiveStreamStatus? status,
    StreamPrivacy? privacy,
    MonetizationType? monetizationType,
    double? ticketPrice,
    String? ingestUrl,
    String? playbackUrl,
    String? streamKey,
    DateTime? scheduledFor,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? createdAt,
    int? viewerCount,
    int? totalViews,
    int? likeCount,
    int? commentCount,
    double? totalTips,
    bool? allowComments,
    bool? allowReactions,
    bool? allowGuestRequests,
    bool? isRecording,
    List<String>? allowedViewerIds,
    List<String>? mutedUserIds,
    List<String>? blockedUserIds,
    String? vodUrl,
    int? vodDuration,
  }) {
    return LiveStreamModel(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      hostUsername: hostUsername ?? this.hostUsername,
      hostAvatarUrl: hostAvatarUrl ?? this.hostAvatarUrl,
      isHostVerified: isHostVerified ?? this.isHostVerified,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      privacy: privacy ?? this.privacy,
      monetizationType: monetizationType ?? this.monetizationType,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      ingestUrl: ingestUrl ?? this.ingestUrl,
      playbackUrl: playbackUrl ?? this.playbackUrl,
      streamKey: streamKey ?? this.streamKey,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
      viewerCount: viewerCount ?? this.viewerCount,
      totalViews: totalViews ?? this.totalViews,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      totalTips: totalTips ?? this.totalTips,
      allowComments: allowComments ?? this.allowComments,
      allowReactions: allowReactions ?? this.allowReactions,
      allowGuestRequests: allowGuestRequests ?? this.allowGuestRequests,
      isRecording: isRecording ?? this.isRecording,
      allowedViewerIds: allowedViewerIds ?? this.allowedViewerIds,
      mutedUserIds: mutedUserIds ?? this.mutedUserIds,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
      vodUrl: vodUrl ?? this.vodUrl,
      vodDuration: vodDuration ?? this.vodDuration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'host_id': hostId,
      'host_username': hostUsername,
      'host_avatar_url': hostAvatarUrl,
      'is_host_verified': isHostVerified,
      'title': title,
      'description': description,
      'cover_image_url': coverImageUrl,
      'category': category,
      'tags': tags,
      'status': status.name,
      'privacy': privacy.name,
      'monetization_type': monetizationType.name,
      'ticket_price': ticketPrice,
      'ingest_url': ingestUrl,
      'playback_url': playbackUrl,
      'stream_key': streamKey,
      'scheduled_for': scheduledFor?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'viewer_count': viewerCount,
      'total_views': totalViews,
      'like_count': likeCount,
      'comment_count': commentCount,
      'total_tips': totalTips,
      'allow_comments': allowComments,
      'allow_reactions': allowReactions,
      'allow_guest_requests': allowGuestRequests,
      'is_recording': isRecording,
      'allowed_viewer_ids': allowedViewerIds,
      'muted_user_ids': mutedUserIds,
      'blocked_user_ids': blockedUserIds,
      'vod_url': vodUrl,
      'vod_duration': vodDuration,
    };
  }

  factory LiveStreamModel.fromJson(Map<String, dynamic> json) {
    return LiveStreamModel(
      id: json['id'],
      hostId: json['host_id'],
      hostUsername: json['host_username'],
      hostAvatarUrl: json['host_avatar_url'],
      isHostVerified: json['is_host_verified'] ?? false,
      title: json['title'],
      description: json['description'],
      coverImageUrl: json['cover_image_url'],
      category: json['category'],
      tags: List<String>.from(json['tags'] ?? []),
      status: LiveStreamStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LiveStreamStatus.scheduled,
      ),
      privacy: StreamPrivacy.values.firstWhere(
        (e) => e.name == json['privacy'],
        orElse: () => StreamPrivacy.public,
      ),
      monetizationType: MonetizationType.values.firstWhere(
        (e) => e.name == json['monetization_type'],
        orElse: () => MonetizationType.none,
      ),
      ticketPrice: json['ticket_price']?.toDouble(),
      ingestUrl: json['ingest_url'],
      playbackUrl: json['playback_url'],
      streamKey: json['stream_key'],
      scheduledFor: json['scheduled_for'] != null
          ? DateTime.parse(json['scheduled_for'])
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      viewerCount: json['viewer_count'] ?? 0,
      totalViews: json['total_views'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      totalTips: (json['total_tips'] ?? 0.0).toDouble(),
      allowComments: json['allow_comments'] ?? true,
      allowReactions: json['allow_reactions'] ?? true,
      allowGuestRequests: json['allow_guest_requests'] ?? true,
      isRecording: json['is_recording'] ?? true,
      allowedViewerIds: List<String>.from(json['allowed_viewer_ids'] ?? []),
      mutedUserIds: List<String>.from(json['muted_user_ids'] ?? []),
      blockedUserIds: List<String>.from(json['blocked_user_ids'] ?? []),
      vodUrl: json['vod_url'],
      vodDuration: json['vod_duration'],
    );
  }
}
