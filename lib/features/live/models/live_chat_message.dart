enum MessageType { text, gift, join, leave, pinned, systemAlert }

class LiveChatMessage {
  final String id;
  final String streamId;
  final String? authorId;
  final String? authorUsername;
  final String? authorAvatarUrl;
  final bool isAuthorVerified;
  final String message;
  final MessageType type;
  final DateTime createdAt;
  final bool isDeleted;
  final bool isModerationFlagged;
  final Map<String, dynamic>? metadata; // For gifts, join events, etc.

  LiveChatMessage({
    required this.id,
    required this.streamId,
    this.authorId,
    this.authorUsername,
    this.authorAvatarUrl,
    this.isAuthorVerified = false,
    required this.message,
    this.type = MessageType.text,
    required this.createdAt,
    this.isDeleted = false,
    this.isModerationFlagged = false,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stream_id': streamId,
      'author_id': authorId,
      'author_username': authorUsername,
      'author_avatar_url': authorAvatarUrl,
      'is_author_verified': isAuthorVerified,
      'message': message,
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
      'is_deleted': isDeleted,
      'is_moderation_flagged': isModerationFlagged,
      'metadata': metadata,
    };
  }

  factory LiveChatMessage.fromJson(Map<String, dynamic> json) {
    return LiveChatMessage(
      id: json['id'],
      streamId: json['stream_id'],
      authorId: json['author_id'],
      authorUsername: json['author_username'],
      authorAvatarUrl: json['author_avatar_url'],
      isAuthorVerified: json['is_author_verified'] ?? false,
      message: json['message'],
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      createdAt: DateTime.parse(json['created_at']),
      isDeleted: json['is_deleted'] ?? false,
      isModerationFlagged: json['is_moderation_flagged'] ?? false,
      metadata: json['metadata'],
    );
  }
}
