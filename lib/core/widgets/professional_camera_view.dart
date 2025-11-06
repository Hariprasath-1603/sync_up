import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/video_service.dart';

/// Aspect ratio modes matching Instagram
enum CameraAspectMode {
  square(1.0, '1:1', 'Post'), // Square posts
  portrait(0.8, '4:5', 'Feed'), // Feed photos
  fullScreen(0.5625, '9:16', 'Reel'); // Reels/Stories

  const CameraAspectMode(this.ratio, this.label, this.description);
  final double ratio;
  final String label;
  final String description;
}

/// Flash mode options
enum CameraFlashMode {
  off,
  on,
  auto;

  IconData get icon {
    switch (this) {
      case CameraFlashMode.off:
        return Icons.flash_off;
      case CameraFlashMode.on:
        return Icons.flash_on;
      case CameraFlashMode.auto:
        return Icons.flash_auto;
    }
  }

  FlashMode get cameraFlashMode {
    switch (this) {
      case CameraFlashMode.off:
        return FlashMode.off;
      case CameraFlashMode.on:
        return FlashMode.torch;
      case CameraFlashMode.auto:
        return FlashMode.auto;
    }
  }
}

/// Professional camera view with Instagram-like controls
class ProfessionalCameraView extends StatefulWidget {
  const ProfessionalCameraView({
    super.key,
    this.initialMode = CameraAspectMode.fullScreen,
    this.showModeSelector = true,
    this.onMediaCaptured,
    this.maxVideoDuration = const Duration(seconds: 60),
    this.enableRotation = true,
  });

  final CameraAspectMode initialMode;
  final bool showModeSelector;
  final Function(String path, String? thumbnailPath, bool isVideo)?
  onMediaCaptured;
  final Duration maxVideoDuration;
  final bool enableRotation;

  @override
  State<ProfessionalCameraView> createState() => _ProfessionalCameraViewState();
}

