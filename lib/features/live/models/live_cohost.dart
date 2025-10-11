enum CohostRole { cohost, guest }

class LiveCohost {
  final String id;
  final String streamId;
  final String userId;
  final String username;
  final String? avatarUrl;
  final bool isVerified;
  final CohostRole role;
  final DateTime? joinedAt;
  final bool isActive;
  final bool isMuted;

  LiveCohost({
    required this.id,
    required this.streamId,
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.isVerified = false,
    this.role = CohostRole.guest,
    this.joinedAt,
    this.isActive = false,
    this.isMuted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stream_id': streamId,
      'user_id': userId,
      'username': username,
      'avatar_url': avatarUrl,
      'is_verified': isVerified,
      'role': role.name,
      'joined_at': joinedAt?.toIso8601String(),
      'is_active': isActive,
      'is_muted': isMuted,
    };
  }

  factory LiveCohost.fromJson(Map<String, dynamic> json) {
    return LiveCohost(
      id: json['id'],
      streamId: json['stream_id'],
      userId: json['user_id'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      isVerified: json['is_verified'] ?? false,
      role: CohostRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => CohostRole.guest,
      ),
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : null,
      isActive: json['is_active'] ?? false,
      isMuted: json['is_muted'] ?? false,
    );
  }
}
