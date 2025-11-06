/// Reel Model
///
/// Represents a reel (short video) in the SyncUp app.
/// This model matches the structure of the 'reels' table in Supabase.
///
/// Database Schema:
/// - id: UUID (primary key)
/// - user_id: UUID (foreign key to users)
/// - video_url: TEXT (video file URL from Supabase Storage)
/// - thumbnail_url: TEXT (thumbnail image URL)
/// - caption: TEXT (reel description)
/// - likes_count: INTEGER (number of likes)
/// - comments_count: INTEGER (number of comments)
/// - views_count: INTEGER (number of views)
/// - shares_count: INTEGER (number of shares)
/// - duration: INTEGER (video duration in seconds)
/// - created_at: TIMESTAMP
/// - updated_at: TIMESTAMP
library;

class ReelModel {
  final String id;
  final String userId;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? caption;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final int sharesCount;
  final int? duration; // Duration in seconds
  final DateTime createdAt;
  final DateTime updatedAt;

  // User information (joined from users table)
  final String? username;
  final String? userPhotoUrl;
  final String? userFullName;

  // Interaction state (client-side)
  final bool isLiked;
  final bool isSaved;

  ReelModel({
    required this.id,
    required this.userId,
    required this.videoUrl,
    this.thumbnailUrl,
    this.caption,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    this.sharesCount = 0,
    this.duration,
    required this.createdAt,
    required this.updatedAt,
    this.username,
    this.userPhotoUrl,
    this.userFullName,
    this.isLiked = false,
    this.isSaved = false,
  });

  /// Create ReelModel from JSON (from Supabase)
  factory ReelModel.fromJson(Map<String, dynamic> json) {
    return ReelModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      videoUrl: json['video_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      caption: json['caption'] as String?,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      viewsCount: json['views_count'] as int? ?? 0,
      sharesCount: json['shares_count'] as int? ?? 0,
      duration: json['duration'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      // User information from joined query
      username: json['username'] as String?,
      userPhotoUrl: json['user_photo_url'] as String?,
      userFullName: json['user_full_name'] as String?,
      // Interaction state
      isLiked: json['is_liked'] as bool? ?? false,
      isSaved: json['is_saved'] as bool? ?? false,
    );
  }

  /// Convert ReelModel to JSON (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'caption': caption,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'views_count': viewsCount,
      'shares_count': sharesCount,
      'duration': duration,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of ReelModel with updated fields
  ReelModel copyWith({
    String? id,
    String? userId,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    int? likesCount,
    int? commentsCount,
    int? viewsCount,
    int? sharesCount,
    int? duration,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? username,
    String? userPhotoUrl,
    String? userFullName,
    bool? isLiked,
    bool? isSaved,
  }) {
    return ReelModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      username: username ?? this.username,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      userFullName: userFullName ?? this.userFullName,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  @override
  String toString() {
    return 'ReelModel(id: $id, userId: $userId, caption: $caption, '
        'likesCount: $likesCount, commentsCount: $commentsCount, '
        'viewsCount: $viewsCount, duration: $duration, '
        'createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ReelModel &&
        other.id == id &&
        other.userId == userId &&
        other.videoUrl == videoUrl &&
        other.thumbnailUrl == thumbnailUrl &&
        other.caption == caption;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        videoUrl.hashCode ^
        thumbnailUrl.hashCode ^
        caption.hashCode;
  }

  /// Get formatted duration string (e.g., "1:23")
  String get formattedDuration {
    if (duration == null) return '0:00';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get formatted likes count (e.g., "1.2K", "345")
  String get formattedLikesCount {
    return _formatCount(likesCount);
  }

  /// Get formatted views count (e.g., "1.2K", "345")
  String get formattedViewsCount {
    return _formatCount(viewsCount);
  }

  /// Get formatted comments count (e.g., "1.2K", "345")
  String get formattedCommentsCount {
    return _formatCount(commentsCount);
  }

  /// Get formatted shares count (e.g., "1.2K", "345")
  String get formattedSharesCount {
    return _formatCount(sharesCount);
  }

  /// Format large numbers with K, M suffixes
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  /// Check if this reel belongs to the given user
  bool isOwnedBy(String uid) {
    return userId == uid;
  }

  /// Get display username (with @ prefix)
  String get displayUsername {
    return username != null ? '@$username' : '@unknown';
  }
}

/// Create Reel Request Model
/// Used when creating a new reel (before it's uploaded to the database)
class CreateReelRequest {
  final String userId;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? caption;
  final int? duration;

  CreateReelRequest({
    required this.userId,
    required this.videoUrl,
    this.thumbnailUrl,
    this.caption,
    this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'caption': caption,
      'duration': duration,
      'likes_count': 0,
      'comments_count': 0,
      'views_count': 0,
      'shares_count': 0,
    };
  }
}

/// Update Reel Request Model
/// Used when updating an existing reel
class UpdateReelRequest {
  final String? caption;
  final String? thumbnailUrl;

  UpdateReelRequest({this.caption, this.thumbnailUrl});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (caption != null) json['caption'] = caption;
    if (thumbnailUrl != null) json['thumbnail_url'] = thumbnailUrl;
    return json;
  }
}