class _ProfessionalCameraViewState extends State<ProfessionalCameraView>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  CameraFlashMode _flashMode = CameraFlashMode.off;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  Offset? _focusPoint;
  CameraAspectMode _currentMode = CameraAspectMode.fullScreen;
  bool _isProcessing = false;

  // Recording
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  // Animations
  late AnimationController _focusAnimationController;
  late AnimationController _modeChangeController;
  late AnimationController _flashAnimationController;
  late AnimationController _switchCameraController;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
    WidgetsBinding.instance.addObserver(this);

    _focusAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _modeChangeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _flashAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _switchCameraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _recordingTimer?.cancel();
    _focusAnimationController.dispose();
    _modeChangeController.dispose();
    _flashAnimationController.dispose();
    _switchCameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showError('No cameras available');
        return;
      }

      await _setupCamera(_cameras![_selectedCameraIndex]);
    } catch (e) {
      _showError('Camera initialization failed: $e');
    }
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = controller;

    try {
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);

      // Get zoom capabilities
      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = await controller.getMaxZoomLevel();
      _currentZoom = _minZoom;

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      _showError('Failed to initialize camera: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    setState(() {
      _isCameraInitialized = false;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    });

    await _controller?.dispose();
    await _setupCamera(_cameras![_selectedCameraIndex]);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;

    try {
      // Cycle through flash modes
      final nextMode = CameraFlashMode
          .values[(_flashMode.index + 1) % CameraFlashMode.values.length];

      setState(() {
        _flashMode = nextMode;
      });

      await _controller!.setFlashMode(_flashMode.cameraFlashMode);
      _flashAnimationController.forward(from: 0);
    } catch (e) {
      _showError('Failed to toggle flash: $e');
    }
  }

  Future<void> _setZoom(double zoom) async {
    if (_controller == null) return;

    try {
      final clampedZoom = zoom.clamp(_minZoom, _maxZoom);
      await _controller!.setZoomLevel(clampedZoom);
      setState(() {
        _currentZoom = clampedZoom;
      });
    } catch (e) {
      debugPrint('Failed to set zoom: $e');
    }
  }

  Future<void> _setFocusPoint(Offset point) async {
    if (_controller == null) return;

    try {
      // Normalize coordinates
      final x = point.dx.clamp(0.0, 1.0);
      final y = point.dy.clamp(0.0, 1.0);

      await _controller!.setFocusPoint(Offset(x, y));
      await _controller!.setExposurePoint(Offset(x, y));

      setState(() {
        _focusPoint = point;
      });

      _focusAnimationController.forward(from: 0).then((_) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _focusPoint = null;
            });
          }
        });
      });
    } catch (e) {
      debugPrint('Failed to set focus: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _controller!.takePicture();
      if (widget.onMediaCaptured != null) {
        widget.onMediaCaptured!(image.path, null, false);
      }
    } catch (e) {
      _showError('Failed to take picture: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _startVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isRecording) return;

    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingSeconds++;
          });

          if (_recordingSeconds >= widget.maxVideoDuration.inSeconds) {
            _stopVideoRecording();
          }
        }
      });
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_controller == null || !_isRecording) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      _recordingTimer?.cancel();
      final video = await _controller!.stopVideoRecording();

      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });

      // Generate thumbnail for video
      String? thumbnailPath;
      try {
        thumbnailPath = await VideoService.generateThumbnail(
          video.path,
          timeMs: 0,
          quality: 75,
        );
      } catch (e) {
        debugPrint('Failed to generate thumbnail: $e');
      }

      if (widget.onMediaCaptured != null) {
        widget.onMediaCaptured!(video.path, thumbnailPath, true);
      }
    } catch (e) {
      _showError('Failed to stop recording: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _changeCameraMode(CameraAspectMode mode) {
    _modeChangeController.forward(from: 0);
    setState(() {
      _currentMode = mode;
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildCameraPreview() {
    if (_controller == null || !_isCameraInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final previewRatio = _controller!.value.aspectRatio;

    // Calculate scale to fill screen
    double scale = deviceRatio / previewRatio;
    if (scale < 1) scale = 1 / scale;

    return Transform.scale(
      scale: scale,
      child: Center(
        child: AspectRatio(
          aspectRatio: previewRatio,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }

  Widget _buildAspectRatioOverlay() {
    final size = MediaQuery.of(context).size;
    final targetAspectRatio = _currentMode.ratio;

    // Calculate overlay dimensions
    double overlayWidth = size.width;
    double overlayHeight = size.width / targetAspectRatio;

    if (overlayHeight > size.height) {
      overlayHeight = size.height;
      overlayWidth = size.height * targetAspectRatio;
    }

    final horizontalPadding = (size.width - overlayWidth) / 2;
    final verticalPadding = (size.height - overlayHeight) / 2;

    return Stack(
      children: [
        // Top dark overlay
        if (verticalPadding > 0)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: verticalPadding,
            child: Container(color: Colors.black54),
          ),
        // Bottom dark overlay
        if (verticalPadding > 0)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: verticalPadding,
            child: Container(color: Colors.black54),
          ),
        // Left dark overlay
        if (horizontalPadding > 0)
          Positioned(
            top: verticalPadding,
            left: 0,
            width: horizontalPadding,
            height: overlayHeight,
            child: Container(color: Colors.black54),
          ),
        // Right dark overlay
        if (horizontalPadding > 0)
          Positioned(
            top: verticalPadding,
            right: 0,
            width: horizontalPadding,
            height: overlayHeight,
            child: Container(color: Colors.black54),
          ),
        // Frame border
        Positioned(
          top: verticalPadding,
          left: horizontalPadding,
          child: Container(
            width: overlayWidth,
            height: overlayHeight,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFocusRing() {
    if (_focusPoint == null) return const SizedBox.shrink();

    return Positioned(
      left: _focusPoint!.dx - 40,
      top: _focusPoint!.dy - 40,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.5, end: 1.0).animate(
          CurvedAnimation(
            parent: _focusAnimationController,
            curve: Curves.easeOut,
          ),
        ),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Close button
            _buildControlButton(
              icon: Icons.close,
              onTap: () => Navigator.pop(context),
            ),
            // Mode indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _currentMode.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Flash button
            ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.2).animate(
                CurvedAnimation(
                  parent: _flashAnimationController,
                  curve: Curves.easeInOut,
                ),
              ),
              child: _buildControlButton(
                icon: _flashMode.icon,
                onTap: _toggleFlash,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom slider
          if (_maxZoom > _minZoom && _currentZoom > _minZoom)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.zoom_out, color: Colors.white, size: 20),
                  Expanded(
                    child: Slider(
                      value: _currentZoom,
                      min: _minZoom,
                      max: _maxZoom,
                      activeColor: Colors.white,
                      inactiveColor: Colors.white38,
                      onChanged: _setZoom,
                    ),
                  ),
                  const Icon(Icons.zoom_in, color: Colors.white, size: 20),
                ],
              ),
            ),
          const SizedBox(height: 20),
          // Mode selector
          if (widget.showModeSelector)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: CameraAspectMode.values.map((mode) {
                final isSelected = mode == _currentMode;
                return GestureDetector(
                  onTap: () => _changeCameraMode(mode),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      mode.label,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 32),
          // Capture controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery button
              _buildControlButton(
                icon: Icons.photo_library,
                onTap: () {
                  // Handle gallery selection
                },
              ),
              // Capture/Record button
              GestureDetector(
                onTap: _isRecording ? null : _takePicture,
                onLongPress: _startVideoRecording,
                onLongPressUp: _stopVideoRecording,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: _isRecording ? Colors.red : Colors.transparent,
                  ),
                  child: _isRecording
                      ? Center(
                          child: Text(
                            _formatDuration(_recordingSeconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              // Switch camera button
              _buildControlButton(
                icon: Icons.flip_camera_ios,
                onTap: _switchCamera,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black54,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview (full screen)
          Positioned.fill(
            child: GestureDetector(
              onTapDown: (details) {
                final renderBox = context.findRenderObject() as RenderBox;
                final localPosition = renderBox.globalToLocal(
                  details.globalPosition,
                );
                _setFocusPoint(Offset(localPosition.dx, localPosition.dy));
              },
              onScaleUpdate: (details) {
                final newZoom = _currentZoom * details.scale;
                _setZoom(newZoom);
              },
              child: _buildCameraPreview(),
            ),
          ),
          // Aspect ratio overlay
          _buildAspectRatioOverlay(),
          // Focus ring
          _buildFocusRing(),
          // Top controls
          Positioned(top: 0, left: 0, right: 0, child: _buildTopControls()),
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),
          // Recording indicator
          if (_isRecording)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'REC ${_formatDuration(_recordingSeconds)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Processing indicator
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Processing...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
    );
  }
}
