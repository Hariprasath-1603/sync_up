import 'dart:io';
import 'package:flutter/material.dart';

class ReelCreationModel {
  String? id;
  String? userId;
  List<VideoSegment> segments;
  String? audioId;
  String? audioName;
  String? audioArtist;
  String? audioUrl;
  String caption;
  List<String> hashtags;
  List<String> mentions;
  String? location;
  String visibility; // 'public', 'followers', 'private'
  bool allowRemix;
  bool allowComments;
  bool allowSharing;
  bool postToFeed;
  double posterFrameTime;
  File? thumbnailFile;
  CreationStatus status;
  DateTime? createdAt;

  ReelCreationModel({
    this.id,
    this.userId,
    this.segments = const [],
    this.audioId,
    this.audioName,
    this.audioArtist,
    this.audioUrl,
    this.caption = '',
    this.hashtags = const [],
    this.mentions = const [],
    this.location,
    this.visibility = 'public',
    this.allowRemix = true,
    this.allowComments = true,
    this.allowSharing = true,
    this.postToFeed = true,
    this.posterFrameTime = 0.0,
    this.thumbnailFile,
    this.status = CreationStatus.editing,
    this.createdAt,
    // Optional named parameters for compatibility
    AudioTrack? audioTrack,
    List<TextOverlay>? textOverlays,
    List<StickerOverlay>? stickerOverlays,
    List<String>? effects,
    EditingState? editingState,
  }) {
    // Handle compatibility parameters
    if (audioTrack != null) {
      audioId = audioTrack.id;
      audioName = audioTrack.name;
      audioArtist = audioTrack.artist;
      audioUrl = audioTrack.url;
    }
  }
  double get totalDuration {
    return segments.fold(0.0, (sum, segment) => sum + segment.duration);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'caption': caption,
      'hashtags': hashtags,
      'mentions': mentions,
      'location': location,
      'visibility': visibility,
      'audio_id': audioId,
      'audio_name': audioName,
      'audio_artist': audioArtist,
      'allow_remix': allowRemix,
      'allow_comments': allowComments,
      'allow_sharing': allowSharing,
      'post_to_feed': postToFeed,
      'poster_frame_time': posterFrameTime,
      'duration': totalDuration,
      'segments_count': segments.length,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  ReelCreationModel copyWith({
    String? id,
    String? userId,
    List<VideoSegment>? segments,
    String? audioId,
    String? audioName,
    String? audioArtist,
    String? audioUrl,
    String? caption,
    List<String>? hashtags,
    List<String>? mentions,
    String? location,
    String? visibility,
    bool? allowRemix,
    bool? allowComments,
    bool? allowSharing,
    bool? postToFeed,
    double? posterFrameTime,
    File? thumbnailFile,
    CreationStatus? status,
    DateTime? createdAt,
  }) {
    return ReelCreationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      segments: segments ?? this.segments,
      audioId: audioId ?? this.audioId,
      audioName: audioName ?? this.audioName,
      audioArtist: audioArtist ?? this.audioArtist,
      audioUrl: audioUrl ?? this.audioUrl,
      caption: caption ?? this.caption,
      hashtags: hashtags ?? this.hashtags,
      mentions: mentions ?? this.mentions,
      location: location ?? this.location,
      visibility: visibility ?? this.visibility,
      allowRemix: allowRemix ?? this.allowRemix,
      allowComments: allowComments ?? this.allowComments,
      allowSharing: allowSharing ?? this.allowSharing,
      postToFeed: postToFeed ?? this.postToFeed,
      posterFrameTime: posterFrameTime ?? this.posterFrameTime,
      thumbnailFile: thumbnailFile ?? this.thumbnailFile,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class VideoSegment {
  String id;
  File? file;
  String? url;
  double duration;
  int orderIndex;
  double startTime;
  double endTime;
  double speed; // 0.5x, 1x, 2x, 4x
  String? effectId;
  List<TextOverlay> textOverlays;
  List<StickerOverlay> stickerOverlays;
  String? filterId;
  bool hasOriginalAudio;
  double originalAudioVolume;

  VideoSegment({
    required this.id,
    this.file,
    this.url,
    required this.duration,
    required this.orderIndex,
    this.startTime = 0.0,
    double? endTime,
    this.speed = 1.0,
    this.effectId,
    this.textOverlays = const [],
    this.stickerOverlays = const [],
    this.filterId,
    this.hasOriginalAudio = true,
    this.originalAudioVolume = 1.0,
  }) : endTime = endTime ?? duration;

  double get trimmedDuration => (endTime - startTime) / speed;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'duration': duration,
      'order_index': orderIndex,
      'start_time': startTime,
      'end_time': endTime,
      'speed': speed,
      'effect_id': effectId,
      'filter_id': filterId,
      'has_original_audio': hasOriginalAudio,
      'original_audio_volume': originalAudioVolume,
    };
  }
}

// AudioTrack class for audio overlay
class AudioTrack {
  String id;
  String name;
  String artist;
  String url;
  double duration;
  double volume;
  double startTime;

