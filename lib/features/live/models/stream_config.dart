class StreamHealthMetrics {
  final int bitrate; // kbps
  final int fps;
  final int droppedFrames;
  final double bandwidth; // Mbps
  final int latency; // ms
  final String quality; // low, medium, high, hd
  final bool isStable;

  StreamHealthMetrics({
    this.bitrate = 0,
    this.fps = 0,
    this.droppedFrames = 0,
    this.bandwidth = 0.0,
    this.latency = 0,
    this.quality = 'medium',
    this.isStable = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'bitrate': bitrate,
      'fps': fps,
      'dropped_frames': droppedFrames,
      'bandwidth': bandwidth,
      'latency': latency,
      'quality': quality,
      'is_stable': isStable,
    };
  }

  factory StreamHealthMetrics.fromJson(Map<String, dynamic> json) {
    return StreamHealthMetrics(
      bitrate: json['bitrate'] ?? 0,
      fps: json['fps'] ?? 0,
      droppedFrames: json['dropped_frames'] ?? 0,
      bandwidth: (json['bandwidth'] ?? 0.0).toDouble(),
      latency: json['latency'] ?? 0,
      quality: json['quality'] ?? 'medium',
      isStable: json['is_stable'] ?? true,
    );
  }
}

class StreamConfig {
  final String resolution; // 720p, 1080p
  final int bitrate; // kbps
  final int fps;
  final bool isFrontCamera;
  final bool enableBeautyFilter;
  final bool enableFlash;
  final String audioQuality; // low, medium, high

  StreamConfig({
    this.resolution = '720p',
    this.bitrate = 2500,
    this.fps = 30,
    this.isFrontCamera = true,
    this.enableBeautyFilter = false,
    this.enableFlash = false,
    this.audioQuality = 'high',
  });

  Map<String, dynamic> toJson() {
    return {
      'resolution': resolution,
      'bitrate': bitrate,
      'fps': fps,
      'is_front_camera': isFrontCamera,
      'enable_beauty_filter': enableBeautyFilter,
      'enable_flash': enableFlash,
      'audio_quality': audioQuality,
    };
  }

  factory StreamConfig.fromJson(Map<String, dynamic> json) {
    return StreamConfig(
      resolution: json['resolution'] ?? '720p',
      bitrate: json['bitrate'] ?? 2500,
      fps: json['fps'] ?? 30,
      isFrontCamera: json['is_front_camera'] ?? true,
      enableBeautyFilter: json['enable_beauty_filter'] ?? false,
      enableFlash: json['enable_flash'] ?? false,
      audioQuality: json['audio_quality'] ?? 'high',
    );
  }
}
