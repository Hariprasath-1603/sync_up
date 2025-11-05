import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

/// Service for managing camera operations
class CameraService extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isRearCamera = true;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;
  bool get isRearCamera => _isRearCamera;
  double get currentZoom => _currentZoom;
  double get minZoom => _minZoom;
  double get maxZoom => _maxZoom;

  /// Initialize camera with permissions
  Future<bool> initialize({
    ResolutionPreset resolution = ResolutionPreset.high,
    bool enableAudio = true,
  }) async {
    try {
      // Request permissions
      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();

      if (!cameraStatus.isGranted || !micStatus.isGranted) {
        debugPrint('Camera or microphone permission denied');
        return false;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        debugPrint('No cameras found');
        return false;
      }

      // Select camera
      final camera = _cameras.firstWhere(
        (c) =>
            c.lensDirection ==
            (_isRearCamera
                ? CameraLensDirection.back
                : CameraLensDirection.front),
        orElse: () => _cameras.first,
      );

      // Create controller
      _controller = CameraController(
        camera,
        resolution,
        enableAudio: enableAudio,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      // Get zoom levels
      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();
      _currentZoom = _minZoom;

      _isInitialized = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      _isInitialized = false;
      notifyListeners();
      return false;
    }
  }

  /// Switch between front and rear camera
  Future<void> switchCamera() async {
    if (_controller == null) return;

    _isRearCamera = !_isRearCamera;
    _isInitialized = false;
    notifyListeners();

    await _controller?.dispose();
    await initialize();
  }

  /// Set zoom level
  Future<void> setZoom(double zoom) async {
    if (_controller == null || !_isInitialized) return;

    final clampedZoom = zoom.clamp(_minZoom, _maxZoom);
    await _controller!.setZoomLevel(clampedZoom);
    _currentZoom = clampedZoom;
    notifyListeners();
  }

  /// Animate zoom change
  Future<void> animateZoom(double targetZoom, {Duration? duration}) async {
    if (_controller == null || !_isInitialized) return;

    final clampedTarget = targetZoom.clamp(_minZoom, _maxZoom);
    final startZoom = _currentZoom;
    final steps = 20;
    final stepDuration =
        (duration ?? const Duration(milliseconds: 300)).inMilliseconds ~/ steps;

    for (int i = 0; i <= steps; i++) {
      final progress = i / steps;
      final zoom = startZoom + (clampedTarget - startZoom) * progress;
      await setZoom(zoom);
      await Future.delayed(Duration(milliseconds: stepDuration));
    }
  }

  /// Toggle flash mode
  Future<void> toggleFlash() async {
    if (_controller == null || !_isInitialized) return;

    final currentMode = _controller!.value.flashMode;
    final newMode = currentMode == FlashMode.off
        ? FlashMode.torch
        : FlashMode.off;
    await _controller!.setFlashMode(newMode);
    notifyListeners();
  }

  /// Start video recording
  Future<void> startRecording() async {
    if (_controller == null || !_isInitialized || _isRecording) return;

    try {
      await _controller!.startVideoRecording();
      _isRecording = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Start recording error: $e');
      rethrow;
    }
  }

  /// Stop video recording and return file path
  Future<String?> stopRecording() async {
    if (_controller == null || !_isRecording) return null;

    try {
      final xFile = await _controller!.stopVideoRecording();
      _isRecording = false;
      notifyListeners();

      // Save to temporary directory
      final directory = await getTemporaryDirectory();
      final fileName = 'reel_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final savePath = '${directory.path}/$fileName';

      // Move file
      await xFile.saveTo(savePath);
      return savePath;
    } catch (e) {
      debugPrint('Stop recording error: $e');
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  /// Dispose camera resources
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
