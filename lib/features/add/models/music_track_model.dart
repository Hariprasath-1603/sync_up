/// Music Track Model for Reel Background Music
class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String url;
  final String? previewUrl;
  final String? thumbnailUrl;
  final int durationSeconds;

  MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
    this.previewUrl,
    this.thumbnailUrl,
    required this.durationSeconds,
  });

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Unknown Title',
      artist: json['artist'] as String? ?? 'Unknown Artist',
      url: json['url'] as String? ?? '',
      previewUrl: json['preview_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'url': url,
      'preview_url': previewUrl,
      'thumbnail_url': thumbnailUrl,
      'duration_seconds': durationSeconds,
    };
  }

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
