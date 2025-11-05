/// Metadata for a recorded reel
class ReelMetadata {
  final String? selectedTrackId;
  final String? selectedTrackTitle;
  final double recordingSpeed; // 1x, 2x, 3x, 5x
  final int durationMs;
  final bool hasGrid;
  final String? resolution;
  final int? frameRate;
  final double zoomLevel;

  ReelMetadata({
    this.selectedTrackId,
    this.selectedTrackTitle,
    this.recordingSpeed = 1.0,
    required this.durationMs,
    this.hasGrid = false,
    this.resolution,
    this.frameRate,
    this.zoomLevel = 1.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'selectedTrackId': selectedTrackId,
      'selectedTrackTitle': selectedTrackTitle,
      'recordingSpeed': recordingSpeed,
      'durationMs': durationMs,
      'hasGrid': hasGrid,
      'resolution': resolution,
      'frameRate': frameRate,
      'zoomLevel': zoomLevel,
    };
  }

  factory ReelMetadata.fromJson(Map<String, dynamic> json) {
    return ReelMetadata(
      selectedTrackId: json['selectedTrackId'] as String?,
      selectedTrackTitle: json['selectedTrackTitle'] as String?,
      recordingSpeed: (json['recordingSpeed'] as num?)?.toDouble() ?? 1.0,
      durationMs: json['durationMs'] as int? ?? 0,
      hasGrid: json['hasGrid'] as bool? ?? false,
      resolution: json['resolution'] as String?,
      frameRate: json['frameRate'] as int?,
      zoomLevel: (json['zoomLevel'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
