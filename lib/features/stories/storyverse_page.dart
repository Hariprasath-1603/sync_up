import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme.dart';

/// Stages in the StoryVerse experience.
enum StoryVerseStage { entry, capture, editor, share, viewer, insights }

/// Capture modes offered in the camera stage.
enum StoryVerseMode { photo, video, boomerang, text, layout }

/// Audiences supported in the share stage.
enum StoryVerseAudience { everyone, followers, closeFriends, custom }

/// Reaction shortcuts that surface inside the viewer.
enum StoryVerseReactionType { love, fire, laugh, wow, celebrate, sad }

enum StoryVerseOverlayType {
  text,
  sticker,
  poll,
  question,
  countdown,
  quiz,
  location,
  hashtag,
}

/// Describes an overlay positioned on top of a clip.
class StoryVerseOverlay {
  StoryVerseOverlay({
    required this.id,
    required this.type,
    required this.label,
    required this.position,
    this.color,
    this.metadata = const {},
    this.size = 1.0,
  });

  final String id;
  final StoryVerseOverlayType type;
  final String label;
  Offset position;
  final Map<String, dynamic> metadata;
  Color? color;
  double size;
}

/// Draft clip that the user is currently editing.
class StoryVerseClip {
  StoryVerseClip({
    required this.id,
    required this.mode,
    this.imageBytes,
    this.videoFile,
    this.duration = const Duration(seconds: 6),
    this.caption,
    this.mood,
    this.music,
    this.filters = const [],
  });

  final String id;
  final StoryVerseMode mode;
  final Uint8List? imageBytes;
  final XFile? videoFile;
  Duration duration;
  String? caption;
  String? mood;
  StoryVerseMusicTrack? music;
  List<String> filters;
  final List<StoryVerseOverlay> overlays = [];

  StoryVerseClip copyWith({
    Duration? duration,
    String? caption,
    String? mood,
    StoryVerseMusicTrack? music,
    List<String>? filters,
    Uint8List? imageBytes,
    XFile? videoFile,
  }) {
    final clip = StoryVerseClip(
      id: id,
      mode: mode,
      imageBytes: imageBytes ?? this.imageBytes,
      videoFile: videoFile ?? this.videoFile,
      duration: duration ?? this.duration,
      caption: caption ?? this.caption,
      mood: mood ?? this.mood,
      music: music ?? this.music,
      filters: filters ?? List<String>.from(this.filters),
    );
    clip.overlays
      ..clear()
      ..addAll(overlays.map(_cloneOverlay));
    return clip;
  }

  StoryVerseOverlay _cloneOverlay(StoryVerseOverlay overlay) {
    return StoryVerseOverlay(
      id: overlay.id,
      type: overlay.type,
      label: overlay.label,
      position: overlay.position,
      metadata: Map<String, dynamic>.from(overlay.metadata),
      color: overlay.color,
      size: overlay.size,
    );
  }
}

class StoryVerseMusicTrack {
  const StoryVerseMusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    this.duration = const Duration(minutes: 1),
  });

  final String id;
  final String title;
  final String artist;
  final String artworkUrl;
  final Duration duration;
}

/// Draft that accumulates clips, metadata and share preferences.
class StoryVerseDraft {
  StoryVerseDraft();

  final List<StoryVerseClip> clips = [];
  StoryVerseAudience audience = StoryVerseAudience.everyone;
  bool allowReplies = true;
  bool allowSharing = true;
  bool saveToArchive = true;
  bool addToHighlight = false;
  final List<String> highlightTags = [];

  bool get isEmpty => clips.isEmpty;

  void reset() {
    clips.clear();
    audience = StoryVerseAudience.everyone;
    allowReplies = true;
    allowSharing = true;
    saveToArchive = true;
    addToHighlight = false;
    highlightTags.clear();
  }
}

class StoryVerseAnalytics {
  StoryVerseAnalytics({
    required this.viewCount,
    required this.replies,
    required this.reactions,
    required this.averageWatch,
    required this.shares,
    required this.reach,
    required this.discoverySources,
  });

  final int viewCount;
  final int replies;
  final int reactions;
  final Duration averageWatch;
  final int shares;
  final int reach;
  final Map<String, int> discoverySources;
}

class StoryVerseStory {
  StoryVerseStory({
    required this.id,
    required this.ownerName,
    required this.ownerAvatar,
    required this.mood,
    required this.timestamp,
    required this.clips,
    this.music,
    this.hasNewContent = true,
  });

  final String id;
  final String ownerName;
  final String ownerAvatar;
  final String mood;
  final DateTime timestamp;
  final List<StoryVerseClip> clips;
  final StoryVerseMusicTrack? music;
  final bool hasNewContent;
}

/// Entire StoryVerse flow widget encapsulating entry, capture, editor, share, viewer and insights.
class StoryVerseExperience extends StatefulWidget {
  const StoryVerseExperience({
    super.key,
    this.initialStage = StoryVerseStage.entry,
    this.initialStory,
    this.feedStories,
    this.showEntryStage = true,
    this.initialMode = StoryVerseMode.photo,
    this.onClose,
    this.showInsightsButton = true,
  });

  final StoryVerseStage initialStage;
  final StoryVerseStory? initialStory;
  final List<StoryVerseStory>? feedStories;
  final bool showEntryStage;
  final StoryVerseMode initialMode;
  final VoidCallback? onClose;
  final bool showInsightsButton;

  @override
  State<StoryVerseExperience> createState() => _StoryVerseExperienceState();
}

