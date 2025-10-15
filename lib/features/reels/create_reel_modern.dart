import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

/// Identifies where a recorded segment originated.
enum ReelSegmentSource { camera, gallery }

/// Represents a single reel clip with basic metadata.
class ReelSegment {
  ReelSegment({
    required this.path,
    required this.duration,
    required this.source,
    required this.captureSpeed,
  });

  final String path;
  final Duration duration;
  final ReelSegmentSource source;
  final double captureSpeed;

  String get formattedDuration {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(1, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Modern reel creation screen with capture, editing, and preview flows.
class CreateReelModern extends StatefulWidget {
  const CreateReelModern({
    super.key,
    this.preselectedAudioId,
    this.isRemix = false,
    this.initialClips = const [],
  });

  final String? preselectedAudioId;
  final bool isRemix;
  final List<ReelSegment> initialClips;

  @override
  State<CreateReelModern> createState() => _CreateReelModernState();
}

/// Represents a segment with editing metadata applied in the editor.
class ReelEditedSegment {
  ReelEditedSegment({
    required this.base,
    Duration? trimStart,
    Duration? trimEnd,
    double volume = 1.0,
    Duration? coverFrame,
  }) : trimStart = trimStart ?? Duration.zero,
       trimEnd = trimEnd ?? base.duration,
       volume = volume.clamp(0.0, 1.0).toDouble(),
       coverFrame = coverFrame ?? Duration.zero;

  final ReelSegment base;
  final Duration trimStart;
  final Duration trimEnd;
  final double volume;
  final Duration coverFrame;

  String get displayLabel => base.formattedDuration;
  String get path => base.path;

  Duration get trimmedDuration {
    final duration = trimEnd - trimStart;
    return duration.isNegative ? Duration.zero : duration;
  }

  ReelEditedSegment copyWith({
    Duration? trimStart,
    Duration? trimEnd,
    double? volume,
    Duration? coverFrame,
  }) {
    final updatedStart = trimStart ?? this.trimStart;
    final updatedEnd = trimEnd ?? this.trimEnd;
    final safeEnd = updatedEnd < updatedStart ? updatedStart : updatedEnd;
    return ReelEditedSegment(
      base: base,
      trimStart: updatedStart,
      trimEnd: safeEnd,
      volume: (volume ?? this.volume).clamp(0.0, 1.0).toDouble(),
      coverFrame: coverFrame ?? this.coverFrame,
    );
  }
}

class _CreateReelModernState extends State<CreateReelModern>
    with WidgetsBindingObserver {
  static const List<String> _speedLabels = ['1x', '2x', '3x'];
  static const List<double> _speedValues = [1.0, 2.0, 3.0];
  static const List<int> _timerOptions = [0, 3, 10];
  static const List<int> _lengthOptions = [15, 30, 60, 90];

  final ImagePicker _picker = ImagePicker();

  List<CameraDescription> _availableCameras = const [];
  CameraController? _cameraController;
  Timer? _countdownTimer;
  int? _countdownValue;
  Directory? _reelsDirectory;
  DateTime? _recordingStartedAt;

  bool _cameraUnavailable = false;
  bool _isCameraReady = false;
  bool _isRecording = false;
  bool _isProcessingSegment = false;
  bool _flashOn = false;
  bool _flashSupported = true;
  bool _showGrid = false;
  bool _isEditorOpen = false;

  int _activeCameraIndex = 0;
  int _selectedSpeedIndex = 0;
  int _selectedTimerIndex = 0;
  int _selectedLengthIndex = 1;

  late String _selectedAudio;
  late List<ReelSegment> _segments;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedAudio = widget.preselectedAudioId ?? 'Original Sound';
    _segments = List<ReelSegment>.from(widget.initialClips);
    _initialiseCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !_isCameraReady) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _recreateCameraController();
    }
  }

