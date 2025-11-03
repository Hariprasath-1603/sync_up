import 'package:flutter/material.dart';

/// Type of post content
enum PostType { image, video, carousel, reel }

/// Discovery source for analytics
enum DiscoverySource { feed, profile, explore, hashtag, location, share }

/// Post model with all interaction data
class PostModel {
  PostModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.mediaUrls,
    required this.thumbnailUrl,
    required this.username,
    required this.userAvatar,
    required this.timestamp,
    this.caption = '',
    this.location,
    this.musicName,
    this.musicArtist,
    this.videoUrl,
    this.videoDuration,
    this.mediaType,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.saves = 0,
    this.views = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.isFollowing = false,
    this.commentsEnabled = true,
    this.isPinned = false,
    this.isArchived = false,
    this.hideLikeCount = false,
    this.tags = const [],
  });

  final String id;
  final String userId; // Owner's user ID
  final PostType type;
  final List<String> mediaUrls; // Can have multiple for carousel
  final String thumbnailUrl;
  final String username;
  final String userAvatar;
  final DateTime timestamp;
  final String caption;
  final String? location;
  final String? musicName;
  final String? musicArtist;

  // Video-specific fields
  final String? videoUrl;
  final int? videoDuration; // Duration in seconds
  final String? mediaType; // 'image', 'video', 'carousel'

  int likes;
  int comments;
  int shares;
  int saves;
  int views;
  bool isLiked;
  bool isSaved;
  bool isFollowing;
  bool commentsEnabled;
  bool isPinned;
  bool isArchived;
  bool hideLikeCount;
  final List<String> tags;

  bool get isVideo =>
      type == PostType.video || type == PostType.reel || mediaType == 'video';
  bool get isCarousel => type == PostType.carousel;
  bool get hasMultipleMedia => mediaUrls.length > 1;
  String get videoUrlOrFirst =>
      videoUrl ?? (mediaUrls.isNotEmpty ? mediaUrls.first : '');

  PostModel copyWith({
    String? id,
    String? userId,
    PostType? type,
    List<String>? mediaUrls,
    String? thumbnailUrl,
    String? username,
    String? userAvatar,
    DateTime? timestamp,
    String? caption,
    String? location,
    String? musicName,
    String? musicArtist,
    String? videoUrl,
    int? videoDuration,
    String? mediaType,
    int? likes,
    int? comments,
    int? shares,
    int? saves,
    int? views,
    bool? isLiked,
    bool? isSaved,
    bool? isFollowing,
    bool? commentsEnabled,
    bool? isPinned,
    bool? isArchived,
    bool? hideLikeCount,
    List<String>? tags,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      timestamp: timestamp ?? this.timestamp,
      caption: caption ?? this.caption,
      location: location ?? this.location,
      musicName: musicName ?? this.musicName,
      musicArtist: musicArtist ?? this.musicArtist,
      videoUrl: videoUrl ?? this.videoUrl,
      videoDuration: videoDuration ?? this.videoDuration,
      mediaType: mediaType ?? this.mediaType,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      saves: saves ?? this.saves,
      views: views ?? this.views,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isFollowing: isFollowing ?? this.isFollowing,
      commentsEnabled: commentsEnabled ?? this.commentsEnabled,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      hideLikeCount: hideLikeCount ?? this.hideLikeCount,
      tags: tags ?? this.tags,
    );
  }
}

/// Collection model for saved posts
class PostCollection {
  PostCollection({
    required this.id,
    required this.name,
    required this.postIds,
    this.coverUrl,
    this.isPrivate = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  final List<String> postIds;
  String? coverUrl;
  bool isPrivate;
  final DateTime createdAt;

  int get postCount => postIds.length;

  PostCollection copyWith({
    String? id,
    String? name,
    List<String>? postIds,
    String? coverUrl,
    bool? isPrivate,
    DateTime? createdAt,
  }) {
    return PostCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      postIds: postIds ?? this.postIds,
      coverUrl: coverUrl ?? this.coverUrl,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Post insights/analytics data
class PostInsights {
  PostInsights({
    required this.postId,
    required this.views,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.saves,
    required this.reach,
    required this.averageViewTime,
    required this.discoverySources,
    this.engagementRate = 0.0,
    this.viewsByDay = const {},
    this.likesByDay = const {},
  });

  final String postId;
  final int views;
  final int likes;
  final int comments;
  final int shares;
  final int saves;
  final int reach;
  final Duration averageViewTime;
  final Map<DiscoverySource, int> discoverySources;
  final double engagementRate;
  final Map<DateTime, int> viewsByDay;
  final Map<DateTime, int> likesByDay;

  int get totalEngagements => likes + comments + shares + saves;

  double calculateEngagementRate() {
    if (reach == 0) return 0.0;
    return (totalEngagements / reach) * 100;
  }

  String get topDiscoverySource {
    if (discoverySources.isEmpty) return 'Unknown';
    final sorted = discoverySources.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key.toString().split('.').last;
  }
}

/// Quick action for long-press menu
class QuickAction {
  const QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
}