class _StoryVerseExperienceState extends State<StoryVerseExperience>
    with TickerProviderStateMixin {
  final StoryVerseDraft _draft = StoryVerseDraft();
  final ImagePicker _picker = ImagePicker();
  late StoryVerseStage _stage;
  late StoryVerseMode _mode;
  CameraController? _cameraController;
  Future<void>? _cameraInitFuture;
  List<CameraDescription> _availableCameras = const [];
  int _activeCameraIndex = 0;
  double _currentZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  bool _isRecordingVideo = false;
  String? _cameraError;
  bool _isInitializingCamera = false;
  StoryVerseStory? _activeStory;
  int _activeClipIndex = 0;
  int _activeViewerSegment = 0;
  Timer? _storyTimer;
  double _segmentProgress = 0;
  bool _isViewerPaused = false;
  bool _isStoryTransitioning = false;
  int? _pendingStoryIndex;
  int _storyTransitionDirection = 0;
  int _storyTransitionTargetSegment = 0;
  late final AnimationController _storyTransitionController;
  late final Animation<double> _storyTransitionAnimation;
  late final AnimationController _entryPulseController;

  @override
  void initState() {
    super.initState();
    _stage = widget.initialStage;
    _mode = widget.initialMode;
    if ((_stage == StoryVerseStage.viewer ||
            _stage == StoryVerseStage.insights) &&
        widget.initialStory != null) {
      _activeStory = widget.initialStory;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_stage == StoryVerseStage.viewer) {
          _kickOffProgressTimer();
        }
      });
    }
    if (!widget.showEntryStage && _stage == StoryVerseStage.entry) {
      _stage = StoryVerseStage.capture;
    }
    if (_stage == StoryVerseStage.capture) {
      unawaited(_initializeCamera());
    }
    _entryPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _storyTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _storyTransitionAnimation = CurvedAnimation(
      parent: _storyTransitionController,
      curve: Curves.easeInOut,
    );
    _storyTransitionController.addListener(() {
      if (!mounted || !_isStoryTransitioning) return;
      setState(() {});
    });
    _storyTransitionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _completePendingStoryTransition();
      }
    });
  }

  @override
  void dispose() {
    _storyTimer?.cancel();
    _cameraController?.dispose();
    _entryPulseController.dispose();
    _storyTransitionController.dispose();
    super.dispose();
  }

  List<StoryVerseStory> get _stories =>
      widget.feedStories ?? _StoryVerseMockData.stories;

  bool get _isCameraReady =>
      _cameraController != null && _cameraController!.value.isInitialized;

  Future<void> _initializeCamera({bool force = false}) async {
    if (kIsWeb) {
      setState(() {
        _cameraError = 'Camera preview is not supported on web builds.';
        _cameraInitFuture = null;
      });
      return;
    }

    if (_isInitializingCamera) return;
    if (!force && _isCameraReady) return;

    setState(() {
      _isInitializingCamera = true;
      _cameraError = null;
    });

    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _cameraError =
              'Camera permission denied. Please enable it in settings to record stories.';
          _cameraInitFuture = null;
        });
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _cameraError = 'No cameras detected on this device.';
          _cameraInitFuture = null;
        });
        return;
      }

      _availableCameras = cameras;
      if (_activeCameraIndex >= cameras.length) {
        _activeCameraIndex = 0;
      }

      await _cameraController?.dispose();
      final controller = CameraController(
        cameras[_activeCameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
      );
      final initFuture = controller.initialize();
      setState(() {
        _cameraController = controller;
        _cameraInitFuture = initFuture;
      });

      await initFuture;
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();
      final targetZoom = min(max(1.0, minZoom), maxZoom);
      await controller.setZoomLevel(targetZoom);

      if (!mounted) return;
      setState(() {
        _minZoomLevel = minZoom;
        _maxZoomLevel = maxZoom;
        _currentZoomLevel = targetZoom;
        _cameraError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraError = 'Unable to access camera: $error';
        _cameraInitFuture = null;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isInitializingCamera = false;
      });
    }
  }

  Future<void> _flipCamera() async {
    if (kIsWeb) return;
    if (_availableCameras.length < 2) {
      await _initializeCamera(force: true);
      if (_availableCameras.length < 2) {
        _showError('Only one camera available.');
        return;
      }
    }
    _activeCameraIndex = (_activeCameraIndex + 1) % _availableCameras.length;
    await _initializeCamera(force: true);
  }

  Future<void> _openGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1080,
        maxHeight: 1920,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      _appendClip(
        StoryVerseClip(
          id: _generateId('clip'),
          mode: StoryVerseMode.photo,
          imageBytes: bytes,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (error) {
      _showError('Unable to open gallery ($error)');
    }
  }

  Future<void> _handleZoomChange(double level) async {
    if (!_isCameraReady) return;
    final zoom = level.clamp(_minZoomLevel, _maxZoomLevel);
    try {
      await _cameraController!.setZoomLevel(zoom);
      if (!mounted) return;
      setState(() {
        _currentZoomLevel = zoom;
      });
    } catch (error) {
      _showError('Unable to adjust zoom ($error)');
    }
  }

  Future<XFile?> _stopVideoRecording({required bool saveClip}) async {
    if (!_isCameraReady) {
      if (_isRecordingVideo && mounted) {
        setState(() => _isRecordingVideo = false);
      }
      return null;
    }
    try {
      if (!_cameraController!.value.isRecordingVideo) {
        if (_isRecordingVideo && mounted) {
          setState(() => _isRecordingVideo = false);
        }
        return null;
      }
      final XFile file = await _cameraController!.stopVideoRecording();
      if (mounted) {
        setState(() => _isRecordingVideo = false);
      }
      return saveClip ? file : null;
    } catch (error) {
      if (mounted) {
        setState(() => _isRecordingVideo = false);
      }
      if (saveClip) {
        _showError('Unable to finish recording ($error)');
      }
      return null;
    }
  }

  void _handleDismiss() {
    if (!mounted) return;
    if (_isRecordingVideo) {
      unawaited(_stopVideoRecording(saveClip: false));
    }
    _storyTimer?.cancel();
    _draft.reset();

    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _handleWillPop() async {
    if (widget.showEntryStage) {
      if (_stage != StoryVerseStage.entry) {
        _goToStage(StoryVerseStage.entry);
        return false;
      }
      return true;
    }
    _handleDismiss();
    return false;
  }

  void _goToStage(StoryVerseStage stage) {
    if (!widget.showEntryStage && stage == StoryVerseStage.entry) {
      _handleDismiss();
      return;
    }
    if (stage == StoryVerseStage.capture && !kIsWeb) {
      unawaited(_initializeCamera());
    } else if (stage != StoryVerseStage.capture && _isRecordingVideo) {
      unawaited(_stopVideoRecording(saveClip: false));
    }
    setState(() {
      _stage = stage;
    });
  }

  void _startCapture(StoryVerseMode mode) {
    _mode = mode;
    _goToStage(StoryVerseStage.capture);
  }

  Future<void> _captureMedia() async {
    switch (_mode) {
      case StoryVerseMode.photo:
        await _capturePhoto();
        break;
      case StoryVerseMode.video:
        await _captureVideo();
        break;
      case StoryVerseMode.boomerang:
        _simulateBoomerang();
        break;
      case StoryVerseMode.text:
        _createTextStory();
        break;
      case StoryVerseMode.layout:
        _openLayoutComposer();
        break;
    }
  }

  Future<void> _capturePhoto() async {
    try {
      if (_isCameraReady) {
        final XFile file = await _cameraController!.takePicture();
        final bytes = await file.readAsBytes();
        _appendClip(
          StoryVerseClip(
            id: _generateId('clip'),
            mode: StoryVerseMode.photo,
            imageBytes: bytes,
            duration: const Duration(seconds: 6),
          ),
        );
        return;
      }

      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 88,
        maxWidth: 1080,
        maxHeight: 1920,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      _appendClip(
        StoryVerseClip(
          id: _generateId('clip'),
          mode: StoryVerseMode.photo,
          imageBytes: bytes,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (error) {
      _showError('Unable to open camera ($error)');
    }
  }

  Future<void> _captureVideo() async {
    try {
      if (_isCameraReady) {
        if (_isRecordingVideo) {
          final XFile? file = await _stopVideoRecording(saveClip: true);
          if (file == null) return;
          _appendClip(
            StoryVerseClip(
              id: _generateId('clip'),
              mode: StoryVerseMode.video,
              videoFile: file,
              duration: const Duration(seconds: 15),
            ),
          );
        } else {
          await _cameraController!.startVideoRecording();
          if (mounted) {
            setState(() => _isRecordingVideo = true);
          }
        }
        return;
      }

      final XFile? file = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 30),
      );
      if (file == null) return;
      _appendClip(
        StoryVerseClip(
          id: _generateId('clip'),
          mode: StoryVerseMode.video,
          videoFile: file,
          duration: const Duration(seconds: 15),
        ),
      );
    } catch (error) {
      _showError('Unable to record video ($error)');
    }
  }

  void _simulateBoomerang() {
    _appendClip(
      StoryVerseClip(
        id: _generateId('clip'),
        mode: StoryVerseMode.boomerang,
        imageBytes: null,
        duration: const Duration(seconds: 8),
        mood: 'Energetic',
        filters: const ['Boomerang Pulse'],
      ),
    );
  }

  void _createTextStory() {
    _appendClip(
      StoryVerseClip(
        id: _generateId('clip'),
        mode: StoryVerseMode.text,
        imageBytes: null,
        duration: const Duration(seconds: 7),
        mood: 'Reflective',
      )..caption = 'Tap to add your thoughts...',
    );
  }

  void _openLayoutComposer() {
    _appendClip(
      StoryVerseClip(
        id: _generateId('clip'),
        mode: StoryVerseMode.layout,
        imageBytes: null,
        duration: const Duration(seconds: 6),
        mood: 'Aesthetic',
        filters: const ['Split Layout'],
      ),
    );
  }

  void _appendClip(StoryVerseClip clip) {
    setState(() {
      _draft.clips.add(clip);
      _activeClipIndex = _draft.clips.length - 1;
      _stage = StoryVerseStage.editor;
    });
  }

  void _removeClip(String id) {
    setState(() {
      _draft.clips.removeWhere((clip) => clip.id == id);
      if (_draft.clips.isEmpty) {
        _goToStage(StoryVerseStage.entry);
      } else {
        _activeClipIndex = min(_activeClipIndex, _draft.clips.length - 1);
      }
    });
  }

  void _duplicateClip(StoryVerseClip clip) {
    final duplicated = clip.copyWith(
      duration: clip.duration,
      caption: clip.caption,
      filters: List<String>.from(clip.filters),
    );
    setState(() {
      _draft.clips.insert(_activeClipIndex + 1, duplicated);
      _activeClipIndex++;
    });
  }

  void _updateClip(StoryVerseClip clip) {
    setState(() {
      final index = _draft.clips.indexWhere((element) => element.id == clip.id);
      if (index != -1) {
        _draft.clips[index] = clip;
        _activeClipIndex = index;
      }
    });
  }

  void _goToShare() {
    if (_draft.clips.isEmpty) {
      _showError('Add at least one clip before sharing.');
      return;
    }
    _goToStage(StoryVerseStage.share);
  }

  void _publishStory() {
    _showSuccess('Story shared to your circle.');
    if (widget.showEntryStage) {
      _draft.reset();
      _goToStage(StoryVerseStage.entry);
    } else {
      _handleDismiss();
    }
  }

  void _openViewer(StoryVerseStory story) {
    final stories = _stories;
    final index = stories.indexWhere((element) => element.id == story.id);
    final resolvedStory = index != -1 ? stories[index] : story;
    _storyTransitionController.stop();
    _storyTransitionController.reset();
    _pendingStoryIndex = null;
    _storyTransitionDirection = 0;
    _storyTransitionTargetSegment = 0;
    setState(() {
      _activeStory = resolvedStory;
      _activeViewerSegment = 0;
      _segmentProgress = 0;
      _isViewerPaused = false;
      _isStoryTransitioning = false;
      _stage = StoryVerseStage.viewer;
    });
    _kickOffProgressTimer();
  }

  void _completePendingStoryTransition() {
    if (!mounted) return;
    final index = _pendingStoryIndex;
    final stories = _stories;
    if (_stage != StoryVerseStage.viewer) {
      _storyTransitionController.reset();
      setState(() {
        _isStoryTransitioning = false;
        _isViewerPaused = false;
        _storyTransitionDirection = 0;
        _pendingStoryIndex = null;
        _storyTransitionTargetSegment = 0;
      });
      return;
    }

    if (index == null || index < 0 || index >= stories.length) {
      _storyTransitionController.reset();
      setState(() {
        _isStoryTransitioning = false;
        _isViewerPaused = false;
        _storyTransitionDirection = 0;
        _pendingStoryIndex = null;
        _storyTransitionTargetSegment = 0;
      });
      _kickOffProgressTimer();
      return;
    }

    final story = stories[index];
    final maxSegment = story.clips.isEmpty ? 0 : story.clips.length - 1;
    final targetSegment = _storyTransitionTargetSegment.clamp(0, maxSegment);

    setState(() {
      _activeStory = story;
      _activeViewerSegment = targetSegment;
      _segmentProgress = 0;
      _isStoryTransitioning = false;
      _isViewerPaused = false;
      _storyTransitionDirection = 0;
      _pendingStoryIndex = null;
      _storyTransitionTargetSegment = 0;
    });
    _storyTransitionController.reset();
    _kickOffProgressTimer();
  }

  void _openInsights() {
    if (_activeStory == null) return;
    _goToStage(StoryVerseStage.insights);
  }

  void _kickOffProgressTimer() {
    _storyTimer?.cancel();
    _segmentProgress = 0;
    _storyTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || _isViewerPaused) return;
      setState(() {
        _segmentProgress += 0.02;
        if (_segmentProgress >= 1) {
          _segmentProgress = 0;
          _advanceSegment();
        }
      });
    });
  }

  void _advanceSegment() {
    if (_isStoryTransitioning) return;
    if (_activeStory == null) return;
    if (_activeViewerSegment < _activeStory!.clips.length - 1) {
      setState(() {
        _activeViewerSegment++;
        _segmentProgress = 0;
      });
      return;
    }
    final nextIndex = _findNextStoryIndex();
    if (nextIndex != null) {
      _goToStoryIndex(nextIndex);
    } else {
      _exitViewer();
    }
  }

  void _previousSegment() {
    if (_isStoryTransitioning) return;
    if (_activeStory == null) return;
    if (_activeViewerSegment > 0) {
      setState(() {
        _activeViewerSegment--;
        _segmentProgress = 0;
      });
      return;
    }
    final previousIndex = _findPreviousStoryIndex();
    if (previousIndex != null) {
      final stories = _stories;
      final clips = stories[previousIndex].clips;
      final targetSegment = clips.isEmpty ? 0 : clips.length - 1;
      _goToStoryIndex(previousIndex, initialSegment: targetSegment);
    }
  }

  int? _findNextStoryIndex() {
    if (_activeStory == null) return null;
    final stories = _stories;
    final currentIndex = stories.indexWhere(
      (element) => element.id == _activeStory!.id,
    );
    if (currentIndex == -1) return null;
    if (currentIndex >= stories.length - 1) return null;
    return currentIndex + 1;
  }

  int? _findPreviousStoryIndex() {
    if (_activeStory == null) return null;
    final stories = _stories;
    final currentIndex = stories.indexWhere(
      (element) => element.id == _activeStory!.id,
    );
    if (currentIndex <= 0) return null;
    return currentIndex - 1;
  }

  void _goToStoryIndex(int index, {int initialSegment = 0}) {
    if (_isStoryTransitioning) return;
    final stories = _stories;
    if (index < 0 || index >= stories.length) {
      _exitViewer();
      return;
    }
    final currentIndex = _activeStory == null
        ? -1
        : stories.indexWhere((element) => element.id == _activeStory!.id);
    if (currentIndex == index) return;

    final direction = currentIndex != -1 && index < currentIndex ? -1 : 1;
    final clips = stories[index].clips;
    final targetSegment = clips.isEmpty
        ? 0
        : initialSegment.clamp(0, clips.length - 1);

    _storyTimer?.cancel();
    _storyTransitionController.stop();
    _storyTransitionController.reset();

    setState(() {
      _isStoryTransitioning = true;
      _isViewerPaused = true;
      _segmentProgress = 0;
      _storyTransitionDirection = direction;
      _pendingStoryIndex = index;
      _storyTransitionTargetSegment = targetSegment;
    });

    _storyTransitionController.forward(from: 0);
  }

  void _togglePause() {
    setState(() {
      _isViewerPaused = !_isViewerPaused;
    });
  }

  void _exitViewer() {
    _storyTimer?.cancel();
    _storyTransitionController.stop();
    _storyTransitionController.reset();
    _pendingStoryIndex = null;
    _storyTransitionDirection = 0;
    _storyTransitionTargetSegment = 0;
    if (widget.showEntryStage) {
      setState(() {
        _stage = StoryVerseStage.entry;
        _activeStory = null;
        _isStoryTransitioning = false;
        _isViewerPaused = false;
        _segmentProgress = 0;
      });
      return;
    }
    setState(() {
      _isStoryTransitioning = false;
    });
    _handleDismiss();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ), // Keep green for success semantic color
    );
  }

  @override
  Widget build(BuildContext context) {
    final stories = _stories;
    final storyForViewer =
        _activeStory ?? (stories.isNotEmpty ? stories.first : null);
    var effectiveStage = _stage;
    if ((effectiveStage == StoryVerseStage.viewer ||
            effectiveStage == StoryVerseStage.insights) &&
        storyForViewer == null) {
      effectiveStage = StoryVerseStage.entry;
    }

    if (!widget.showEntryStage && effectiveStage == StoryVerseStage.entry) {
      return const SizedBox.shrink();
    }

    StoryVerseStory? pendingStory;
    if (_pendingStoryIndex != null &&
        _pendingStoryIndex! >= 0 &&
        _pendingStoryIndex! < stories.length) {
      pendingStory = stories[_pendingStoryIndex!];
    }

    final child = switch (effectiveStage) {
      StoryVerseStage.entry => _StoryVerseEntryStage(
        onStartCapture: _startCapture,
        onOpenStory: _openViewer,
        pulseAnimation: _entryPulseController,
        stories: stories,
      ),
      StoryVerseStage.capture => _StoryVerseCaptureStage(
        mode: _mode,
        onBack: widget.showEntryStage
            ? () => _goToStage(StoryVerseStage.entry)
            : _handleDismiss,
        onCapture: _captureMedia,
        onModeChanged: (mode) {
          if (_mode == StoryVerseMode.video &&
              _isRecordingVideo &&
              mode != StoryVerseMode.video) {
            unawaited(_stopVideoRecording(saveClip: false));
          }
          setState(() => _mode = mode);
        },
        cameraController: _cameraController,
        cameraInitFuture: _cameraInitFuture,
        cameraError: _cameraError,
        isCameraInitializing: _isInitializingCamera,
        isCameraReady: _isCameraReady,
        isRecordingVideo: _isRecordingVideo,
        zoomLevel: _currentZoomLevel,
        minZoom: _minZoomLevel,
        maxZoom: _maxZoomLevel,
        onFlipCamera: _flipCamera,
        onOpenGallery: _openGallery,
        onZoomChanged: _handleZoomChange,
        onRetryCamera: () => _initializeCamera(force: true),
      ),
      StoryVerseStage.editor => _StoryVerseEditorStage(
        draft: _draft,
        activeIndex: _activeClipIndex,
        onClipChanged: _updateClip,
        onClipRemoved: _removeClip,
        onClipDuplicated: _duplicateClip,
        onAddOverlay: _addOverlay,
        onUpdateOverlayPosition: _updateOverlayPosition,
        onRemoveOverlay: _removeOverlay,
        onShare: _goToShare,
        onBack: () => _goToStage(StoryVerseStage.capture),
        onExit: _handleDismiss,
      ),
      StoryVerseStage.share => _StoryVerseShareStage(
        draft: _draft,
        onBack: () => _goToStage(StoryVerseStage.editor),
        onPublish: _publishStory,
      ),
      StoryVerseStage.viewer => _StoryVerseViewerStage(
        story: storyForViewer!,
        activeIndex: _activeViewerSegment,
        progress: _segmentProgress,
        paused: _isViewerPaused,
        transitioning: _isStoryTransitioning,
        transitionAnimation: _storyTransitionAnimation,
        transitionDirection: _storyTransitionDirection,
        transitioningTo: pendingStory,
        transitionTargetSegment: _storyTransitionTargetSegment,
        onNext: _advanceSegment,
        onPrevious: _previousSegment,
        onClose: _exitViewer,
        onTogglePause: _togglePause,
        onReact: (reaction) => _showSuccess('Sent ${reaction.name} reaction'),
        onOpenInsights: _openInsights,
        showInsightsButton: widget.showInsightsButton,
      ),
      StoryVerseStage.insights => _StoryVerseInsightsStage(
        story: storyForViewer!,
        analytics: _mockAnalytics,
        onBack: () {
          setState(() {
            _stage = StoryVerseStage.viewer;
          });
        },
      ),
    };

    return WillPopScope(
      onWillPop: _handleWillPop,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        child: child,
      ),
    );
  }

  StoryVerseOverlay _cloneOverlay(StoryVerseOverlay overlay) {
    return StoryVerseOverlay(
      id: overlay.id,
      type: overlay.type,
      label: overlay.label,
      position: overlay.position,
      metadata: Map<String, dynamic>.from(overlay.metadata),
      color: overlay.color,
      size: overlay.size,
    );
  }

  void _addOverlay(StoryVerseClip clip, StoryVerseOverlay overlay) {
    setState(() {
      final index = _draft.clips.indexWhere((element) => element.id == clip.id);
      if (index == -1) return;
      _draft.clips[index].overlays.add(_cloneOverlay(overlay));
    });
  }

  void _updateOverlayPosition(
    StoryVerseClip clip,
    String overlayId,
    Offset delta,
  ) {
    setState(() {
      final storyClip = _draft.clips.firstWhere(
        (element) => element.id == clip.id,
      );
      final overlay = storyClip.overlays.firstWhere(
        (element) => element.id == overlayId,
      );
      overlay.position += delta;
    });
  }

  void _removeOverlay(StoryVerseClip clip, String overlayId) {
    setState(() {
      final storyClip = _draft.clips.firstWhere(
        (element) => element.id == clip.id,
      );
      storyClip.overlays.removeWhere((element) => element.id == overlayId);
    });
  }

  StoryVerseAnalytics get _mockAnalytics => StoryVerseAnalytics(
    viewCount: 1823,
    replies: 96,
    reactions: 534,
    averageWatch: const Duration(seconds: 12),
    shares: 211,
    reach: 2560,
    discoverySources: const {
      'Feed': 980,
      'Explore': 620,
      'DM': 450,
      'Profile': 220,
    },
  );

  String _generateId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(999)}';
}