  Future<void> _initialiseCamera() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        setState(() => _cameraUnavailable = true);
        return;
      }
      await _setupCameraController(_availableCameras.first);
    } on CameraException {
      if (!mounted) return;
      setState(() => _cameraUnavailable = true);
    }
  }

  Future<void> _recreateCameraController() async {
    if (_availableCameras.isEmpty) return;
    final index = _activeCameraIndex.clamp(0, _availableCameras.length - 1);
    await _setupCameraController(_availableCameras[index]);
  }

  Future<void> _setupCameraController(CameraDescription description) async {
    final previous = _cameraController;
    if (mounted) {
      setState(() {
        _isCameraReady = false;
        _cameraController = null;
      });
    }
    await previous?.dispose();

    final controller = CameraController(
      description,
      ResolutionPreset.max,
      enableAudio: true,
    );

    try {
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      final supportsFlash =
          controller.description.lensDirection != CameraLensDirection.front;
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
        _cameraUnavailable = false;
        _flashOn = false;
        _flashSupported = supportsFlash;
      });
      await _applySelectedZoom();
    } on CameraException {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _cameraController = null;
        _isCameraReady = false;
        _cameraUnavailable = true;
        _flashSupported = false;
      });
    }
  }

  Future<void> _applySelectedZoom() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();
      final desired = _speedValues[_selectedSpeedIndex];
      final clamped = desired.clamp(minZoom, maxZoom).toDouble();
      await controller.setZoomLevel(clamped);
    } on CameraException {
      // Ignore zoom errors silently to avoid disrupting capture.
    }
  }

  void _onSelectSpeedIndex(int index) {
    setState(() => _selectedSpeedIndex = index);
    _applySelectedZoom();
  }

  Future<Directory> _ensureReelsDirectory() async {
    if (_reelsDirectory != null) {
      return _reelsDirectory!;
    }
    final storageRoot = await getApplicationDocumentsDirectory();
    final directory = Directory('${storageRoot.path}/reels');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    _reelsDirectory = directory;
    return directory;
  }

  Future<void> _toggleRecording() async {
    final controller = _cameraController;
    if (_isProcessingSegment ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    if (_isRecording) {
      try {
        final file = await controller.stopVideoRecording();
        if (!mounted) return;
        setState(() => _isProcessingSegment = true);
        final segment = await _createSegment(file, ReelSegmentSource.camera);
        if (!mounted) return;
        setState(() {
          _isRecording = false;
          _recordingStartedAt = null;
          _segments.add(segment);
          _isProcessingSegment = false;
        });
        _maybeNavigateToEditor();
      } on CameraException {
        if (!mounted) return;
        setState(() {
          _isRecording = false;
          _recordingStartedAt = null;
          _isProcessingSegment = false;
        });
        _showSnackBar('Failed to save recording.');
      }
      return;
    }

    final timerValue = _timerOptions[_selectedTimerIndex];
    if (timerValue > 0) {
      _startCountdown(timerValue);
    } else {
      await _beginRecording(controller);
    }
  }

  void _startCountdown(int seconds) {
    setState(() => _countdownValue = seconds);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final nextValue = (_countdownValue ?? 1) - 1;
      if (nextValue <= 0) {
        timer.cancel();
        setState(() => _countdownValue = null);
        final controller = _cameraController;
        if (controller != null) {
          await _beginRecording(controller);
        }
      } else {
        setState(() => _countdownValue = nextValue);
      }
    });
  }

  Future<void> _beginRecording(CameraController controller) async {
    try {
      await controller.prepareForVideoRecording();
      await controller.startVideoRecording();
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _recordingStartedAt = DateTime.now();
      });
    } on CameraException {
      if (!mounted) return;
      setState(() => _isRecording = false);
      _showSnackBar('Recording could not start.');
    }
  }

  Future<ReelSegment> _createSegment(
    XFile file,
    ReelSegmentSource source,
  ) async {
    final speed = _speedValues[_selectedSpeedIndex];
    final reelsDir = await _ensureReelsDirectory();
    final extension = file.path.contains('.')
        ? '.${file.path.split('.').last}'
        : '.mp4';
    final targetPath =
        '${reelsDir.path}/reel_${DateTime.now().millisecondsSinceEpoch}$extension';
    await file.saveTo(targetPath);

    final probe = VideoPlayerController.file(File(targetPath));
    await probe.initialize();
    final duration = probe.value.duration;
    await probe.dispose();
    return ReelSegment(
      path: targetPath,
      duration: duration,
      source: source,
      captureSpeed: speed,
    );
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2) {
      _showSnackBar('Only one camera available.');
      return;
    }
    final nextIndex = (_activeCameraIndex + 1) % _availableCameras.length;
    setState(() {
      _activeCameraIndex = nextIndex;
      _isCameraReady = false;
    });
    await _setupCameraController(_availableCameras[nextIndex]);
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null) return;
    if (!_flashSupported) {
      _showSnackBar('Flash not available on this camera.');
      return;
    }
    try {
      final nextMode = _flashOn ? FlashMode.off : FlashMode.torch;
      await controller.setFlashMode(nextMode);
      if (!mounted) return;
      setState(() => _flashOn = !_flashOn);
    } on CameraException {
      _showSnackBar('Flash not available on this camera.');
    }
  }

  Future<void> _pickVideoFromGallery() async {
    if (_isProcessingSegment) return;
    try {
      final picked = await _picker.pickVideo(source: ImageSource.gallery);
      if (picked == null) return;
      if (mounted) {
        setState(() => _isProcessingSegment = true);
      }
      final segment = await _createSegment(picked, ReelSegmentSource.gallery);
      if (!mounted) return;
      setState(() {
        _segments.add(segment);
        _isProcessingSegment = false;
      });
      _showSnackBar('Clip added from gallery.');
      _maybeNavigateToEditor();
    } catch (_) {
      if (mounted) {
        setState(() => _isProcessingSegment = false);
      }
      _showSnackBar('Could not import video.');
    }
  }

  void _toggleGrid() => setState(() => _showGrid = !_showGrid);

  void _openTimerPicker() {
    if (_isProcessingSegment) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _TimerPickerSheet(
        optionsInSeconds: _timerOptions,
        selectedIndex: _selectedTimerIndex,
        onSelected: (index) {
          setState(() => _selectedTimerIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openLengthPicker() {
    if (_isProcessingSegment) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LengthPickerSheet(
        optionsInSeconds: _lengthOptions,
        selectedIndex: _selectedLengthIndex,
        onSelected: (index) {
          setState(() => _selectedLengthIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openAudioLibrary() {
    if (_isProcessingSegment) return;
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AudioLibrarySheet(
        selectedAudio: _selectedAudio,
        onAudioSelected: (value) => setState(() => _selectedAudio = value),
      ),
    );
  }

  void _openEffectsSheet() {
    if (_isProcessingSegment) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const EffectsBottomSheet(),
    );
  }

  void _openUploadOptions() {
    if (_isProcessingSegment) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => UploadOptionsSheet(
        onGallerySelected: () {
          Navigator.pop(context);
          _pickVideoFromGallery();
        },
        onVideoLibrarySelected: () {
          Navigator.pop(context);
          _showSnackBar('Video library is not ready yet.');
        },
        onTemplateSelected: (template) {
          Navigator.pop(context);
          _showSnackBar('Template "$template" coming soon.');
        },
      ),
    );
  }

  void _openEditor() {
    if (_isProcessingSegment) return;
    if (_isEditorOpen) return;
    if (_segments.isEmpty) {
      _showSnackBar('Record or import at least one clip first.');
      return;
    }
    _isEditorOpen = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReelEditingModern(
          segments: List<ReelSegment>.from(_segments),
          initialAudio: _selectedAudio,
          captureSpeedLabel: _speedLabels[_selectedSpeedIndex],
          isRemix: widget.isRemix,
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isEditorOpen = false);
      } else {
        _isEditorOpen = false;
      }
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _maybeNavigateToEditor() {
    if (!mounted ||
        _segments.isEmpty ||
        _isProcessingSegment ||
        _isEditorOpen) {
      return;
    }
    Future.microtask(() {
      if (!mounted ||
          _segments.isEmpty ||
          _isProcessingSegment ||
          _isEditorOpen) {
        return;
      }
      _openEditor();
    });
  }

  ColorScheme get _scheme => Theme.of(context).colorScheme;

  double get _captureProgress {
    final limitSeconds = _lengthOptions[_selectedLengthIndex];
    if (limitSeconds <= 0) return 0;
    final recordedSegments = _segments.fold<double>(
      0,
      (sum, item) => sum + item.duration.inMilliseconds,
    );
    final liveRecording = _isRecording && _recordingStartedAt != null
        ? DateTime.now()
              .difference(_recordingStartedAt!)
              .inMilliseconds
              .toDouble()
        : 0;
    final totalMillis = recordedSegments + liveRecording;
    return (totalMillis / (limitSeconds * 1000)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final countdownActive = _countdownValue != null;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildCameraSurface(),
          if (countdownActive) _CountdownOverlay(seconds: _countdownValue ?? 0),
          _buildTopBar(),
          _buildSideTools(),
          _buildBottomControls(),
          if (_isProcessingSegment)
            const _ProcessingOverlay(message: 'Processing clip...'),
        ],
      ),
    );
  }

  Widget _buildCameraSurface() {
    if (_cameraUnavailable) {
      return const Center(
        child: Text(
          'Camera unavailable',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    final controller = _cameraController;
    if (!_isCameraReady || controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(48),
          bottomRight: Radius.circular(48),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.05),
                      Colors.black.withOpacity(0.35),
                    ],
                  ),
                ),
              ),
            ),
            if (_showGrid) const _GridOverlay(),
            if (_isRecording)
              Positioned(
                top: 24,
                left: 24,
                child: Row(
                  children: const [
                    _RecordingDot(),
                    SizedBox(width: 8),
                    Text(
                      'REC',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final selectedLength = _lengthOptions[_selectedLengthIndex];
    final hasAudio = _selectedAudio != 'Original Sound';
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: _captureProgress,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(_scheme.primary),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _circleButton(
                    icon: Icons.close,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (widget.isRemix)
                          _capsuleChip(icon: Icons.loop, label: 'Remix mode'),
                        _capsuleChip(
                          icon: Icons.fiber_manual_record,
                          label:
                              '${(_captureProgress * 100).clamp(0, 100).toStringAsFixed(0)}% of ${selectedLength}s',
                        ),
                        _capsuleChip(
                          icon: Icons.timelapse,
                          label: '${_lengthOptions[_selectedLengthIndex]}s',
                          onTap: _openLengthPicker,
                        ),
                        _capsuleChip(
                          icon: Icons.music_note,
                          label: hasAudio ? _selectedAudio : 'Add audio',
                          onTap: _openAudioLibrary,
                          emphasize: hasAudio,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_segments.isNotEmpty)
                    FilledButton(
                      onPressed: _openEditor,
                      style: FilledButton.styleFrom(
                        backgroundColor: _scheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  if (_segments.isNotEmpty) const SizedBox(width: 12),
                  if (_flashSupported)
                    _circleButton(
                      icon: _flashOn ? Icons.flash_on : Icons.flash_off,
                      onTap: _toggleFlash,
                    ),
                  if (_flashSupported) const SizedBox(width: 12),
                  _circleButton(
                    icon: Icons.settings,
                    onTap: () => _showSnackBar('Camera settings coming soon.'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideTools() {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).size.height * 0.22,
      child: Column(
        children: [
          _sideButton(Icons.flip_camera_ios, 'Flip', _switchCamera),
          const SizedBox(height: 18),
          _sideButton(Icons.timer, 'Timer', _openTimerPicker),
          const SizedBox(height: 18),
          _sideButton(
            _showGrid ? Icons.grid_off : Icons.grid_on,
            'Grid',
            _toggleGrid,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black, Colors.black.withOpacity(0.25)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_segments.isNotEmpty) ...[
                _SegmentsStrip(
                  segments: _segments,
                  onRemoveLast: () => setState(() => _segments.removeLast()),
                ),
                const SizedBox(height: 18),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_speedLabels.length, (index) {
                  final label = _speedLabels[index];
                  final isSelected = index == _selectedSpeedIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () => _onSelectSpeedIndex(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _actionButton(
                    Icons.auto_awesome,
                    'Effects',
                    _openEffectsSheet,
                  ),
                  _recordButton(),
                  _actionButton(
                    Icons.photo_library_outlined,
                    'Upload',
                    _openUploadOptions,
                  ),
                ],
              ),
              if (_segments.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _openEditor,
                    child: const Text('Next'),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _musicSelector(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recordButton() {
    return GestureDetector(
      onTap: _toggleRecording,
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _isRecording ? Colors.redAccent : Colors.white,
            width: 4,
          ),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            width: _isRecording ? 34 : 68,
            height: _isRecording ? 34 : 68,
            decoration: BoxDecoration(
              color: _isRecording ? Colors.redAccent : null,
              gradient: _isRecording
                  ? null
                  : LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        const Color(0xFFFF6B9D),
                      ],
                    ),
              borderRadius: BorderRadius.circular(_isRecording ? 12 : 46),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _musicSelector() {
    final display = _selectedAudio == 'Original Sound'
        ? 'Add music'
        : _selectedAudio;
    return GestureDetector(
      onTap: _openAudioLibrary,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_note, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                display,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.2),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _capsuleChip({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool emphasize = false,
  }) {
    final background = emphasize
        ? _scheme.primary.withOpacity(0.22)
        : Colors.black.withOpacity(0.45);
    final borderColor = emphasize
        ? _scheme.primary
        : Colors.white.withOpacity(0.2);
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }

  Widget _sideButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.45),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Text(
              '$seconds',
              key: ValueKey<int>(seconds),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 96,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _GridPainter()));
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 1;
    final thirdWidth = size.width / 3;
    final thirdHeight = size.height / 3;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(thirdWidth * i, 0),
        Offset(thirdWidth * i, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, thirdHeight * i),
        Offset(size.width, thirdHeight * i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RecordingDot extends StatefulWidget {
  const _RecordingDot();

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white70),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorActionSheet extends StatelessWidget {
  const _EditorActionSheet({
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: 24 + bottomInset,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween(
      begin: 0.55,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _SegmentsStrip extends StatelessWidget {
  const _SegmentsStrip({required this.segments, required this.onRemoveLast});

  final List<ReelSegment> segments;
  final VoidCallback onRemoveLast;

  Duration get _totalDuration =>
      segments.fold(Duration.zero, (total, item) => total + item.duration);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timeline, color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            Text(
              _totalDuration.inSeconds > 0
                  ? '${_totalDuration.inSeconds}s total'
                  : 'Ready to record',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onRemoveLast,
              child: const Text(
                'Undo',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 16,
          child: Row(
            children: segments.asMap().entries.map((entry) {
              final segment = entry.value;
              final isLast = entry.key == segments.length - 1;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 3),
                  child: _SegmentBlock(
                    duration: segment.duration,
                    source: segment.source,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SegmentBlock extends StatelessWidget {
  const _SegmentBlock({required this.duration, required this.source});

  final Duration duration;
  final ReelSegmentSource source;

  @override
  Widget build(BuildContext context) {
    final color = source == ReelSegmentSource.camera
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF6B9D);
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _TimerPickerSheet extends StatelessWidget {
  const _TimerPickerSheet({
    required this.optionsInSeconds,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<int> optionsInSeconds;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Countdown timer',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < optionsInSeconds.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(i == 0 ? 'Off' : '${optionsInSeconds[i]} seconds'),
              trailing: i == selectedIndex
                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                  : const Icon(Icons.circle_outlined, color: Colors.grey),
              onTap: () => onSelected(i),
            ),
        ],
      ),
    );
  }
}

class _LengthPickerSheet extends StatelessWidget {
  const _LengthPickerSheet({
    required this.optionsInSeconds,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<int> optionsInSeconds;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select reel length',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < optionsInSeconds.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${optionsInSeconds[i]} seconds'),
              trailing: i == selectedIndex
                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                  : const Icon(Icons.circle_outlined, color: Colors.grey),
              onTap: () => onSelected(i),
            ),
        ],
      ),
    );
  }
}

class EffectsBottomSheet extends StatelessWidget {
  const EffectsBottomSheet({super.key});

  static const List<_EffectOption> _effects = [
    _EffectOption('Sparkle', Icons.auto_awesome),
    _EffectOption('Bokeh', Icons.blur_on),
    _EffectOption('VHS', Icons.movie_filter),
    _EffectOption('Glow', Icons.light_mode),
    _EffectOption('Stretch', Icons.waves),
    _EffectOption('Mirror', Icons.flip),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      padding: const EdgeInsets.only(top: 18, left: 20, right: 20, bottom: 26),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Effects',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try filters and AR effects. More presets coming soon.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.78,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: _effects.length,
              itemBuilder: (context, index) {
                final effect = _effects[index];
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${effect.label} will be added soon.'),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          effect.icon,
                          size: 36,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          effect.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

class _EffectOption {
  const _EffectOption(this.label, this.icon);

  final String label;
  final IconData icon;
}

class AudioLibrarySheet extends StatefulWidget {
  const AudioLibrarySheet({
    super.key,
    required this.selectedAudio,
    required this.onAudioSelected,
  });

  final String selectedAudio;
  final ValueChanged<String> onAudioSelected;

  @override
  State<AudioLibrarySheet> createState() => _AudioLibrarySheetState();
}

class _AudioLibrarySheetState extends State<AudioLibrarySheet>
    with SingleTickerProviderStateMixin {
  static const List<String> _tabs = [
    'Trending',
    'For You',
    'Saved',
    'Original',
  ];

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final Map<String, List<_AudioTrack>> _tracksByTab = {
    'Trending': [
      _AudioTrack('City Nights', 'LUX', '00:30'),
      _AudioTrack('Future Bounce', 'DJ Orbit', '00:28'),
      _AudioTrack('Weekend Waves', 'Mono', '00:25'),
    ],
    'For You': [
      _AudioTrack('Golden Hour', 'MIRA', '00:32'),
      _AudioTrack('Neon Hearts', 'Kali', '00:29'),
      _AudioTrack('Afterglow', 'Lyra', '00:26'),
    ],
    'Saved': [
      _AudioTrack('Original Sound', 'You', '00:15'),
      _AudioTrack('Focus Flow', 'BeatLab', '00:45'),
    ],
    'Original': [_AudioTrack('Original Sound', 'Recorded', '00:15')],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sound library',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Discover trending audio or use your own original sound.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search sounds, artists or moods',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TabBar(
                      controller: _tabController,
                      labelColor: theme.colorScheme.onSurface,
                      indicatorColor: theme.colorScheme.primary,
                      isScrollable: true,
                      tabs: _tabs
                          .map((tab) => Tab(text: tab))
                          .toList(growable: false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _tabs
                      .map((tab) {
                        final tracks = _tracksByTab[tab] ?? [];
                        return ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          itemBuilder: (context, index) {
                            final track = tracks[index];
                            final selected =
                                track.title == widget.selectedAudio;
                            return _AudioListTile(
                              track: track,
                              isSelected: selected,
                              onTap: () {
                                widget.onAudioSelected(track.title);
                                Navigator.pop(context, track.title);
                              },
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemCount: tracks.length,
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AudioTrack {
  const _AudioTrack(this.title, this.artist, this.duration);

  final String title;
  final String artist;
  final String duration;
}

class _AudioListTile extends StatelessWidget {
  const _AudioListTile({
    required this.track,
    required this.isSelected,
    required this.onTap,
  });

  final _AudioTrack track;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.12)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF4E00), Color(0xFFFE006A)],
                ),
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${track.artist} · ${track.duration}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Icon(
              isSelected ? Icons.check_circle : Icons.add_circle_outline,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class UploadOptionsSheet extends StatelessWidget {
  const UploadOptionsSheet({
    super.key,
    required this.onGallerySelected,
    required this.onVideoLibrarySelected,
    required this.onTemplateSelected,
  });

  final VoidCallback onGallerySelected;
  final VoidCallback onVideoLibrarySelected;
  final ValueChanged<String> onTemplateSelected;

  static const List<_TemplateOption> _templates = [
    _TemplateOption('Travel Recap', 'Dynamic transitions for city shots'),
    _TemplateOption('Daily Routine', 'Snappy cuts for morning to night'),
    _TemplateOption('Food Diary', 'Macro close-ups with warm tones'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: 24 + bottomInset,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Upload',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bring in clips from your gallery or quick templates.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 18),
            ListTile(
              onTap: onGallerySelected,
              leading: const CircleAvatar(
                child: Icon(Icons.photo_library_rounded),
              ),
              title: const Text('Gallery'),
              subtitle: const Text('Pick multiple clips from your phone'),
              trailing: const Icon(Icons.chevron_right),
            ),
            ListTile(
              onTap: onVideoLibrarySelected,
              leading: const CircleAvatar(
                child: Icon(Icons.video_library_rounded),
              ),
              title: const Text('Video library'),
              subtitle: const Text('Browse previously uploaded reels'),
              trailing: const Icon(Icons.chevron_right),
            ),
            const SizedBox(height: 12),
            Text(
              'Templates',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ..._templates.map(
              (template) => Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  onTap: () => onTemplateSelected(template.title),
                  title: Text(
                    template.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(template.subtitle),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateOption {
  const _TemplateOption(this.title, this.subtitle);

  final String title;
  final String subtitle;
}

class ReelEditingModern extends StatefulWidget {
  const ReelEditingModern({
    super.key,
    required this.segments,
    required this.initialAudio,
    required this.captureSpeedLabel,
    required this.isRemix,
  });

  final List<ReelSegment> segments;
  final String initialAudio;
  final String captureSpeedLabel;
  final bool isRemix;

  @override
  State<ReelEditingModern> createState() => _ReelEditingModernState();
}

class _ReelEditingModernState extends State<ReelEditingModern> {
  VideoPlayerController? _controller;
  VoidCallback? _controllerListener;
  late List<ReelEditedSegment> _clips;
  int _selectedIndex = 0;
  bool _isPlaying = true;

  ReelEditedSegment get _currentClip => _clips[_selectedIndex];

  @override
  void initState() {
    super.initState();
    _clips = widget.segments
        .map((segment) => ReelEditedSegment(base: segment))
        .toList();
    _initialiseController();
  }

  @override
  void dispose() {
    _controllerListener = null;
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initialiseController() async {
    final previous = _controller;
    final clip = _currentClip;
    final controller = VideoPlayerController.file(File(clip.base.path));
    await controller.initialize();
    controller.setLooping(false);
    await controller.setVolume(clip.volume);
    await controller.seekTo(clip.trimStart);
    if (_controllerListener != null) {
      previous?.removeListener(_controllerListener!);
    }
    await previous?.dispose();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    _controllerListener = null;
    setState(() {
      _controller = controller;
      _registerControllerListener(controller);
    });
    if (_isPlaying) {
      controller.play();
    }
  }

  void _registerControllerListener(VideoPlayerController controller) {
    _controllerListener = () {
      if (!mounted || _controller != controller) return;
      final clip = _currentClip;
      final position = controller.value.position;
      if (position < clip.trimStart || position >= clip.trimEnd) {
        controller.seekTo(clip.trimStart);
      }
    };
    controller.addListener(_controllerListener!);
  }

  void _selectSegment(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    unawaited(_initialiseController());
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    if (_isPlaying) {
      controller.pause();
    } else {
      controller.seekTo(_currentClip.trimStart);
      controller.play();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  void _openTrimSheet() {
    final clip = _currentClip;
    final maxMillis = clip.base.duration.inMilliseconds.toDouble();
    if (maxMillis <= 0) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        RangeValues values = RangeValues(
          clip.trimStart.inMilliseconds.toDouble(),
          clip.trimEnd.inMilliseconds.toDouble(),
        );
        return _EditorActionSheet(
          title: 'Trim clip',
          subtitle: 'Adjust the in and out points for this clip.',
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final start = Duration(milliseconds: values.start.round());
              final end = Duration(milliseconds: values.end.round());
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RangeSlider(
                    min: 0,
                    max: maxMillis,
                    divisions: clip.base.duration.inSeconds * 4 + 1,
                    values: values,
                    labels: RangeLabels(
                      _formatDuration(start),
                      _formatDuration(end),
                    ),
                    onChanged: (newValues) {
                      if ((newValues.end - newValues.start) < 300) {
                        return;
                      }
                      setModalState(() => values = newValues);
                    },
                  ),
                  Text(
                    'Selection: ${_formatDuration(start)} - ${_formatDuration(end)} '
                    '(${_formatDuration(end - start)})',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _clips[_selectedIndex] = clip.copyWith(
                          trimStart: Duration(
                            milliseconds: values.start.round(),
                          ),
                          trimEnd: Duration(milliseconds: values.end.round()),
                        );
                      });
                      _initialiseController();
                      Navigator.pop(context);
                    },
                    child: const Text('Apply trim'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _openVolumeSheet() {
    final clip = _currentClip;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        double sliderValue = clip.volume;
        return _EditorActionSheet(
          title: 'Clip volume',
          subtitle: 'Balance how loud this clip should sound.',
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Slider(
                    value: sliderValue,
                    min: 0,
                    max: 1,
                    divisions: 10,
                    label: '${(sliderValue * 100).round()}%',
                    onChanged: (value) =>
                        setModalState(() => sliderValue = value),
                  ),
                  Text(
                    'Current volume: ${(sliderValue * 100).round()}%',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _clips[_selectedIndex] = clip.copyWith(
                          volume: sliderValue.clamp(0.0, 1.0),
                        );
                      });
                      _controller?.setVolume(sliderValue);
                      Navigator.pop(context);
                    },
                    child: const Text('Apply volume'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _removeCurrentClip() {
    if (_clips.isEmpty) return;
    _clips.removeAt(_selectedIndex);
    if (_clips.isEmpty) {
      Navigator.pop(context, <ReelEditedSegment>[]);
      return;
    }
    setState(() {
      _selectedIndex = _selectedIndex.clamp(0, _clips.length - 1);
    });
    _showEditorMessage('Removed clip from timeline');
    _initialiseController();
  }

  void _duplicateClip() {
    final clip = _currentClip;
    setState(() {
      _clips.insert(_selectedIndex + 1, clip.copyWith());
    });
    _showEditorMessage('Clip duplicated');
  }

  void _onReorderClips(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    setState(() {
      final clip = _clips.removeAt(oldIndex);
      _clips.insert(newIndex, clip);
      _selectedIndex = _clips.indexOf(clip);
    });
    _initialiseController();
  }

  void _showEditorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final tenths = (duration.inMilliseconds % 1000 ~/ 100).toString();
    return '$minutes:$seconds.$tenths';
  }

  Widget _editorActionButton(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  void _openPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReelPreviewModern(
          segments: _clips,
          audioLabel: widget.initialAudio,
          isRemix: widget.isRemix,
        ),
      ),
    );
  }

  String _segmentLabel(int index) {
    final segment = _clips[index];
    final seconds = segment.trimmedDuration.inSeconds;
    return 'Clip ${index + 1} • ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Edit reel'),
        actions: [
          IconButton(
            onPressed: _openVolumeSheet,
            icon: const Icon(Icons.graphic_eq),
            tooltip: 'Adjust volume',
          ),
        ],
      ),
      body: controller == null || !controller.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: VideoPlayer(controller),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black.withOpacity(0.35),
                              ),
                              onPressed: _togglePlay,
                              icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                              ),
                              label: Text(_isPlaying ? 'Pause' : 'Play'),
                            ),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                              ),
                              onPressed: _openPreview,
                              icon: const Icon(Icons.send),
                              label: const Text('Preview'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF111111),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.music_note,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.initialAudio,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ReorderableListView.builder(
                          scrollDirection: Axis.horizontal,
                          onReorder: _onReorderClips,
                          buildDefaultDragHandles: false,
                          padding: EdgeInsets.zero,
                          itemCount: _clips.length,
                          itemBuilder: (context, index) {
                            final clip = _clips[index];
                            final selected = index == _selectedIndex;
                            return Padding(
                              key: ValueKey('${clip.path}-$index'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: GestureDetector(
                                onTap: () => _selectSegment(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 152,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: selected
                                        ? theme.colorScheme.primary.withOpacity(
                                            0.22,
                                          )
                                        : Colors.white.withOpacity(0.06),
                                    border: Border.all(
                                      color: selected
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _segmentLabel(index),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          ReorderableDragStartListener(
                                            index: index,
                                            child: Icon(
                                              Icons.drag_handle,
                                              color: Colors.white.withOpacity(
                                                0.6,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Trim: ${_formatDuration(clip.trimStart)} - '
                                        '${_formatDuration(clip.trimEnd)}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Volume: ${(clip.volume * 100).round()}%',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'Cover @ ${_formatDuration(clip.coverFrame)}',
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _editorActionButton(
                            Icons.content_cut,
                            'Trim',
                            _openTrimSheet,
                          ),
                          _editorActionButton(
                            Icons.graphic_eq,
                            'Volume',
                            _openVolumeSheet,
                          ),
                          _editorActionButton(
                            Icons.copy,
                            'Duplicate',
                            _duplicateClip,
                          ),
                          _editorActionButton(
                            Icons.delete,
                            'Delete',
                            _removeCurrentClip,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Next button to proceed to preview
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: _openPreview,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4A6CF7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            minimumSize: const Size.fromHeight(54),
                          ),
                          icon: const Icon(Icons.arrow_forward, size: 20),
                          label: const Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class ReelPreviewModern extends StatefulWidget {
  const ReelPreviewModern({
    super.key,
    required this.segments,
    required this.audioLabel,
    required this.isRemix,
  });

  final List<ReelEditedSegment> segments;
  final String audioLabel;
  final bool isRemix;

  @override
  State<ReelPreviewModern> createState() => _ReelPreviewModernState();
}

class _ReelPreviewModernState extends State<ReelPreviewModern> {
  VideoPlayerController? _controller;
  VoidCallback? _controllerListener;
  int _currentIndex = 0;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    if (widget.segments.isNotEmpty) {
      _loadSegment(0, autoplay: true);
    }
  }

  @override
  void dispose() {
    if (_controllerListener != null) {
      _controller?.removeListener(_controllerListener!);
    }
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadSegment(int index, {required bool autoplay}) async {
    if (index < 0 || index >= widget.segments.length) return;
    final clip = widget.segments[index];
    final previous = _controller;
    final controller = VideoPlayerController.file(File(clip.path));
    await controller.initialize();
    await controller.setLooping(false);
    await controller.setVolume(clip.volume);
    await controller.seekTo(clip.trimStart);
    if (_controllerListener != null) {
      previous?.removeListener(_controllerListener!);
    }
    await previous?.dispose();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    _controllerListener = () {
      if (!mounted || _controller != controller) return;
      final position = controller.value.position;
      if (position >= clip.trimEnd) {
        if (_isPlaying) {
          final nextIndex = _currentIndex + 1;
          if (nextIndex < widget.segments.length) {
            _loadSegment(nextIndex, autoplay: true);
          } else {
            controller.pause();
            controller.seekTo(clip.trimStart);
            setState(() => _isPlaying = false);
          }
        } else {
          controller.seekTo(clip.trimStart);
        }
      }
    };
    controller.addListener(_controllerListener!);
    setState(() {
      _controller = controller;
      _currentIndex = index;
      _isPlaying = autoplay;
    });
    if (autoplay) {
      controller.play();
    }
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null) return;
    if (_isPlaying) {
      controller.pause();
    } else {
      final clip = widget.segments[_currentIndex];
      final position = controller.value.position;
      if (position >= clip.trimEnd || position < clip.trimStart) {
        controller.seekTo(clip.trimStart);
      }
      controller.play();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  void _jumpToClip(int index) {
    if (index < 0 || index >= widget.segments.length) return;
    final shouldAutoplay = _isPlaying;
    if (index == _currentIndex) {
      final clip = widget.segments[index];
      _controller?.seekTo(clip.trimStart);
      if (shouldAutoplay) {
        _controller?.play();
      }
      return;
    }
    _loadSegment(index, autoplay: shouldAutoplay);
  }

  String _formatPreviewDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Preview')),
      body: controller == null || !controller.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      VideoPlayer(controller),
                      Positioned(
                        bottom: 24,
                        left: 24,
                        right: 24,
                        child: Row(
                          children: [
                            const Icon(Icons.music_note, color: Colors.white70),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.audioLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF111111),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          if (widget.isRemix)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'Remix',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const Spacer(),
                          Text(
                            '${widget.segments.length} clips',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 86,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.segments.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final clip = widget.segments[index];
                            final selected = index == _currentIndex;
                            return GestureDetector(
                              onTap: () => _jumpToClip(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 140,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: selected
                                      ? Colors.white.withOpacity(0.18)
                                      : Colors.white.withOpacity(0.08),
                                  border: Border.all(
                                    color: selected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Clip ${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Length ${_formatPreviewDuration(clip.trimmedDuration)}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Volume ${(clip.volume * 100).round()}%',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Reel saved to drafts.'),
                                  ),
                                );
                                Navigator.pop(context);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.12),
                              ),
                              child: const Text('Save draft'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReelCoverCaptionScreen(
                                      segments: widget.segments,
                                      audioLabel: widget.audioLabel,
                                      isRemix: widget.isRemix,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Next'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _togglePlayback,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.35),
                        ),
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        label: Text(_isPlaying ? 'Pause' : 'Play again'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ============================================================================
// 🎨 STAGE 3 — COVER & CAPTION SCREEN
// ============================================================================

class ReelCoverCaptionScreen extends StatefulWidget {
  const ReelCoverCaptionScreen({
    super.key,
    required this.segments,
    required this.audioLabel,
    required this.isRemix,
  });

  final List<ReelEditedSegment> segments;
  final String audioLabel;
  final bool isRemix;

  @override
  State<ReelCoverCaptionScreen> createState() => _ReelCoverCaptionScreenState();
}

class _ReelCoverCaptionScreenState extends State<ReelCoverCaptionScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _captionFocusNode = FocusNode();

  VideoPlayerController? _coverController;
  Duration _selectedCoverFrame = Duration.zero;
  String _visibility = 'Public';
  bool _allowComments = true;
  bool _allowRemix = true;
  bool _showCaptions = true;
  bool _shareToFeed = false;
  bool _shareToStory = false;
  final List<String> _taggedUsers = [];

  @override
  void initState() {
    super.initState();
    if (widget.segments.isNotEmpty) {
      _initializeCoverPreview();
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    _captionFocusNode.dispose();
    _coverController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCoverPreview() async {
    final firstSegment = widget.segments.first;
    _coverController = VideoPlayerController.file(File(firstSegment.path));
    await _coverController!.initialize();
    await _coverController!.seekTo(_selectedCoverFrame);
    if (mounted) setState(() {});
  }

  Future<void> _selectCoverFrame(Duration frame) async {
    setState(() => _selectedCoverFrame = frame);
    await _coverController?.seekTo(frame);
  }

  void _addHashtag() {
    final text = _captionController.text;
    if (!text.endsWith(' ') && text.isNotEmpty) {
      _captionController.text = '$text ';
      _captionController.selection = TextSelection.fromPosition(
        TextPosition(offset: _captionController.text.length),
      );
    }
    _captionController.text = '${_captionController.text}#';
    _captionController.selection = TextSelection.fromPosition(
      TextPosition(offset: _captionController.text.length),
    );
    _captionFocusNode.requestFocus();
  }

  void _showTagPeopleSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Tag people',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: 10,
                itemBuilder: (context, index) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Colors.primaries[index % Colors.primaries.length],
                    child: Text(
                      'U${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  title: Text(
                    'user${index + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'User Name ${index + 1}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  trailing: Checkbox(
                    value: _taggedUsers.contains('user${index + 1}'),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _taggedUsers.add('user${index + 1}');
                        } else {
                          _taggedUsers.remove('user${index + 1}');
                        }
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Add location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search for a location...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: const Icon(
                    Icons.location_on,
                    color: Colors.white54,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: ListView(
                  children:
                      [
                            'New York, NY',
                            'Los Angeles, CA',
                            'San Francisco, CA',
                            'Mumbai, India',
                            'London, UK',
                          ]
                          .map(
                            (location) => ListTile(
                              leading: const Icon(
                                Icons.location_on,
                                color: Colors.white54,
                              ),
                              title: Text(
                                location,
                                style: const TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                setState(
                                  () => _locationController.text = location,
                                );
                                Navigator.pop(context);
                              },
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coverInitialized = _coverController?.value.isInitialized ?? false;
    final totalDuration = widget.segments.fold<Duration>(
      Duration.zero,
      (sum, seg) => sum + seg.trimmedDuration,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Share reel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReelPublishScreen(
                    segments: widget.segments,
                    audioLabel: widget.audioLabel,
                    caption: _captionController.text,
                    location: _locationController.text,
                    visibility: _visibility,
                    allowComments: _allowComments,
                    allowRemix: _allowRemix,
                    showCaptions: _showCaptions,
                    shareToFeed: _shareToFeed,
                    shareToStory: _shareToStory,
                    taggedUsers: _taggedUsers,
                    coverFrame: _selectedCoverFrame,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF4A6CF7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Publish',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover preview with timeline
            Container(
              height: 280,
              width: double.infinity,
              color: const Color(0xFF1C1C1E),
              child: Stack(
                children: [
                  if (coverInitialized)
                    Center(
                      child: AspectRatio(
                        aspectRatio: _coverController!.value.aspectRatio,
                        child: VideoPlayer(_coverController!),
                      ),
                    )
                  else
                    const Center(child: CircularProgressIndicator()),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select cover frame',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 10,
                              itemBuilder: (context, index) {
                                final frameDuration = Duration(
                                  milliseconds:
                                      (totalDuration.inMilliseconds /
                                              10 *
                                              index)
                                          .round(),
                                );
                                final isSelected =
                                    frameDuration == _selectedCoverFrame;
                                return GestureDetector(
                                  onTap: () => _selectCoverFrame(frameDuration),
                                  child: Container(
                                    width: 50,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF4A6CF7)
                                            : Colors.white24,
                                        width: isSelected ? 3 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.image,
                                        color: isSelected
                                            ? const Color(0xFF4A6CF7)
                                            : Colors.white38,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Caption input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.primaries[0],
                        child: const Text(
                          'U',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _captionController,
                          focusNode: _captionFocusNode,
                          maxLines: 5,
                          minLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Write a caption...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tag, color: Color(0xFF4A6CF7)),
                        onPressed: _addHashtag,
                        tooltip: 'Add hashtag',
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 1),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Audio info
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.music_note,
                  color: Color(0xFF4A6CF7),
                  size: 20,
                ),
              ),
              title: Text(
                widget.audioLabel.isEmpty
                    ? 'Original Audio'
                    : widget.audioLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              onTap: () {
                // Could navigate to audio change screen
              },
            ),

            const Divider(
              color: Colors.white12,
              height: 1,
              indent: 16,
              endIndent: 16,
            ),

            // Tag people
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_add,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
              title: const Text(
                'Tag people',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: _taggedUsers.isEmpty
                  ? null
                  : Text(
                      _taggedUsers.join(', '),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              onTap: _showTagPeopleSheet,
            ),

            const Divider(
              color: Colors.white12,
              height: 1,
              indent: 16,
              endIndent: 16,
            ),

            // Add location
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
              title: const Text(
                'Add location',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: _locationController.text.isEmpty
                  ? null
                  : Text(
                      _locationController.text,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              onTap: _showLocationPicker,
            ),

            const SizedBox(height: 24),

            // Privacy & settings section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Visibility',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Public', label: Text('Public')),
                      ButtonSegment(
                        value: 'Followers',
                        label: Text('Followers'),
                      ),
                      ButtonSegment(value: 'Private', label: Text('Private')),
                    ],
                    selected: {_visibility},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() => _visibility = newSelection.first);
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return const Color(0xFFFF006A);
                        }
                        return Colors.white.withOpacity(0.1);
                      }),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Advanced settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _allowComments,
                    onChanged: (val) => setState(() => _allowComments = val),
                    title: const Text(
                      'Allow comments',
                      style: TextStyle(color: Colors.white),
                    ),
                    activeThumbColor: const Color(0xFF4A6CF7),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    value: _allowRemix,
                    onChanged: (val) => setState(() => _allowRemix = val),
                    title: const Text(
                      'Allow remixes',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Let others create content with your reel',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    activeThumbColor: const Color(0xFF4A6CF7),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    value: _showCaptions,
                    onChanged: (val) => setState(() => _showCaptions = val),
                    title: const Text(
                      'Show captions',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Auto-generated captions (when available)',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    activeThumbColor: const Color(0xFF4A6CF7),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Share to other platforms
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Also share to',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _shareToFeed,
                    onChanged: (val) =>
                        setState(() => _shareToFeed = val ?? false),
                    title: const Text(
                      'Feed',
                      style: TextStyle(color: Colors.white),
                    ),
                    activeColor: const Color(0xFF4A6CF7),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    value: _shareToStory,
                    onChanged: (val) =>
                        setState(() => _shareToStory = val ?? false),
                    title: const Text(
                      'Story',
                      style: TextStyle(color: Colors.white),
                    ),
                    activeColor: const Color(0xFF4A6CF7),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 🚀 STAGE 4 — PUBLISH & UPLOAD SCREEN
// ============================================================================

class ReelPublishScreen extends StatefulWidget {
  const ReelPublishScreen({
    super.key,
    required this.segments,
    required this.audioLabel,
    required this.caption,
    required this.location,
    required this.visibility,
    required this.allowComments,
    required this.allowRemix,
    required this.showCaptions,
    required this.shareToFeed,
    required this.shareToStory,
    required this.taggedUsers,
    required this.coverFrame,
  });

  final List<ReelEditedSegment> segments;
  final String audioLabel;
  final String caption;
  final String location;
  final String visibility;
  final bool allowComments;
  final bool allowRemix;
  final bool showCaptions;
  final bool shareToFeed;
  final bool shareToStory;
  final List<String> taggedUsers;
  final Duration coverFrame;

  @override
  State<ReelPublishScreen> createState() => _ReelPublishScreenState();
}

class _ReelPublishScreenState extends State<ReelPublishScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _uploadProgress = 0.0;
  bool _isUploading = true;
  bool _uploadComplete = false;
  String _statusMessage = 'Preparing your reel...';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _startUpload();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startUpload() async {
    // Simulate upload process with realistic stages
    final stages = [
      ('Processing video...', 0.2),
      ('Applying filters...', 0.4),
      ('Adding audio...', 0.6),
      ('Generating thumbnail...', 0.8),
      ('Publishing...', 1.0),
    ];

    for (final stage in stages) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _statusMessage = stage.$1;
          _uploadProgress = stage.$2;
        });
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isUploading = false;
        _uploadComplete = true;
        _statusMessage = 'Your reel is live!';
      });
      _animationController.stop();
    }
  }

  void _minimizeUpload() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Upload continues in background'),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _cancelUpload() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text(
          'Cancel upload?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Your reel will not be published if you cancel now.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue uploading'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel upload'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isUploading,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isUploading) {
          _minimizeUpload();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: _uploadComplete ? _buildSuccessView() : _buildUploadingView(),
        ),
      ),
    );
  }

  Widget _buildUploadingView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF1C1C1E), Colors.black],
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.minimize, color: Colors.white),
                  onPressed: _minimizeUpload,
                  tooltip: 'Minimize',
                ),
                const Text(
                  'Publishing',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _cancelUpload,
                  tooltip: 'Cancel',
                ),
              ],
            ),
          ),

          const Spacer(),

          // Animated upload icon
          RotationTransition(
            turns: _animationController,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4A6CF7).withOpacity(0.3),
              ),
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF4A6CF7),
                  ),
                  child: const Icon(
                    Icons.cloud_upload,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Status message
          Text(
            _statusMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 24),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4A6CF7),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${(_uploadProgress * 100).toInt()}%',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Info cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildInfoCard(
                  icon: Icons.videocam,
                  title: '${widget.segments.length} clips',
                  subtitle: 'High quality',
                ),
                const SizedBox(height: 12),
                if (widget.caption.isNotEmpty)
                  _buildInfoCard(
                    icon: Icons.text_fields,
                    title: 'Caption added',
                    subtitle: widget.caption.length > 30
                        ? '${widget.caption.substring(0, 30)}...'
                        : widget.caption,
                  ),
                if (widget.location.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildInfoCard(
                      icon: Icons.location_on,
                      title: widget.location,
                      subtitle: 'Location',
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF1C1C1E), Colors.black],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4A6CF7).withOpacity(0.3),
            ),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4A6CF7),
                ),
                child: const Icon(Icons.check, size: 60, color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            '✨ Your reel is live!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Text(
            'Your reel has been published successfully',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () {
                      // Navigate to reel view
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4A6CF7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: const Text(
                      'View Reel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Share functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Share functionality coming soon'),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.share),
                    label: const Text(
                      'Share',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stats preview
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.visibility, '0', 'Views'),
                Container(width: 1, height: 40, color: Colors.white12),
                _buildStatItem(Icons.favorite, '0', 'Likes'),
                Container(width: 1, height: 40, color: Colors.white12),
                _buildStatItem(Icons.share, '0', 'Shares'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4A6CF7).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF4A6CF7), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF4A6CF7), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
        ),
      ],
    );
  }
}