  AudioTrack({
    required this.id,
    required this.name,
    required this.artist,
    required this.url,
    required this.duration,
    this.volume = 1.0,
    this.startTime = 0.0,
  });
}

// EditingState enum for tracking editing workflow
enum EditingState { recording, editing, previewing, uploading, published }

class TextOverlay {
  String id;
  String text;
  double x; // 0.0 to 1.0 (percentage)
  double y; // 0.0 to 1.0
  double rotation;
  double scale;
  String fontFamily;
  double fontSize;
  String color;
  String backgroundColor;
  double startTime;
  double endTime;
  TextAlign alignment;
  String? animationType;

  TextOverlay({
    required this.id,
    required this.text,
    this.x = 0.5,
    this.y = 0.5,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.fontFamily = 'Roboto',
    this.fontSize = 24.0,
    this.color = '#FFFFFF',
    this.backgroundColor = '#00000000',
    required this.startTime,
    required this.endTime,
    this.alignment = TextAlign.center,
    this.animationType,
    TextStyle? style,
    Offset? position,
  }) {
    // If style is provided, extract properties from it
    if (style != null) {
      if (style.fontSize != null) fontSize = style.fontSize!;
      if (style.color != null) {
        color = '#${style.color!.value.toRadixString(16).padLeft(8, '0')}';
      }
      if (style.fontFamily != null) fontFamily = style.fontFamily!;
    }
    // If position is provided, use it
    if (position != null) {
      x = position.dx;
      y = position.dy;
    }
  }

  // Getters for compatibility with editing page
  TextStyle get style => TextStyle(
    fontSize: fontSize,
    color: Color(int.parse(color.substring(1), radix: 16)),
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
  );

  Offset get position => Offset(x, y);
}

class StickerOverlay {
  String id;
  String stickerUrl;
  double x;
  double y;
  double rotation;
  double scale;
  double startTime;
  double endTime;
  String? animationType;

  StickerOverlay({
    required this.id,
    required this.stickerUrl,
    this.x = 0.5,
    this.y = 0.5,
    this.rotation = 0.0,
    this.scale = 1.0,
    required this.startTime,
    required this.endTime,
    this.animationType,
    String? imageUrl,
    Offset? position,
    double? size,
  }) {
    // If imageUrl is provided, use it
    if (imageUrl != null) stickerUrl = imageUrl;
    // If position is provided, use it
    if (position != null) {
      x = position.dx;
      y = position.dy;
    }
    // If size is provided, use it to set scale
    if (size != null) scale = size / 100.0; // Assuming 100 is base size
  }

  // Getters for compatibility with editing page
  String get imageUrl => stickerUrl;
  Offset get position => Offset(x, y);
  double get size => scale * 100.0; // Convert scale back to size
}

enum CreationStatus {
  editing,
  previewing,
  uploading,
  processing,
  published,
  draft,
  failed,
}

enum CameraMode { photo, video, reel }

enum RecordingState { idle, recording, paused }