class _StoryVerseEntryStage extends StatelessWidget {
  const _StoryVerseEntryStage({
    required this.onStartCapture,
    required this.onOpenStory,
    required this.pulseAnimation,
    required this.stories,
  });

  final void Function(StoryVerseMode mode) onStartCapture;
  final void Function(StoryVerseStory story) onOpenStory;
  final AnimationController pulseAnimation;
  final List<StoryVerseStory> stories;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('StoryVerse'),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Highlight manager coming soon.')),
              );
            },
            icon: const Icon(Icons.auto_awesome_motion_rounded),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 132,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _YourStoryBubble(
                      controller: pulseAnimation,
                      onTap: () => onStartCapture(StoryVerseMode.photo),
                      onLongPress: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Story settings coming soon.'),
                          ),
                        );
                      },
                    );
                  }

                  final story = stories[index - 1];
                  return _StoryBubble(
                    story: story,
                    onTap: () => onOpenStory(story),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: stories.length + 1,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _SuggestionCard(
                      title: '💡 Create from today\'s photos',
                      subtitle: 'AI picked 4 highlights from your gallery',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'AI auto story composer coming soon.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SuggestionCard(
                      title: '🎵 Mood-based theme',
                      subtitle: 'Build a chill story with matching soundtrack',
                      onTap: () => onStartCapture(StoryVerseMode.video),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final story = stories[index % stories.length];
                return GestureDetector(
                  onTap: () => onOpenStory(story),
                  child: _StoryPreviewCard(story: story),
                );
              }, childCount: stories.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 0.72,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => onStartCapture(StoryVerseMode.photo),
        backgroundColor: kPrimary,
        label: const Text('Create Story'),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _StoryVerseCaptureStage extends StatefulWidget {
  const _StoryVerseCaptureStage({
    required this.mode,
    required this.onBack,
    required this.onCapture,
    required this.onModeChanged,
    required this.cameraController,
    required this.cameraInitFuture,
    required this.cameraError,
    required this.isCameraInitializing,
    required this.isCameraReady,
    required this.isRecordingVideo,
    required this.zoomLevel,
    required this.minZoom,
    required this.maxZoom,
    required this.onFlipCamera,
    required this.onOpenGallery,
    required this.onZoomChanged,
    required this.onRetryCamera,
  });

  final StoryVerseMode mode;
  final VoidCallback onBack;
  final Future<void> Function() onCapture;
  final ValueChanged<StoryVerseMode> onModeChanged;
  final CameraController? cameraController;
  final Future<void>? cameraInitFuture;
  final String? cameraError;
  final bool isCameraInitializing;
  final bool isCameraReady;
  final bool isRecordingVideo;
  final double zoomLevel;
  final double minZoom;
  final double maxZoom;
  final Future<void> Function() onFlipCamera;
  final Future<void> Function() onOpenGallery;
  final ValueChanged<double> onZoomChanged;
  final Future<void> Function() onRetryCamera;

  @override
  State<_StoryVerseCaptureStage> createState() =>
      _StoryVerseCaptureStageState();
}

class _StoryVerseCaptureStageState extends State<_StoryVerseCaptureStage> {
  double? _zoomAtGestureStart;

  void _handleScaleStart(ScaleStartDetails details) {
    if (details.pointerCount < 2) return;
    _zoomAtGestureStart = widget.zoomLevel;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount < 2 || _zoomAtGestureStart == null) return;
    final nextZoom = (_zoomAtGestureStart! * details.scale).clamp(
      widget.minZoom,
      widget.maxZoom,
    );
    widget.onZoomChanged(nextZoom);
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _zoomAtGestureStart = null;
  }

  String get _modeHelpText {
    switch (widget.mode) {
      case StoryVerseMode.photo:
        return 'Tap to capture a photo';
      case StoryVerseMode.video:
        return widget.isRecordingVideo
            ? 'Tap to stop recording'
            : 'Tap to start recording • pinch to zoom';
      case StoryVerseMode.boomerang:
        return 'Creates an automatic loop clip';
      case StoryVerseMode.text:
        return 'Create a text story on a gradient background';
      case StoryVerseMode.layout:
        return 'Combine multiple shots into one collage';
    }
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.mode == StoryVerseMode.video
                ? Icons.videocam_rounded
                : widget.mode == StoryVerseMode.text
                ? Icons.text_fields_rounded
                : Icons.camera_alt_rounded,
            size: 72,
            color: Colors.white70,
          ),
          const SizedBox(height: 16),
          Text(
            _modeHelpText,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraContent() {
    if (widget.cameraError != null) {
      return _CaptureFallback(
        icon: Icons.videocam_off_rounded,
        title: 'Camera unavailable',
        message: widget.cameraError!,
        actionLabel: 'Retry',
        onAction: widget.onRetryCamera,
      );
    }

    final future = widget.cameraInitFuture;
    if (future == null) {
      return _buildPlaceholder();
    }

    return FutureBuilder<void>(
      future: future,
      builder: (context, snapshot) {
        if (!widget.isCameraReady ||
            snapshot.connectionState != ConnectionState.done) {
          if (widget.isCameraInitializing) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          return _buildPlaceholder();
        }

        final controller = widget.cameraController;
        if (controller == null) {
          return _buildPlaceholder();
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          onScaleEnd: _handleScaleEnd,
          child: CameraPreview(controller),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            const Color(0xFF0B0E13), // Dark background
                            const Color(0xFF1A1D24), // Slightly lighter
                          ]
                        : [
                            const Color(0xFF1A1D24), // Dark for light mode too
                            const Color(0xFF2A2D34),
                          ],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                _CaptureTopBar(onBack: widget.onBack),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.black.withOpacity(0.5),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          _buildCameraContent(),
                          if (widget.mode == StoryVerseMode.video &&
                              widget.isRecordingVideo)
                            Positioned(
                              top: 20,
                              left: 20,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'REC',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 24,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _modeHelpText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          if (widget.isCameraReady)
                            Positioned(
                              right: 18,
                              bottom: 40,
                              child: _LiveLightSlider(
                                value: widget.zoomLevel,
                                minValue: widget.minZoom,
                                maxValue: widget.maxZoom,
                                onChanged: widget.onZoomChanged,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                _CaptureBottomBar(
                  mode: widget.mode,
                  onCapture: widget.onCapture,
                  onModeChanged: widget.onModeChanged,
                  onFlipCamera: widget.onFlipCamera,
                  onOpenGallery: widget.onOpenGallery,
                  isRecording: widget.isRecordingVideo,
                ),
              ],
            ),
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.music_note_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Auto beat-sync ready',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryVerseEditorStage extends StatefulWidget {
  const _StoryVerseEditorStage({
    required this.draft,
    required this.activeIndex,
    required this.onClipChanged,
    required this.onClipRemoved,
    required this.onClipDuplicated,
    required this.onAddOverlay,
    required this.onUpdateOverlayPosition,
    required this.onRemoveOverlay,
    required this.onShare,
    required this.onBack,
    required this.onExit,
  });

  final StoryVerseDraft draft;
  final int activeIndex;
  final ValueChanged<StoryVerseClip> onClipChanged;
  final void Function(String clipId) onClipRemoved;
  final void Function(StoryVerseClip clip) onClipDuplicated;
  final void Function(StoryVerseClip clip, StoryVerseOverlay overlay)
  onAddOverlay;
  final void Function(StoryVerseClip clip, String overlayId, Offset delta)
  onUpdateOverlayPosition;
  final void Function(StoryVerseClip clip, String overlayId) onRemoveOverlay;
  final VoidCallback onShare;
  final VoidCallback onBack;
  final VoidCallback onExit;

  @override
  State<_StoryVerseEditorStage> createState() => _StoryVerseEditorStageState();
}

class _StoryVerseEditorStageState extends State<_StoryVerseEditorStage> {
  StoryVerseClip get selectedClip => widget.draft.clips[widget.activeIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: widget.onExit,
        ),
        actions: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: 'Retake',
          ),
          IconButton(
            onPressed: () => widget.onClipDuplicated(selectedClip),
            icon: const Icon(Icons.copy_rounded),
          ),
          IconButton(
            onPressed: () => widget.onClipRemoved(selectedClip.id),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
          const SizedBox(width: 8),
        ],
        title: const Text('Edit story'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black, Colors.black.withOpacity(0.4)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (selectedClip.imageBytes != null)
                        Image.memory(
                          selectedClip.imageBytes!,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [kPrimary, kPrimary.withOpacity(0.7)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            final overlay = _selectedOverlay;
                            if (overlay != null) {
                              widget.onUpdateOverlayPosition(
                                selectedClip,
                                overlay.id,
                                details.delta,
                              );
                            }
                          },
                          onLongPress: () {
                            final overlay = _selectedOverlay;
                            if (overlay != null) {
                              widget.onRemoveOverlay(selectedClip, overlay.id);
                            }
                          },
                          child: Stack(
                            children: [
                              for (final overlay in selectedClip.overlays)
                                Positioned(
                                  left: overlay.position.dx,
                                  top: overlay.position.dy,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _activeOverlayId = overlay.id,
                                    ),
                                    child: _OverlayChip(
                                      overlay: overlay,
                                      isActive: overlay.id == _activeOverlayId,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 18,
                        right: 18,
                        child: _MoodTag(mood: selectedClip.mood ?? 'Freestyle'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _EditorToolbar(
            clip: selectedClip,
            onClipChanged: widget.onClipChanged,
            onAddOverlay: (overlay) =>
                widget.onAddOverlay(selectedClip, overlay),
          ),
          _TimelineScroller(
            draft: widget.draft,
            activeIndex: widget.activeIndex,
            onSelect: (index) {
              setState(() {
                _activeOverlayId = null;
              });
              widget.onClipChanged(widget.draft.clips[index]);
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: FilledButton.icon(
              onPressed: widget.onShare,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: kPrimary,
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  String? _activeOverlayId;

  StoryVerseOverlay? get _selectedOverlay {
    if (_activeOverlayId == null) return null;
    return selectedClip.overlays.firstWhere(
      (overlay) => overlay.id == _activeOverlayId,
    );
  }
}

class _StoryVerseShareStage extends StatelessWidget {
  const _StoryVerseShareStage({
    required this.draft,
    required this.onBack,
    required this.onPublish,
  });

  final StoryVerseDraft draft;
  final VoidCallback onBack;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final clip = draft.clips.last;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Share'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (clip.imageBytes != null)
                      Image.memory(clip.imageBytes!, fit: BoxFit.cover)
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPrimary, kPrimary.withOpacity(0.3)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 18,
                      left: 18,
                      child: _MoodTag(mood: clip.mood ?? 'Freestyle'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Audience', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: StoryVerseAudience.values.map((audience) {
                final selected = draft.audience == audience;
                return ChoiceChip(
                  label: Text(_audienceLabel(audience)),
                  selected: selected,
                  onSelected: (_) {
                    draft.audience = audience;
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            _ShareToggle(
              label: 'Allow replies',
              subtitle: 'Let viewers respond with messages',
              value: draft.allowReplies,
              onChanged: (value) => draft.allowReplies = value,
            ),
            _ShareToggle(
              label: 'Allow sharing',
              subtitle: 'Viewers can forward to friends',
              value: draft.allowSharing,
              onChanged: (value) => draft.allowSharing = value,
            ),
            _ShareToggle(
              label: 'Save to archive',
              subtitle: 'Keep a copy after 24 hours',
              value: draft.saveToArchive,
              onChanged: (value) => draft.saveToArchive = value,
            ),
            _ShareToggle(
              label: 'Add to highlight',
              subtitle: 'Pin to your profile highlights',
              value: draft.addToHighlight,
              onChanged: (value) => draft.addToHighlight = value,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onPublish,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Share story'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _audienceLabel(StoryVerseAudience audience) {
    switch (audience) {
      case StoryVerseAudience.everyone:
        return 'Everyone';
      case StoryVerseAudience.followers:
        return 'Followers';
      case StoryVerseAudience.closeFriends:
        return 'Close friends';
      case StoryVerseAudience.custom:
        return 'Custom';
    }
  }
}

class _StoryVerseViewerStage extends StatelessWidget {
  const _StoryVerseViewerStage({
    required this.story,
    required this.activeIndex,
    required this.progress,
    required this.paused,
    required this.transitioning,
    required this.transitionAnimation,
    required this.transitionDirection,
    required this.transitioningTo,
    required this.transitionTargetSegment,
    required this.onNext,
    required this.onPrevious,
    required this.onClose,
    required this.onTogglePause,
    required this.onReact,
    required this.onOpenInsights,
    this.showInsightsButton = true,
  });

  final StoryVerseStory story;
  final int activeIndex;
  final double progress;
  final bool paused;
  final bool transitioning;
  final Animation<double> transitionAnimation;
  final int transitionDirection;
  final StoryVerseStory? transitioningTo;
  final int transitionTargetSegment;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onClose;
  final VoidCallback onTogglePause;
  final void Function(StoryVerseReactionType reaction) onReact;
  final VoidCallback onOpenInsights;
  final bool showInsightsButton;

  @override
  Widget build(BuildContext context) {
    final clip = story.clips[activeIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      body: IgnorePointer(
        ignoring: transitioning,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // Single tap on close icon area (top right) to exit
            // Otherwise handle segment navigation
          },
          onTapUp: (details) {
            final width = MediaQuery.of(context).size.width;
            final tapX = details.localPosition.dx;
            final tapY = details.localPosition.dy;

            // Check if tap is on close button area (top right)
            if (tapX > width - 80 && tapY < 120) {
              onClose();
              return;
            }

            // Otherwise handle left/right navigation
            if (tapX > width / 2) {
              onNext();
            } else {
              onPrevious();
            }
          },
          onLongPress: onTogglePause,
          onLongPressUp: onTogglePause,
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! > 900) {
              onClose();
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final slideProgress = transitioning
                  ? transitionAnimation.value
                  : 0.0;

              final currentContent = Transform.translate(
                offset: Offset(
                  transitioning
                      ? -transitionDirection * slideProgress * width
                      : 0,
                  0,
                ),
                child: Opacity(
                  opacity: transitioning
                      ? (1 - slideProgress * 0.25).clamp(0.0, 1.0)
                      : 1.0,
                  child: _buildStoryContent(
                    context: context,
                    story: story,
                    clip: clip,
                    progress: progress,
                    paused: paused && !transitioning,
                  ),
                ),
              );

              final children = <Widget>[currentContent];

              if (transitioning && transitioningTo != null) {
                final incomingStory = transitioningTo!;
                final clips = incomingStory.clips;
                final targetSegment = clips.isEmpty
                    ? 0
                    : transitionTargetSegment.clamp(0, clips.length - 1);
                final incomingClip = clips.isNotEmpty
                    ? clips[targetSegment]
                    : clip;

                children.add(
                  Transform.translate(
                    offset: Offset(
                      transitionDirection * (1 - slideProgress) * width,
                      0,
                    ),
                    child: Opacity(
                      opacity: slideProgress.clamp(0.0, 1.0),
                      child: _buildStoryContent(
                        context: context,
                        story: incomingStory,
                        clip: incomingClip,
                        progress: 0,
                        paused: false,
                      ),
                    ),
                  ),
                );
              }

              return Stack(fit: StackFit.expand, children: children);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStoryContent({
    required BuildContext context,
    required StoryVerseStory story,
    required StoryVerseClip clip,
    required double progress,
    required bool paused,
  }) {
    final moodText = story.mood.trim();
    final metadataText = moodText.isEmpty
        ? _timeAgo(story.timestamp)
        : '${_timeAgo(story.timestamp)} • $moodText';

    return Stack(
      fit: StackFit.expand,
      children: [
        if (clip.imageBytes != null)
          Image.memory(clip.imageBytes!, fit: BoxFit.cover)
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimary.withOpacity(0.8), kPrimary.withOpacity(0.4)],
              ),
            ),
          ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent, Colors.black54],
            ),
          ),
        ),
        Positioned(
          top: 48,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(story.ownerAvatar),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.ownerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        metadataText,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (showInsightsButton)
                    IconButton(
                      onPressed: onOpenInsights,
                      icon: const Icon(
                        Icons.equalizer_rounded,
                        color: Colors.white,
                      ),
                    ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 80,
          left: 16,
          right: 16,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.38),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.message_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Send message...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onReact(StoryVerseReactionType.love),
                      icon: Icon(Icons.favorite, color: kPrimary),
                    ),
                    IconButton(
                      onPressed: () => onReact(StoryVerseReactionType.fire),
                      icon: Icon(Icons.local_fire_department, color: kPrimary),
                    ),
                    IconButton(
                      onPressed: () => onReact(StoryVerseReactionType.laugh),
                      icon: const Icon(
                        Icons.emoji_emotions,
                        color: Colors.yellowAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: StoryVerseReactionType.values
                    .map(
                      (reaction) => IconButton(
                        onPressed: () => onReact(reaction),
                        icon: Icon(
                          _reactionIcon(reaction),
                          color: Colors.white,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        if (paused)
          const Center(
            child: Icon(
              Icons.pause_circle_filled,
              color: Colors.white70,
              size: 64,
            ),
          ),
        if (transitioning) _SwipeIndicator(direction: transitionDirection),
      ],
    );
  }

  static String _timeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }

  static IconData _reactionIcon(StoryVerseReactionType reaction) {
    switch (reaction) {
      case StoryVerseReactionType.love:
        return Icons.favorite_rounded;
      case StoryVerseReactionType.fire:
        return Icons.local_fire_department_rounded;
      case StoryVerseReactionType.laugh:
        return Icons.emoji_emotions_rounded;
      case StoryVerseReactionType.wow:
        return Icons.auto_awesome_rounded;
      case StoryVerseReactionType.celebrate:
        return Icons.celebration_rounded;
      case StoryVerseReactionType.sad:
        return Icons.sentiment_dissatisfied_rounded;
    }
  }
}

class _SwipeIndicator extends StatelessWidget {
  const _SwipeIndicator({required this.direction});

  final int direction;

  @override
  Widget build(BuildContext context) {
    final isForward = direction >= 0;
    return IgnorePointer(
      child: Container(
        color: Colors.black.withOpacity(0.25),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: isForward
                ? [
                    _buildText('Next'),
                    const SizedBox(width: 12),
                    _buildArrow(Icons.keyboard_arrow_right_rounded),
                  ]
                : [
                    _buildArrow(Icons.keyboard_arrow_left_rounded),
                    const SizedBox(width: 12),
                    _buildText('Previous'),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildArrow(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(icon, color: Colors.white, size: 36),
    );
  }

  Widget _buildText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
    );
  }
}

class _StoryVerseInsightsStage extends StatelessWidget {
  const _StoryVerseInsightsStage({
    required this.story,
    required this.analytics,
    required this.onBack,
  });

  final StoryVerseStory story;
  final StoryVerseAnalytics analytics;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Insights'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundImage: NetworkImage(story.ownerAvatar)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.ownerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Posted ${_StoryVerseViewerStage._timeAgo(story.timestamp)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _MoodTag(mood: story.mood),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InsightTile(
                  title: 'Views',
                  value: analytics.viewCount.toString(),
                  icon: Icons.visibility_rounded,
                ),
                _InsightTile(
                  title: 'Replies',
                  value: analytics.replies.toString(),
                  icon: Icons.chat_bubble_rounded,
                ),
                _InsightTile(
                  title: 'Reactions',
                  value: analytics.reactions.toString(),
                  icon: Icons.favorite_rounded,
                ),
                _InsightTile(
                  title: 'Shares',
                  value: analytics.shares.toString(),
                  icon: Icons.send_rounded,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white.withOpacity(0.04),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_rounded, color: Colors.white70),
                  const SizedBox(width: 12),
                  Text(
                    'Avg watch ${analytics.averageWatch.inSeconds}s',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Discovery',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            ...analytics.discoverySources.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    Text(
                      entry.value.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting analytics soon.')),
                );
              },
              icon: const Icon(Icons.file_download_done_rounded),
              label: const Text('Export report'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodTag extends StatelessWidget {
  const _MoodTag({required this.mood});

  final String mood;

  @override
  Widget build(BuildContext context) {
    final text = mood.trim();
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [kPrimary, kPrimary.withOpacity(0.7)]),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ShareToggle extends StatefulWidget {
  const _ShareToggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<_ShareToggle> createState() => _ShareToggleState();
}

class _ShareToggleState extends State<_ShareToggle> {
  late bool _value = widget.value;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: _value,
      onChanged: (value) {
        setState(() => _value = value);
        widget.onChanged(value);
      },
      activeColor: kPrimary,
      title: Text(widget.label),
      subtitle: Text(widget.subtitle),
    );
  }
}

class _StoryVerseMockData {
  static List<StoryVerseStory> get stories {
    // Return empty list - stories should come from database
    return [];
  }
}

class _CaptureTopBar extends StatelessWidget {
  const _CaptureTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Music picker coming soon.')),
              );
            },
            icon: const Icon(Icons.music_note_rounded, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Timer controls coming soon.')),
              );
            },
            icon: const Icon(Icons.timer_rounded, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filters coming soon.')),
              );
            },
            icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _CaptureBottomBar extends StatelessWidget {
  const _CaptureBottomBar({
    required this.mode,
    required this.onCapture,
    required this.onModeChanged,
    required this.onFlipCamera,
    required this.onOpenGallery,
    required this.isRecording,
  });

  final StoryVerseMode mode;
  final Future<void> Function() onCapture;
  final ValueChanged<StoryVerseMode> onModeChanged;
  final Future<void> Function() onFlipCamera;
  final Future<void> Function() onOpenGallery;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    final modes = StoryVerseMode.values;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => onFlipCamera(),
                icon: const Icon(
                  Icons.flip_camera_ios_rounded,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onCapture,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: isRecording && mode == StoryVerseMode.video ? 78 : 84,
                  height: isRecording && mode == StoryVerseMode.video ? 78 : 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRecording && mode == StoryVerseMode.video
                          ? Theme.of(context).colorScheme.error
                          : null,
                      gradient: isRecording && mode == StoryVerseMode.video
                          ? null
                          : LinearGradient(
                              colors: [kPrimary, kPrimary.withOpacity(0.7)],
                            ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => onOpenGallery(),
                icon: const Icon(
                  Icons.photo_library_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: modes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final item = modes[index];
                final isActive = mode == item;
                return GestureDetector(
                  onTap: () => onModeChanged(item),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withOpacity(0.16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      item.name.toUpperCase(),
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white60,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveLightSlider extends StatelessWidget {
  const _LiveLightSlider({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
  });

  final double value;
  final double minValue;
  final double maxValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveMax = maxValue <= minValue ? minValue + 0.0001 : maxValue;
    final clamped = value.clamp(minValue, effectiveMax).toDouble();
    return RotatedBox(
      quarterTurns: 3,
      child: SizedBox(
        width: 140,
        child: Slider(
          value: clamped,
          min: minValue,
          max: effectiveMax,
          inactiveColor: Colors.white12,
          activeColor: Colors.white,
          onChanged: (newValue) =>
              onChanged(newValue.clamp(minValue, effectiveMax).toDouble()),
        ),
      ),
    );
  }
}

class _CaptureFallback extends StatelessWidget {
  const _CaptureFallback({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.55),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: Colors.white70),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => onAction(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayChip extends StatelessWidget {
  const _OverlayChip({required this.overlay, required this.isActive});

  final StoryVerseOverlay overlay;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: isActive ? 1.05 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(18),
          border: isActive ? Border.all(color: Colors.white, width: 1.2) : null,
        ),
        child: Text(
          overlay.label,
          style: TextStyle(
            color: overlay.color ?? Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({
    required this.clip,
    required this.onClipChanged,
    required this.onAddOverlay,
  });

  final StoryVerseClip clip;
  final ValueChanged<StoryVerseClip> onClipChanged;
  final ValueChanged<StoryVerseOverlay> onAddOverlay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _EditorToolButton(
                icon: Icons.text_fields_rounded,
                label: 'Text',
                onTap: () {
                  _openTextComposer(context);
                },
              ),
              _EditorToolButton(
                icon: Icons.brush_rounded,
                label: 'Doodle',
                onTap: () => _showComingSoon(context, 'Doodle tool'),
              ),
              _EditorToolButton(
                icon: Icons.music_note_rounded,
                label: 'Music',
                onTap: () => _openMusicPicker(context),
              ),
              _EditorToolButton(
                icon: Icons.emoji_emotions_rounded,
                label: 'Stickers',
                onTap: () => _openStickerPanel(context),
              ),
              _EditorToolButton(
                icon: Icons.auto_awesome_mosaic_rounded,
                label: 'Filters',
                onTap: () => _openFilterPanel(context),
              ),
              _EditorToolButton(
                icon: Icons.grid_view_rounded,
                label: 'Templates',
                onTap: () => _showComingSoon(context, 'Templates'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: clip.caption ?? ''),
                  onChanged: (value) {
                    onClipChanged(clip.copyWith(caption: value));
                  },
                  decoration: InputDecoration(
                    hintText: 'Write a caption... (auto caption coming soon)',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _EditorToolButton(
                icon: Icons.bolt_rounded,
                label: 'AI assist',
                onTap: () => _showComingSoon(context, 'AI layout suggestions'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openTextComposer(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add text'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Say something...'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                final overlay = StoryVerseOverlay(
                  id: 'overlay-${DateTime.now().microsecondsSinceEpoch}',
                  type: StoryVerseOverlayType.text,
                  label: value,
                  position: const Offset(120, 220),
                  color: Colors.white,
                );
                onAddOverlay(overlay);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _openMusicPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final tracks = _StoryVerseMockData.stories
            .map((e) => e.music)
            .whereType<StoryVerseMusicTrack>()
            .toList();
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trending tracks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...tracks.map(
                (track) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    onClipChanged(clip.copyWith(music: track));
                    Navigator.pop(context);
                  },
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(track.artworkUrl),
                  ),
                  title: Text(
                    track.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    track.artist,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openStickerPanel(BuildContext context) {
    final stickers = ['🔥', '🎉', '💫', '😂', '😍', '👏', '🦄', '🌈'];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 40),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: stickers
                .map(
                  (sticker) => GestureDetector(
                    onTap: () {
                      onAddOverlay(
                        StoryVerseOverlay(
                          id: 'overlay-${DateTime.now().microsecondsSinceEpoch}',
                          type: StoryVerseOverlayType.sticker,
                          label: sticker,
                          position: const Offset(160, 260),
                        ),
                      );
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          sticker,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  void _openFilterPanel(BuildContext context) {
    final filters = ['Cinematic', 'Dreamy', 'Neon', 'Retro', 'Faded'];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 40),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: filters
                .map(
                  (filter) => ChoiceChip(
                    label: Text(filter),
                    selected: clip.filters.contains(filter),
                    onSelected: (_) {
                      final filtersCopy = Set<String>.from(clip.filters);
                      if (filtersCopy.contains(filter)) {
                        filtersCopy.remove(filter);
                      } else {
                        filtersCopy.add(filter);
                      }
                      onClipChanged(
                        clip.copyWith(filters: filtersCopy.toList()),
                      );
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature coming soon.')));
  }
}

class _EditorToolButton extends StatelessWidget {
  const _EditorToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimary, kPrimary.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _TimelineScroller extends StatelessWidget {
  const _TimelineScroller({
    required this.draft,
    required this.activeIndex,
    required this.onSelect,
  });

  final StoryVerseDraft draft;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final clip = draft.clips[index];
          final isActive = index == activeIndex;
          return GestureDetector(
            onTap: () => onSelect(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isActive ? Colors.white : Colors.white24,
                  width: isActive ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: clip.imageBytes != null
                    ? Image.memory(clip.imageBytes!, fit: BoxFit.cover)
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kPrimary.withOpacity(0.3),
                              kPrimary.withOpacity(0.1),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Center(
                          child: Icon(switch (clip.mode) {
                            StoryVerseMode.photo => Icons.camera_alt_rounded,
                            StoryVerseMode.video => Icons.videocam_rounded,
                            StoryVerseMode.boomerang => Icons.loop_rounded,
                            StoryVerseMode.text => Icons.text_fields_rounded,
                            StoryVerseMode.layout => Icons.grid_view_rounded,
                          }, color: Colors.white70),
                        ),
                      ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: draft.clips.length,
      ),
    );
  }
}

class _YourStoryBubble extends StatelessWidget {
  const _YourStoryBubble({
    required this.controller,
    required this.onTap,
    required this.onLongPress,
  });

  final AnimationController controller;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.95,
        end: 1.05,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut)),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          width: 92,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimary, kPrimary.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(36),
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white12,
                  child: Icon(Icons.add_rounded, color: Colors.white),
                ),
                SizedBox(height: 6),
                Text(
                  'Your Story',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({required this.story, required this.onTap});

  final StoryVerseStory story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: story.hasNewContent
                    ? [kPrimary, kPrimary.withOpacity(0.7)]
                    : [
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                        Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(0.7),
                      ],
              ),
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundImage: NetworkImage(story.ownerAvatar),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            story.ownerName,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [kPrimary, kPrimary.withOpacity(0.7)],
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryPreviewCard extends StatelessWidget {
  const _StoryPreviewCard({required this.story});

  final StoryVerseStory story;

  @override
  Widget build(BuildContext context) {
    final moodText = story.mood.trim();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHighest,
            Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: story.clips.first.imageBytes != null
                  ? Image.memory(
                      story.clips.first.imageBytes!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kPrimary, kPrimary.withOpacity(0.7)],
                        ),
                      ),
                    ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Colors.black87, Colors.transparent.withOpacity(0.1)],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.ownerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (moodText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    moodText,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [kPrimary, kPrimary.withOpacity(0.7)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white70),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
