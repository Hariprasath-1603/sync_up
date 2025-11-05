import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_compress/video_compress.dart';
import 'dart:math' as math;
import 'camera_composer_page.dart';
import '../../core/services/video_service.dart';

/// Dedicated Reel Creator Page - Instagram/TikTok style
/// Single purpose: Create and record Reels only
class ReelCreatePage extends StatefulWidget {
  const ReelCreatePage({super.key});

  @override
  State<ReelCreatePage> createState() => _ReelCreatePageState();
}

class _ReelCreatePageState extends State<ReelCreatePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Camera
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isRearCamera = true;

  // Recording state
  bool _isRecording = false;
  double _recordingProgress = 0.0;
  Timer? _recordingTimer;
  int _recordingDuration = 0; // in milliseconds
  int _maxDuration = 30000; // 30 seconds default

  // Settings
  bool _isFlashOn = false;
  String _speed = '1x';
  String _selectedDuration = '30s';
  int? _timerCountdown; // 3s or 10s
  bool _isCountingDown = false;

  // UI & Animations
  DateTime? _lastBackPress;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  int _reelTitleTapCount = 0;
  DateTime? _lastReelTitleTap;
  bool _showEasterEgg = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _initializeCamera();
  }

  void _initializeAnimations() {
    // Pulse animation for record button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Glow animation for REEL title
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _pulseController.dispose();
    _glowController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameraStatus = await Permission.camera.request();
      final microphoneStatus = await Permission.microphone.request();

      if (!cameraStatus.isGranted || !microphoneStatus.isGranted) {
        _showPermissionDeniedDialog();
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _showErrorSnackBar('No cameras found');
        return;
      }

      final camera = _cameras.firstWhere(
        (camera) =>
            camera.lensDirection ==
            (_isRearCamera
                ? CameraLensDirection.back
                : CameraLensDirection.front),
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset
            .medium, // Changed from high to medium (saves ~40% bandwidth)
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to initialize camera: $e');
    }
  }

  Future<void> toggleCamera() async {
    setState(() {
      _isRearCamera = !_isRearCamera;
      _isCameraInitialized = false;
    });
    await _cameraController?.dispose();
    await _initializeCamera();
    HapticFeedback.mediumImpact();
  }

  Future<void> toggleFlash() async {
    if (_cameraController == null) return;
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    await _cameraController!.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
    HapticFeedback.lightImpact();
  }

  void toggleSpeed() {
    setState(() {
      if (_speed == '0.5x') {
        _speed = '1x';
      } else if (_speed == '1x')
        _speed = '2x';
      else
        _speed = '0.5x';
    });
    HapticFeedback.lightImpact();
  }

  void onTimerTap() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1D24)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Timer Countdown',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...[('Off', null), ('3s', 3), ('10s', 10)].map((option) {
              return ListTile(
                leading: Radio<int?>(
                  value: option.$2,
                  groupValue: _timerCountdown,
                  onChanged: (value) {
                    setState(() {
                      _timerCountdown = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: const Color(0xFF5B3FFF),
                ),
                title: Text(
                  option.$1,
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                onTap: () {
                  setState(() {
                    _timerCountdown = option.$2;
                  });
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void onSettingsTap() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1D24)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Camera Settings',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildSettingTile('Resolution', '1080p', Icons.hd),
            _buildSettingTile('Grid', 'Off', Icons.grid_3x3),
            _buildSettingTile('Stabilization', 'On', Icons.videocam_rounded),
            _buildSettingTile('Auto Lighting', 'On', Icons.wb_sunny),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF5B3FFF)),
      title: Text(title, style: GoogleFonts.poppins()),
      trailing: Text(value, style: GoogleFonts.poppins(color: Colors.grey)),
      onTap: () {
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$title settings coming soon!',
              style: GoogleFonts.poppins(),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void onAudioTap() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1D24)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add Audio',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search sounds',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5B3FFF), Color(0xFF00E0FF)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        'Trending Sound ${index + 1}',
                        style: GoogleFonts.poppins(),
                      ),
                      subtitle: Text(
                        'Artist Name',
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Sound ${index + 1} selected',
                              style: GoogleFonts.poppins(),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onEffectsTap() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1D24)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Effects',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildEffectItem('None', Icons.block),
                  _buildEffectItem('Beauty', Icons.face),
                  _buildEffectItem('Vintage', Icons.camera),
                  _buildEffectItem('Neon', Icons.lightbulb),
                  _buildEffectItem('Blur', Icons.blur_on),
                  _buildEffectItem('B&W', Icons.filter_b_and_w),
                  _buildEffectItem('Warm', Icons.wb_sunny),
                  _buildEffectItem('Cool', Icons.ac_unit),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectItem(String name, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(name, style: GoogleFonts.poppins(fontSize: 12)),
      ],
    );
  }

  void onDurationTap() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1D24)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Reel Duration',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...[('15s', 15000), ('30s', 30000), ('60s', 60000)].map((option) {
              return ListTile(
                leading: Radio<String>(
                  value: option.$1,
                  groupValue: _selectedDuration,
                  onChanged: (value) {
                    setState(() {
                      _selectedDuration = value!;
                      _maxDuration = option.$2;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: const Color(0xFF5B3FFF),
                ),
                title: Text(
                  option.$1,
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                onTap: () {
                  setState(() {
                    _selectedDuration = option.$1;
                    _maxDuration = option.$2;
                  });
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void onGreenScreenTap() {
    HapticFeedback.mediumImpact();
    _showComingSoonSnackBar('Green Screen');
  }

  void onTouchUpTap() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1D24)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Touch Up',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            _buildSlider('Smoothness', 0.5),
            const SizedBox(height: 20),
            _buildSlider('Brightness', 0.3),
            const SizedBox(height: 20),
            _buildSlider('Whitening', 0.0),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14)),
        Slider(
          value: value,
          onChanged: (val) {
            HapticFeedback.selectionClick();
            // TODO: Apply filter
          },
          activeColor: const Color(0xFF5B3FFF),
        ),
      ],
    );
  }

  Future<void> onRecordButtonPressed() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      if (_timerCountdown != null) {
        await _startCountdown();
      } else {
        await _startRecording();
      }
    }
  }

  Future<void> _startCountdown() async {
    setState(() {
      _isCountingDown = true;
    });

    for (int i = _timerCountdown!; i > 0; i--) {
      if (!mounted) return;
      setState(() {});
      await Future.delayed(const Duration(seconds: 1));
      HapticFeedback.mediumImpact();
    }

    setState(() {
      _isCountingDown = false;
    });
    await _startRecording();
  }

  Future<void> _startRecording() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isRecording) {
      return;
    }

    try {
      await _cameraController!.startVideoRecording();
      HapticFeedback.heavyImpact();

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
        _recordingProgress = 0.0;
      });

      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _recordingDuration += 100;
          _recordingProgress = _recordingDuration / _maxDuration;
        });
        if (_recordingDuration >= _maxDuration) {
          _stopRecording();
        }
      });
    } catch (e) {
      _showErrorSnackBar('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _cameraController == null) return;

    try {
      final video = await _cameraController!.stopVideoRecording();
      _recordingTimer?.cancel();
      HapticFeedback.lightImpact();

      setState(() {
        _isRecording = false;
        _recordingProgress = 0.0;
        _recordingDuration = 0;
      });

      if (mounted) {
        // Show compression progress
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF5B3FFF),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Compressing video...',
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This reduces file size by 70%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Compress video to save bandwidth
        final compressedPath = await VideoService.compressVideo(
          video.path,
          quality: VideoQuality.MediumQuality,
        );

        if (mounted) {
          Navigator.of(context).pop(); // Close compression dialog
        }

        final videoPath = compressedPath ?? video.path;

        // Show file size saved
        if (compressedPath != null && mounted) {
          final originalSize = File(video.path).lengthSync() / 1024 / 1024;
          final compressedSize =
              File(compressedPath).lengthSync() / 1024 / 1024;
          final savedMB = originalSize - compressedSize;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Saved ${savedMB.toStringAsFixed(1)} MB!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        if (mounted) {
          // Navigate to Camera Composer for editing with the compressed video
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CameraComposerPage(type: 'reel', videoPath: videoPath),
            ),
          );

          // If result is returned, pop with the video path
          if (result != null && mounted) {
            Navigator.pop(context, result);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close any dialogs
      }
      _showErrorSnackBar('Failed to stop recording: $e');
    }
  }

  void _openGallery() {
    HapticFeedback.lightImpact();
    _showComingSoonSnackBar('Gallery');
  }

  void _handleReelTitleTap() {
    final now = DateTime.now();
    if (_lastReelTitleTap != null &&
        now.difference(_lastReelTitleTap!) < const Duration(seconds: 2)) {
      _reelTitleTapCount++;
      if (_reelTitleTapCount >= 5) {
        _showEasterEgg = true;
        _reelTitleTapCount = 0;
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('📹', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(
                  'SyncUp Vibes! 🎉',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF5B3FFF),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showEasterEgg = false;
            });
          }
        });
      }
    } else {
      _reelTitleTapCount = 1;
    }
    _lastReelTitleTap = now;
  }

  void _handleBackPress() {
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Press back again to exit',
            style: GoogleFonts.poppins(),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Permissions Required',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Camera and microphone permissions are required to record Reels.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(
              'Settings',
              style: GoogleFonts.poppins(
                color: const Color(0xFF5B3FFF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showComingSoonSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!', style: GoogleFonts.poppins()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Camera Preview (Full Screen)
            if (_isCameraInitialized && _cameraController != null)
              Center(child: CameraPreview(_cameraController!))
            else
              _buildLoadingOverlay(),

            // Gradient overlay for contrast
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: const [0.0, 0.25, 0.75, 1.0],
                ),
              ),
            ),

            // Top Bar - "REEL" Title with Neon Glow
            _buildTopBar(),

            // Side Bar - Left Controls
            _buildSideBar(),

            // Action Buttons - Right Top Corner
            _buildActionButtons(),

            // Bottom Controls
            _buildBottomControls(),

            // Recording Indicator
            if (_isRecording) _buildRecordingIndicator(),

            // Countdown Overlay
            if (_isCountingDown) _buildCountdownOverlay(),

            // Easter Egg Animation
            if (_showEasterEgg) _buildEasterEgg(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B3FFF)),
            ),
            const SizedBox(height: 20),
            Text(
              'Initializing Camera...',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 0,
      right: 0,
      child:
          GestureDetector(
                onTap: _handleReelTitleTap,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF5B3FFF,
                              ).withOpacity(_glowAnimation.value * 0.6),
                              blurRadius: 20 + (_glowAnimation.value * 20),
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: const Color(
                                0xFF00E0FF,
                              ).withOpacity(_glowAnimation.value * 0.4),
                              blurRadius: 30 + (_glowAnimation.value * 30),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Color.lerp(
                                const Color(0xFF5B3FFF),
                                const Color(0xFF8B6FFF),
                                _glowAnimation.value,
                              )!,
                              Color.lerp(
                                const Color(0xFF00E0FF),
                                const Color(0xFF00FFD4),
                                _glowAnimation.value,
                              )!,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            'REEL',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .shimmer(
                duration: 2.seconds,
                color: Colors.white.withOpacity(0.3),
              ),
    );
  }

  Widget _buildSideBar() {
    return Positioned(
      left: 16,
      top: MediaQuery.of(context).padding.top + 100,
      child: Column(
        children: [
          _buildSideButton(Icons.music_note, 'Audio', onAudioTap, delay: 0),
          const SizedBox(height: 24),
          _buildSideButton(
            Icons.auto_awesome,
            'Effects',
            onEffectsTap,
            delay: 1,
          ),
          const SizedBox(height: 24),
          _buildSideButton(
            Icons.timer,
            _selectedDuration,
            onDurationTap,
            delay: 2,
          ),
          const SizedBox(height: 24),
          _buildSideButton(
            Icons.grid_4x4,
            'Green\nScreen',
            onGreenScreenTap,
            delay: 3,
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              _buildSideButton(
                Icons.auto_fix_high,
                'Touch\nUp',
                onTouchUpTap,
                delay: 4,
              ),
              Positioned(
                top: 0,
                right: 0,
                child:
                    Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5B3FFF), Color(0xFF00E0FF)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5B3FFF).withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            'NEW',
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(duration: 1.5.seconds)
                        .shake(hz: 0.5, duration: 2.seconds),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSideButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    int delay = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child:
          SizedBox(
                width: 56,
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          const Shadow(color: Colors.black, blurRadius: 8),
                          const Shadow(color: Colors.black, blurRadius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .slideX(
                begin: -1.0,
                end: 0.0,
                duration: 600.ms,
                delay: (delay * 100).ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 400.ms, delay: (delay * 100).ms),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      right: 16,
      child: Column(
        children: [
          _buildCircularButton(
            icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
            onTap: toggleFlash,
            isActive: _isFlashOn,
            delay: 0,
          ),
          const SizedBox(height: 12),
          _buildCircularButton(
            icon: Icons.speed,
            label: _speed,
            onTap: toggleSpeed,
            delay: 1,
          ),
          const SizedBox(height: 12),
          _buildCircularButton(
            icon: Icons.timer,
            onTap: onTimerTap,
            isActive: _timerCountdown != null,
            delay: 2,
          ),
          const SizedBox(height: 12),
          _buildCircularButton(
            icon: Icons.settings,
            onTap: onSettingsTap,
            delay: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
    bool isActive = false,
    int delay = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child:
          Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? const LinearGradient(
                          colors: [Color(0xFF5B3FFF), Color(0xFF00E0FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isActive ? null : Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF00E0FF)
                        : Colors.white.withOpacity(0.4),
                    width: 2,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF5B3FFF).withOpacity(0.6),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: const Color(0xFF00E0FF).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                ),
                child: Center(
                  child: label != null
                      ? Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : Icon(icon, color: Colors.white, size: 22),
                ),
              )
              .animate()
              .slideX(
                begin: 1.0,
                end: 0.0,
                duration: 600.ms,
                delay: (delay * 100).ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 400.ms, delay: (delay * 100).ms),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery Button
          GestureDetector(
                onTap: _openGallery,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              )
              .animate()
              .slideY(
                begin: 2.0,
                end: 0.0,
                duration: 600.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 400.ms),

          // Record Button with Pulsing Border
          GestureDetector(
                onTap: onRecordButtonPressed,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isRecording ? 1.0 : _pulseAnimation.value,
                      child: Container(
                        width: 85,
                        height: 85,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF5B3FFF),
                              Color(0xFF7B5FFF),
                              Color(0xFF00D4FF),
                              Color(0xFF00E0FF),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5B3FFF).withOpacity(0.7),
                              blurRadius: _isRecording ? 25 : 35,
                              spreadRadius: _isRecording ? 3 : 6,
                            ),
                            BoxShadow(
                              color: const Color(0xFF00E0FF).withOpacity(0.5),
                              blurRadius: _isRecording ? 20 : 30,
                              spreadRadius: _isRecording ? 2 : 4,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Progress Ring
                            if (_isRecording)
                              CustomPaint(
                                size: const Size(85, 85),
                                painter: _ProgressRingPainter(
                                  _recordingProgress,
                                ),
                              ),
                            // Inner Circle
                            Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 65,
                                height: 65,
                                decoration: BoxDecoration(
                                  color: _isRecording
                                      ? Colors.red
                                      : Colors.white,
                                  shape: _isRecording
                                      ? BoxShape.rectangle
                                      : BoxShape.circle,
                                  borderRadius: _isRecording
                                      ? BorderRadius.circular(10)
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _isRecording
                                          ? Colors.red.withOpacity(0.5)
                                          : Colors.white.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                duration: 700.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 400.ms),

          // Switch Camera Button
          GestureDetector(
                onTap: toggleCamera,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.cameraswitch,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              )
              .animate()
              .slideY(
                begin: 2.0,
                end: 0.0,
                duration: 600.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(_recordingDuration / 1000).toStringAsFixed(1)}s',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    final currentCount =
        (_timerCountdown! - (_recordingDuration / 1000).floor()).clamp(
          1,
          _timerCountdown!,
        );

    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                  '$currentCount',
                  style: GoogleFonts.poppins(
                    fontSize: 140,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 800.ms, color: const Color(0xFF00E0FF))
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.2, 1.2),
                  duration: 800.ms,
                  curve: Curves.easeOut,
                )
                .then()
                .scale(
                  begin: const Offset(1.2, 1.2),
                  end: const Offset(0.8, 0.8),
                  duration: 200.ms,
                ),
            const SizedBox(height: 20),
            Text(
                  'Get Ready!',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .fadeIn(duration: 500.ms)
                .fadeOut(duration: 500.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildEasterEgg() {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📹', style: const TextStyle(fontSize: 100))
                .animate()
                .scale(
                  begin: const Offset(0.0, 0.0),
                  end: const Offset(1.5, 1.5),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                )
                .then()
                .shake(hz: 5, duration: 500.ms)
                .then()
                .rotate(begin: 0, end: 2 * math.pi, duration: 1000.ms),
            const SizedBox(height: 20),
            Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B3FFF), Color(0xFF00E0FF)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B3FFF).withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Text(
                    '✨ SyncUp Vibes! ✨',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                )
                .animate()
                .slideY(
                  begin: 2.0,
                  end: 0.0,
                  duration: 600.ms,
                  delay: 300.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 400.ms, delay: 300.ms)
                .shimmer(
                  duration: 1.5.seconds,
                  delay: 800.ms,
                  color: Colors.white,
                ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Progress Ring
class _ProgressRingPainter extends CustomPainter {
  final double progress;

  _ProgressRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
