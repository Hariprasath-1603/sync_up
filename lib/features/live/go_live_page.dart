import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const _primaryGradient = LinearGradient(
  colors: [Color(0xFFFF0050), Color(0xFF8E2DE2)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const _glassColor = Color(0x33000000);
const _commentDisplayDuration = Duration(seconds: 6);

class GoLivePage extends StatefulWidget {
  const GoLivePage({
    super.key,
    this.cameraEnabled = true,
    this.screenShareEnabled = false,
  });

  final bool cameraEnabled;
  final bool screenShareEnabled;

  @override
  State<GoLivePage> createState() => _GoLivePageState();
}

class _GoLivePageState extends State<GoLivePage> {
  final _commentController = LiveCommentFeedController();
  final _reactionController = FloatingReactionController();
  final _textController = TextEditingController();

  final List<String> _mockUsernames = [
    'Lena',
    'Priya',
    'Tom',
    'Haruki',
    'Amelia',
    'Diego',
    'Hana',
    'Maya',
    'Ezra',
  ];

  final List<LiveComment> _commentHistory = [];
  Timer? _mockCommentTimer;
  Timer? _mockJoinTimer;
  Timer? _mockReactionTimer;
  Timer? _giftTimer;
  String? _latestJoin;

  bool _coHostJoined = false;
  bool _micOn = true;
  bool _cameraOn = true;
  bool _screenSharing = false;
  bool _commentsEnabled = true;
  bool _giftsEnabled = true;
  String? _guestDisplayName;
  double _micLevel = 0.85;
  double _bgmLevel = 0.45;
  Set<String> _activeEffects = <String>{};
  String _activeFilter = 'Original';
  double _lightIntensity = 0.3;
  GiftDisplay? _activeGift;

  List<CameraDescription> _availableCameras = const [];
  CameraController? _cameraController;
  int _selectedCameraIndex = 0;
  bool _cameraInitializing = false;
  String? _cameraErrorMessage;
  bool _permissionsDenied = false;

  @override
  void initState() {
    super.initState();
    // Initialize state from widget parameters
    _cameraOn = widget.cameraEnabled;
    _screenSharing = widget.screenShareEnabled;

    _seedInitialComments();
    _startMockStreams();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _initializeLiveHardware(),
    );
  }

  @override
  void dispose() {
    _mockCommentTimer?.cancel();
    _mockJoinTimer?.cancel();
    _mockReactionTimer?.cancel();
    _giftTimer?.cancel();
    _cameraController?.dispose();
    _commentController.dispose();
    _reactionController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _seedInitialComments() {
    const seed = [
      LiveComment(username: 'Priya', message: 'Love this energy! 🔥'),
      LiveComment(username: 'Lena', message: 'You look stunning ✨'),
      LiveComment(username: 'Tom', message: 'Tuning in from NYC!'),
    ];
    for (final comment in seed) {
      _pushComment(comment);
    }
  }

  void _startMockStreams() {
    final random = Random();
    _mockCommentTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_commentsEnabled) return;
      final user = _mockUsernames[random.nextInt(_mockUsernames.length)];
      final phrases = [
        'This is epic! 💥',
        'Sending love from Berlin ❤️',
        'Drop that playlist!',
        'The vibes are immaculate ✨',
        'Can we get a sneak peek?',
      ];
      _pushComment(
        LiveComment(
          username: user,
          message: phrases[random.nextInt(phrases.length)],
        ),
      );
    });

    _mockJoinTimer = Timer.periodic(const Duration(seconds: 11), (_) {
      final user = _mockUsernames[random.nextInt(_mockUsernames.length)];
      final message = '@$user joined the live';
      setState(() => _latestJoin = message);
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted && _latestJoin == message) {
          setState(() => _latestJoin = null);
        }
      });
    });

    _mockReactionTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      const emojis = ['❤️', '💜', '💛', '🔥'];
      _reactionController.addReaction(emojis[random.nextInt(emojis.length)]);
    });
  }

  Future<void> _initializeLiveHardware() async {
    setState(() {
      _cameraInitializing = true;
      _cameraErrorMessage = null;
      _permissionsDenied = false;
    });

    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        setState(() {
          _cameraErrorMessage = 'No cameras available';
          _cameraInitializing = false;
        });
        return;
      }
      _selectedCameraIndex = min(
        _selectedCameraIndex,
        _availableCameras.length - 1,
      );
      await _startCameraStream(_availableCameras[_selectedCameraIndex]);
    } on CameraException catch (error) {
      // Check if it's a permission error
      if (error.code == 'CameraAccessDenied' ||
          error.code == 'AudioAccessDenied' ||
          error.description?.toLowerCase().contains('permission') == true) {
        setState(() {
          _permissionsDenied = true;
          _cameraInitializing = false;
        });
      } else {
        setState(() {
          _cameraErrorMessage = error.description ?? 'Failed to start camera';
          _cameraInitializing = false;
        });
      }
    } catch (error) {
      setState(() {
        _cameraErrorMessage = 'Failed to initialize: $error';
        _cameraInitializing = false;
      });
    }
  }

  Future<void> _startCameraStream(CameraDescription camera) async {
    await _cameraController?.dispose();
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: _micOn,
    );
    _cameraController = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _cameraInitializing = false;
        _cameraErrorMessage = null;
      });
    } on CameraException catch (error) {
      setState(() {
        _cameraInitializing = false;
        _cameraErrorMessage =
            error.description ?? 'Failed to initialize camera';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2 || _cameraInitializing) return;
    final nextIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    setState(() {
      _cameraInitializing = true;
      _selectedCameraIndex = nextIndex;
    });
    await _startCameraStream(_availableCameras[nextIndex]);
  }

  Future<void> _toggleMicWithPermission() async {
    // Simply toggle the mic state
    // Camera will handle permissions when initializing
    setState(() {
      _micOn = !_micOn;
    });

    // Reinitialize camera with new audio setting
    if (_availableCameras.isNotEmpty) {
      setState(() => _cameraInitializing = true);
      try {
        await _startCameraStream(_availableCameras[_selectedCameraIndex]);
      } on CameraException catch (error) {
        if (error.code == 'AudioAccessDenied' ||
            error.description?.toLowerCase().contains('microphone') == true) {
          setState(() {
            _permissionsDenied = true;
            _micOn = false; // Revert to off if permission denied
            _cameraInitializing = false;
          });
        }
      }
    }
  }

  void _toggleCoHost(bool value, {String? guestName}) {
    setState(() {
      _coHostJoined = value;
      _guestDisplayName = value
          ? (guestName ?? _guestDisplayName ?? 'Guest')
          : null;
    });
  }

  void _toggleCamera() {
    setState(() {
      _cameraOn = !_cameraOn;
    });

    if (_cameraOn) {
      // Re-initialize camera
      _initializeLiveHardware();
    } else {
      // Pause/stop camera feed
      _cameraController?.pausePreview();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_cameraOn ? 'Camera turned on' : 'Camera turned off'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleScreenShare() {
    setState(() {
      _screenSharing = !_screenSharing;
    });

    if (_screenSharing) {
      // Start screen sharing - in production, integrate with actual screen capture
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Screen sharing started'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Stop screen sharing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Screen sharing stopped'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleComments(bool value) {
    setState(() => _commentsEnabled = value);
  }

  void _toggleGifts(bool value) {
    setState(() => _giftsEnabled = value);
  }

  void _submitComment(String text) {
    if (text.trim().isEmpty || !_commentsEnabled) return;
    _pushComment(LiveComment(username: 'You', message: text.trim()));
    _textController.clear();
  }

  void _pushComment(LiveComment comment) {
    _commentHistory.insert(0, comment);
    if (_commentHistory.length > 200) {
      _commentHistory.removeLast();
    }
    _commentController.addComment(comment);
  }

  void _sendHeart() {
    if (!_giftsEnabled) return;
    const palette = ['❤️', '💗', '💜', '💛', '🔥'];
    _reactionController.addReaction(palette[Random().nextInt(palette.length)]);
  }

  Future<void> _openCommentSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.85),
      barrierColor: Colors.black54,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: CommentSheet(
            comments: List<LiveComment>.from(_commentHistory),
            onSubmit: (value) {
              Navigator.of(context).pop();
              _submitComment(value);
            },
          ),
        );
      },
    );
  }

  Future<void> _openGiftMenu() async {
    if (!_giftsEnabled) return;
    final gifts = GiftDisplay.samples();
    final selected = await showModalBottomSheet<GiftDisplay>(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.85),
      barrierColor: Colors.black54,
      builder: (context) => GiftMenuSheet(gifts: gifts),
    );
    if (selected != null) {
      _triggerGiftCelebration(selected);
    }
  }

  Future<void> _openShareSheet() async {
    final option = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.85),
      barrierColor: Colors.black54,
      builder: (context) => const ShareOptionsSheet(),
    );
    if (option != null && mounted) {
      _showSnack('Shared via $option');
    }
  }

  Future<void> _openAudioMixPanel() async {
    final result = await showModalBottomSheet<AudioMixSettings>(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.85),
      barrierColor: Colors.black54,
      isScrollControlled: true,
      builder: (context) =>
          AudioMixSheet(micLevel: _micLevel, bgmLevel: _bgmLevel),
    );
    if (result != null) {
      setState(() {
        _micLevel = result.micLevel;
        _bgmLevel = result.bgmLevel;
      });
      _showSnack('Audio mix updated');
    }
  }

  Future<void> _openEffectsPanel() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.85),
      barrierColor: Colors.black54,
      builder: (context) => EffectsSheet(activeEffects: _activeEffects),
    );
    if (result != null) {
      setState(() => _activeEffects = result);
    }
  }

  Future<void> _openFiltersPanel() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.85),
      barrierColor: Colors.black54,
      builder: (context) => FiltersSheet(selected: _activeFilter),
    );
    if (result != null) {
      setState(() => _activeFilter = result);
    }
  }

  Future<void> _openLightsPanel() async {
    final result = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.85),
      barrierColor: Colors.black54,
      builder: (context) => LightsSheet(lightIntensity: _lightIntensity),
    );
    if (result != null) {
      setState(() => _lightIntensity = result);
    }
  }

  Future<void> _handleCoHostAction() async {
    final action = await showModalBottomSheet<CoHostAction>(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.85),
      barrierColor: Colors.black54,
      builder: (context) =>
          CoHostSheet(currentGuest: _guestDisplayName, isActive: _coHostJoined),
    );
    if (action == null) return;
    switch (action.type) {
      case CoHostActionType.invite:
        _toggleCoHost(true, guestName: action.guestName);
      case CoHostActionType.remove:
        _toggleCoHost(false);
    }
  }

  Future<void> _openSystemSettings() async {
    // Show a message to the user to manually enable permissions
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enable Camera and Microphone permissions in Settings',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _triggerGiftCelebration(GiftDisplay gift) {
    _giftTimer?.cancel();
    setState(() => _activeGift = gift);
    _reactionController.addReaction(gift.emoji);
    _giftTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _activeGift = null);
      }
    });
    _showSnack('Sent ${gift.label}!');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.85),
      ),
    );
  }

  Future<void> _openSettingsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.75),
      barrierColor: Colors.black54,
      isScrollControlled: true,
      builder: (context) {
        return LiveSettingsSheet(
          micOn: _micOn,
          commentsEnabled: _commentsEnabled,
          giftsEnabled: _giftsEnabled,
          coHostActive: _coHostJoined,
          onToggleMic: _toggleMicWithPermission,
          onToggleComments: _toggleComments,
          onToggleGifts: _toggleGifts,
          onToggleCoHost: (value) => _toggleCoHost(value),
          onEndLive: () async {
            Navigator.of(context).pop();
            await _showEndLiveConfirmation();
          },
        );
      },
    );
  }

  Future<void> _showEndLiveConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.videocam_off_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'End Live Stream?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to end your live stream? You can\'t undo this action.',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'End Live',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _showEndLiveSummary();
    }
  }

  Future<void> _showEndLiveSummary() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.85),
      barrierColor: Colors.black87,
      isScrollControlled: true,
      builder: (context) => const EndLiveSummarySheet(
        totalViewers: '4.8K',
        totalLikes: '62.4K',
        totalComments: '2.1K',
        duration: '48m 12s',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onDoubleTap: _sendHeart,
        child: Stack(
          children: [
            VideoFeedView(
              controller: _cameraController,
              initializing: _cameraInitializing,
              permissionsDenied: _permissionsDenied,
              errorMessage: _cameraErrorMessage,
              onRetry: _initializeLiveHardware,
              onOpenSettings: _openSystemSettings,
              coHostActive: _coHostJoined,
              hostName: 'Harper Ray',
              guestName: _coHostJoined ? (_guestDisplayName ?? 'Guest') : null,
              activeFilter: _activeFilter,
              lightIntensity: _lightIntensity,
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: TopBarLiveInfo(
                hostName: 'Harper Ray',
                hostAvatarUrl:
                    'https://images.unsplash.com/photo-1614289371518-722f2615943c?auto=format&fit=crop&w=200&q=80',
                viewerCount: '1.2K watching',
                onMenuPressed: _openSettingsSheet,
                screenSharing: _screenSharing,
                onToggleScreenShare: _toggleScreenShare,
              ),
            ),
            Positioned(
              left: 16,
              bottom: 170,
              child: SizedBox(
                width: min(MediaQuery.of(context).size.width * 0.55, 240),
                child: LiveCommentFeed(
                  controller: _commentController,
                  displayDuration: _commentDisplayDuration,
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 120,
              child: SizedBox(
                width: 140,
                height: 280,
                child: FloatingReactionsLayer(controller: _reactionController),
              ),
            ),
            if (_latestJoin != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 72,
                left: 16,
                child: JoinNotificationBubble(message: _latestJoin!),
              ),
            if (_activeGift != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 110,
                right: 16,
                child: GiftCelebrationBadge(gift: _activeGift!),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomInputBar(
                controller: _textController,
                onSubmitted: _submitComment,
                onTapHeart: _sendHeart,
                onOpenComments: _openCommentSheet,
                onTapGift: _giftsEnabled ? _openGiftMenu : null,
                onTapShare: _openShareSheet,
                onTapCameraSwitch: _switchCamera,
                onTapAddGuest: _handleCoHostAction,
                onToggleMic: _toggleMicWithPermission,
                onToggleCamera: _toggleCamera,
                onOpenAudioMix: _openAudioMixPanel,
                onOpenEffects: _openEffectsPanel,
                onOpenFilters: _openFiltersPanel,
                onOpenLights: _openLightsPanel,
                micOn: _micOn,
                cameraOn: _cameraOn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoFeedView extends StatelessWidget {
  const VideoFeedView({
    super.key,
    required this.controller,
    required this.initializing,
    required this.permissionsDenied,
    this.errorMessage,
    required this.onRetry,
    required this.onOpenSettings,
    required this.coHostActive,
    required this.hostName,
    this.guestName,
    required this.activeFilter,
    required this.lightIntensity,
  });

  final CameraController? controller;
  final bool initializing;
  final bool permissionsDenied;
  final String? errorMessage;
  final Future<void> Function() onRetry;
  final Future<void> Function() onOpenSettings;
  final bool coHostActive;
  final String hostName;
  final String? guestName;
  final String activeFilter;
  final double lightIntensity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Colors.black),
            child: coHostActive
                ? _buildSplitFeeds(context)
                : _buildHostFeed(context),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0xAA000000)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHostFeed(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCameraSurface(context),
        Positioned(left: 16, bottom: 24, child: _nameTag(hostName)),
      ],
    );
  }

  Widget _buildSplitFeeds(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildHostFeed(context)),
        Expanded(child: _buildGuestPlaceholder()),
      ],
    );
  }

  Widget _buildCameraSurface(BuildContext context) {
    if (permissionsDenied) {
      return _buildStateMessage(
        icon: Icons.lock_outline,
        title: 'Camera & mic access needed',
        subtitle: 'Allow permissions to start your live stream.',
        primaryActionLabel: 'Grant access',
        primaryAction: onOpenSettings,
        secondaryActionLabel: 'Try again',
        secondaryAction: onRetry,
      );
    }

    if (errorMessage != null) {
      return _buildStateMessage(
        icon: Icons.videocam_off_rounded,
        title: 'Camera error',
        subtitle: errorMessage,
        primaryActionLabel: 'Retry',
        primaryAction: onRetry,
      );
    }

    final currentController = controller;
    if (initializing ||
        currentController == null ||
        !currentController.value.isInitialized) {
      return _buildLoadingSurface();
    }

    // Calculate scale to fill screen while maintaining aspect ratio
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final cameraRatio = currentController.value.aspectRatio;

    double scale;
    if (cameraRatio > deviceRatio) {
      // Camera is wider, scale based on height
      scale = 1 / cameraRatio / deviceRatio;
    } else {
      // Camera is taller, scale based on width
      scale = 1.0;
    }

    Widget preview = Transform.scale(
      scale: scale,
      child: Center(child: CameraPreview(currentController)),
    );

    // Apply color filter if needed
    final filter = _filterForName(activeFilter);
    if (filter != null) {
      preview = ColorFiltered(colorFilter: filter, child: preview);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        preview,
        if (lightIntensity > 0)
          Container(
            color: Colors.white.withOpacity(lightIntensity.clamp(0, 1) * 0.22),
          ),
      ],
    );
  }

  Widget _buildGuestPlaceholder() {
    final gradientOverlay = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0x33000000), Color(0x88000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => const LinearGradient(
            colors: [Color(0xFF3A1C71), Color(0xFFD76D77)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect),
          child: Image.network(
            'https://images.unsplash.com/photo-1499996860823-5214fcc65f8f?auto=format&fit=crop&w=900&q=80',
            fit: BoxFit.cover,
            color: Colors.white.withOpacity(0.75),
            colorBlendMode: BlendMode.softLight,
          ),
        ),
        gradientOverlay,
        Positioned(left: 16, bottom: 24, child: _nameTag(guestName ?? 'Guest')),
      ],
    );
  }

  Widget _buildLoadingSurface() {
    return Stack(
      alignment: Alignment.center,
      children: const [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        CircularProgressIndicator(color: Colors.white70),
      ],
    );
  }

  Widget _buildStateMessage({
    required IconData icon,
    required String title,
    String? subtitle,
    required String primaryActionLabel,
    required Future<void> Function() primaryAction,
    String? secondaryActionLabel,
    Future<void> Function()? secondaryAction,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xDD1B1B1E), Color(0xDD111115)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.75)),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => primaryAction(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(primaryActionLabel),
              ),
              if (secondaryAction != null && secondaryActionLabel != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => secondaryAction(),
                  child: Text(
                    secondaryActionLabel,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _nameTag(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.radio_button_checked,
            color: Colors.redAccent,
            size: 12,
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: _primaryGradient,
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ColorFilter? _filterForName(String name) {
    switch (name) {
      case 'Warm':
        return const ColorFilter.matrix(<double>[
          1.1,
          0.1,
          0.0,
          0.0,
          0,
          0.05,
          1.0,
          0.0,
          0.0,
          0,
          0.0,
          0.05,
          0.9,
          0.0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      case 'Cool':
        return const ColorFilter.matrix(<double>[
          0.9,
          0.0,
          0.0,
          0.0,
          0,
          0.0,
          0.95,
          0.05,
          0.0,
          0,
          0.0,
          0.1,
          1.1,
          0.0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      case 'Mono':
        return const ColorFilter.matrix(<double>[
          0.33,
          0.33,
          0.33,
          0,
          0,
          0.33,
          0.33,
          0.33,
          0,
          0,
          0.33,
          0.33,
          0.33,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      default:
        return null;
    }
  }
}

class TopBarLiveInfo extends StatelessWidget {
  const TopBarLiveInfo({
    super.key,
    required this.hostName,
    required this.hostAvatarUrl,
    required this.viewerCount,
    required this.onMenuPressed,
    required this.screenSharing,
    required this.onToggleScreenShare,
  });

  final String hostName;
  final String hostAvatarUrl;
  final String viewerCount;
  final VoidCallback onMenuPressed;
  final bool screenSharing;
  final VoidCallback onToggleScreenShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // User info bubble
        Flexible(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _glassColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(hostAvatarUrl),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hostName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            viewerCount,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: _primaryGradient,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x55FF0050),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.fiber_manual_record,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Screen sharing button (icon only)
        GestureDetector(
          onTap: onToggleScreenShare,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: screenSharing
                      ? const LinearGradient(
                          colors: [Color(0xFF00C853), Color(0xFF64DD17)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: screenSharing ? null : _glassColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Icon(
                  Icons.screen_share_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Menu button
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _glassColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: IconButton(
                icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
                onPressed: onMenuPressed,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LiveComment {
  const LiveComment({
    required this.username,
    required this.message,
    this.leadingEmoji,
  });

  final String username;
  final String message;
  final String? leadingEmoji;
}

class LiveCommentFeedController {
  void Function(LiveComment comment)? _addComment;

  void addComment(LiveComment comment) => _addComment?.call(comment);

  void dispose() => _addComment = null;
}

class LiveCommentFeed extends StatefulWidget {
  const LiveCommentFeed({
    super.key,
    required this.controller,
    this.displayDuration = _commentDisplayDuration,
  });

  final LiveCommentFeedController controller;
  final Duration displayDuration;

  @override
  State<LiveCommentFeed> createState() => _LiveCommentFeedState();
}

class _LiveCommentFeedState extends State<LiveCommentFeed> {
  final _listKey = GlobalKey<AnimatedListState>();
  final _items = <_CommentEntry>[];

  @override
  void initState() {
    super.initState();
    widget.controller._addComment = _handleAdd;
  }

  @override
  void dispose() {
    widget.controller._addComment = null;
    super.dispose();
  }

  void _handleAdd(LiveComment comment) {
    final entry = _CommentEntry(comment: comment);
    _items.insert(0, entry);
    _listKey.currentState?.insertItem(0);
    Future<void>.delayed(widget.displayDuration, () {
      final index = _items.indexOf(entry);
      if (!mounted || index == -1) return;
      final removed = _items.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildItem(removed, animation),
        duration: const Duration(milliseconds: 350),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(_items.isEmpty ? 0.0 : 0.30),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: AnimatedList(
              key: _listKey,
              shrinkWrap: true,
              reverse: true,
              physics: const NeverScrollableScrollPhysics(),
              initialItemCount: _items.length,
              itemBuilder: (context, index, animation) =>
                  _buildItem(_items[index], animation),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(_CommentEntry entry, Animation<double> animation) {
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(
        position: slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.comment.leadingEmoji != null) ...[
                Text(
                  entry.comment.leadingEmoji!,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '@${entry.comment.username}  ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      TextSpan(
                        text: entry.comment.message,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentEntry {
  _CommentEntry({required this.comment});

  final LiveComment comment;
}

class FloatingReactionController {
  void Function(String emoji)? _onAddReaction;

  void addReaction(String emoji) => _onAddReaction?.call(emoji);

  void dispose() => _onAddReaction = null;
}

class FloatingReactionsLayer extends StatefulWidget {
  const FloatingReactionsLayer({
    super.key,
    required this.controller,
    this.life = const Duration(milliseconds: 2800),
  });

  final FloatingReactionController controller;
  final Duration life;

  @override
  State<FloatingReactionsLayer> createState() => _FloatingReactionsLayerState();
}

class _FloatingReactionsLayerState extends State<FloatingReactionsLayer>
    with SingleTickerProviderStateMixin {
  final _reactions = <_ReactionInstance>[];
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    widget.controller._onAddReaction = _addReaction;
    _ticker = createTicker((_) => setState(() {}))..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    widget.controller._onAddReaction = null;
    super.dispose();
  }

  void _addReaction(String emoji) {
    final random = Random();
    final instance = _ReactionInstance(
      emoji: emoji,
      createdAt: DateTime.now(),
      horizontalOffset: 8 + random.nextDouble() * 60,
      wobbleOffset: -6 + random.nextDouble() * 12,
    );
    setState(() => _reactions.add(instance));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    _reactions.removeWhere(
      (reaction) => now.difference(reaction.createdAt) >= widget.life,
    );

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: _reactions.map((reaction) {
          final progress =
              (now.difference(reaction.createdAt).inMilliseconds /
                      widget.life.inMilliseconds)
                  .clamp(0.0, 1.0);
          final curve = Curves.easeOut.transform(progress);
          final opacity = 1 - Curves.easeInCubic.transform(progress);
          final scale = 0.9 + Curves.easeOutBack.transform(progress) * 0.25;
          final bottom = 20 + curve * 220;

          return Positioned(
            right: reaction.horizontalOffset,
            bottom: bottom,
            child: Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(reaction.wobbleOffset * sin(progress * pi), 0),
                child: Transform.scale(
                  scale: scale,
                  child: Text(
                    reaction.emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReactionInstance {
  _ReactionInstance({
    required this.emoji,
    required this.createdAt,
    required this.horizontalOffset,
    required this.wobbleOffset,
  });

  final String emoji;
  final DateTime createdAt;
  final double horizontalOffset;
  final double wobbleOffset;
}

class JoinNotificationBubble extends StatelessWidget {
  const JoinNotificationBubble({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 300),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('❤️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BottomInputBar extends StatelessWidget {
  const BottomInputBar({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onTapHeart,
    required this.onOpenComments,
    this.onTapGift,
    required this.onTapShare,
    required this.onTapCameraSwitch,
    required this.onTapAddGuest,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onOpenAudioMix,
    required this.onOpenEffects,
    required this.onOpenFilters,
    required this.onOpenLights,
    required this.micOn,
    required this.cameraOn,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onTapHeart;
  final VoidCallback onOpenComments;
  final VoidCallback? onTapGift;
  final VoidCallback onTapShare;
  final VoidCallback onTapCameraSwitch;
  final VoidCallback onTapAddGuest;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
  final VoidCallback onOpenAudioMix;
  final VoidCallback onOpenEffects;
  final VoidCallback onOpenFilters;
  final VoidCallback onOpenLights;
  final bool micOn;
  final bool cameraOn;

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'More Options',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuOption(
              context,
              icon: Icons.group_add_rounded,
              label: 'Co-host',
              onTap: () {
                Navigator.pop(context);
                onTapAddGuest();
              },
            ),
            _buildMenuOption(
              context,
              icon: Icons.auto_awesome_rounded,
              label: 'Effects',
              onTap: () {
                Navigator.pop(context);
                onOpenEffects();
              },
            ),
            _buildMenuOption(
              context,
              icon: Icons.palette_rounded,
              label: 'Filters',
              onTap: () {
                Navigator.pop(context);
                onOpenFilters();
              },
            ),
            _buildMenuOption(
              context,
              icon: Icons.light_mode_rounded,
              label: 'Studio Lights',
              onTap: () {
                Navigator.pop(context);
                onOpenLights();
              },
            ),
            _buildMenuOption(
              context,
              icon: Icons.graphic_eq_rounded,
              label: 'Audio Mix',
              onTap: () {
                Navigator.pop(context);
                onOpenAudioMix();
              },
            ),
            _buildMenuOption(
              context,
              icon: Icons.share_rounded,
              label: 'Share',
              onTap: () {
                Navigator.pop(context);
                onTapShare();
              },
            ),
            if (onTapGift != null)
              _buildMenuOption(
                context,
                icon: Icons.card_giftcard_rounded,
                label: 'Send Gift',
                onTap: () {
                  Navigator.pop(context);
                  onTapGift!();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, padding + 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0xD6000000)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Essential controls row
          Row(
            children: [
              // Microphone toggle
              _CircularIconButton(
                icon: micOn ? Icons.mic_none_rounded : Icons.mic_off_rounded,
                onTap: onToggleMic,
                gradient: micOn ? _primaryGradient : null,
              ),
              const SizedBox(width: 12),

              // Camera toggle
              _CircularIconButton(
                icon: cameraOn
                    ? Icons.videocam_rounded
                    : Icons.videocam_off_rounded,
                onTap: onToggleCamera,
                gradient: cameraOn ? _primaryGradient : null,
              ),
              const SizedBox(width: 12),

              // Camera switch
              _CircularIconButton(
                icon: Icons.cameraswitch_rounded,
                onTap: onTapCameraSwitch,
              ),
              const SizedBox(width: 12),

              // Comments
              _CircularIconButton(
                icon: Icons.chat_bubble_outline_rounded,
                onTap: onOpenComments,
              ),
              const SizedBox(width: 12),

              const Spacer(),

              // Heart button
              _CircularIconButton(
                icon: Icons.favorite_rounded,
                onTap: onTapHeart,
                gradient: _primaryGradient,
              ),
              const SizedBox(width: 12),

              // More options menu
              _CircularIconButton(
                icon: Icons.more_horiz_rounded,
                onTap: () => _showMoreOptions(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularIconButton extends StatelessWidget {
  const _CircularIconButton({required this.icon, this.onTap, this.gradient});

  final IconData icon;
  final VoidCallback? onTap;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? Colors.white.withOpacity(0.12) : null,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Icon(icon, color: Colors.white),
    );

    return GestureDetector(onTap: onTap, child: child);
  }
}

class CommentSheet extends StatefulWidget {
  const CommentSheet({
    super.key,
    required this.comments,
    required this.onSubmit,
  });

  final List<LiveComment> comments;
  final ValueChanged<String> onSubmit;

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.78),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Live chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  reverse: true,
                  itemBuilder: (context, index) {
                    final comment = widget.comments[index];
                    return RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '@${comment.username}  ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text: comment.message,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: widget.comments.length,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        hintText: 'Send a message…',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;
                      widget.onSubmit(text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('Send'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GiftDisplay {
  const GiftDisplay({
    required this.emoji,
    required this.label,
    required this.value,
  });

  final String emoji;
  final String label;
  final int value;

  static List<GiftDisplay> samples() => const [
    GiftDisplay(emoji: '💎', label: 'Crystal Burst', value: 10),
    GiftDisplay(emoji: '🎉', label: 'Confetti Rain', value: 25),
    GiftDisplay(emoji: '🔥', label: 'Firestorm', value: 35),
    GiftDisplay(emoji: '🚀', label: 'Rocket Boost', value: 50),
    GiftDisplay(emoji: '👑', label: 'Crown Drop', value: 75),
    GiftDisplay(emoji: '🌟', label: 'Star Shower', value: 100),
  ];
}

class GiftMenuSheet extends StatelessWidget {
  const GiftMenuSheet({super.key, required this.gifts});

  final List<GiftDisplay> gifts;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.78),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Send a gift',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: gifts.length,
                itemBuilder: (context, index) {
                  final gift = gifts[index];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(gift),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: _primaryGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33FF0050),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            gift.emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            gift.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${gift.value} coins',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GiftCelebrationBadge extends StatelessWidget {
  const GiftCelebrationBadge({super.key, required this.gift});

  final GiftDisplay gift;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(gift.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    gift.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${gift.value} coins',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShareOptionsSheet extends StatelessWidget {
  const ShareOptionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final options = [
      {'icon': Icons.send_rounded, 'label': 'Direct message'},
      {'icon': Icons.link_rounded, 'label': 'Copy link'},
      {'icon': Icons.ios_share_rounded, 'label': 'Share to story'},
      {'icon': Icons.groups_rounded, 'label': 'Invite friends'},
    ];
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.78),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0x33FFFFFF)),
                itemBuilder: (context, index) {
                  final option = options[index];
                  return ListTile(
                    onTap: () =>
                        Navigator.of(context).pop(option['label'] as String),
                    leading: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.12),
                      child: Icon(
                        option['icon'] as IconData,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      option['label'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white70,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AudioMixSettings {
  const AudioMixSettings({required this.micLevel, required this.bgmLevel});

  final double micLevel;
  final double bgmLevel;
}

class AudioMixSheet extends StatefulWidget {
  const AudioMixSheet({
    super.key,
    required this.micLevel,
    required this.bgmLevel,
  });

  final double micLevel;
  final double bgmLevel;

  @override
  State<AudioMixSheet> createState() => _AudioMixSheetState();
}

class _AudioMixSheetState extends State<AudioMixSheet> {
  late double _micLevel;
  late double _bgmLevel;

  @override
  void initState() {
    super.initState();
    _micLevel = widget.micLevel;
    _bgmLevel = widget.bgmLevel;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24 + 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.82),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 20),
              _AudioSlider(
                icon: Icons.mic_rounded,
                label: 'Microphone',
                value: _micLevel,
                onChanged: (value) => setState(() => _micLevel = value),
              ),
              const SizedBox(height: 16),
              _AudioSlider(
                icon: Icons.music_note_rounded,
                label: 'Background',
                value: _bgmLevel,
                onChanged: (value) => setState(() => _bgmLevel = value),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(
                  AudioMixSettings(micLevel: _micLevel, bgmLevel: _bgmLevel),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text('Apply mix'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioSlider extends StatelessWidget {
  const _AudioSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.9)),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.25),
            thumbColor: Colors.white,
          ),
          child: Slider(value: value, onChanged: onChanged),
        ),
      ],
    );
  }
}

class EffectsSheet extends StatefulWidget {
  const EffectsSheet({super.key, required this.activeEffects});

  final Set<String> activeEffects;

  @override
  State<EffectsSheet> createState() => _EffectsSheetState();
}

class _EffectsSheetState extends State<EffectsSheet> {
  late Set<String> _selected;

  final _effects = const [
    'Sparkles',
    'Retro Glow',
    'Portrait',
    'Disco Pulse',
    'Studio Blur',
    'VHS',
  ];

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.activeEffects);
  }

  @override
  Widget build(BuildContext context) {
    return _GlassSheet(
      title: 'Effects',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _effects.length,
            itemBuilder: (context, index) {
              final effect = _effects[index];
              final selected = _selected.contains(effect);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selected.remove(effect);
                    } else {
                      _selected.add(effect);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: selected
                        ? _primaryGradient
                        : const LinearGradient(
                            colors: [Color(0x33000000), Color(0x66000000)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    border: Border.all(
                      color: Colors.white.withOpacity(selected ? 0.2 : 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.auto_awesome_rounded,
                        color: Colors.white,
                      ),
                      const Spacer(),
                      Text(
                        effect,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _PrimarySheetButton(
            label: 'Apply effects',
            onPressed: () => Navigator.of(context).pop(_selected),
          ),
        ],
      ),
    );
  }
}

class FiltersSheet extends StatefulWidget {
  const FiltersSheet({super.key, required this.selected});

  final String selected;

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  final _filters = const ['Original', 'Warm', 'Cool', 'Mono'];
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return _GlassSheet(
      title: 'Filters',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filters.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0x22FFFFFF)),
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final selected = _selected == filter;
              return ListTile(
                onTap: () => setState(() => _selected = filter),
                leading: CircleAvatar(
                  backgroundColor: selected
                      ? Colors.white
                      : Colors.white.withOpacity(0.12),
                  child: Icon(
                    Icons.palette_rounded,
                    color: selected ? Colors.black : Colors.white,
                  ),
                ),
                title: Text(
                  filter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: selected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                      )
                    : const Icon(Icons.circle_outlined, color: Colors.white54),
              );
            },
          ),
          const SizedBox(height: 20),
          _PrimarySheetButton(
            label: 'Use $_selected',
            onPressed: () => Navigator.of(context).pop(_selected),
          ),
        ],
      ),
    );
  }
}

class LightsSheet extends StatefulWidget {
  const LightsSheet({super.key, required this.lightIntensity});

  final double lightIntensity;

  @override
  State<LightsSheet> createState() => _LightsSheetState();
}

class _LightsSheetState extends State<LightsSheet> {
  late double _intensity;

  @override
  void initState() {
    super.initState();
    _intensity = widget.lightIntensity;
  }

  @override
  Widget build(BuildContext context) {
    return _GlassSheet(
      title: 'Studio lights',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text(
            'Balance your virtual lighting setup.',
            style: TextStyle(color: Colors.white.withOpacity(0.75)),
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.25),
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: _intensity,
              onChanged: (value) => setState(() => _intensity = value),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Intensity ${(100 * _intensity).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _PrimarySheetButton(
            label: 'Save lighting',
            onPressed: () => Navigator.of(context).pop(_intensity),
          ),
        ],
      ),
    );
  }
}

enum CoHostActionType { invite, remove }

class CoHostAction {
  const CoHostAction._(this.type, this.guestName);

  factory CoHostAction.invite(String name) =>
      CoHostAction._(CoHostActionType.invite, name);
  factory CoHostAction.remove() =>
      const CoHostAction._(CoHostActionType.remove, null);

  final CoHostActionType type;
  final String? guestName;
}

class CoHostSheet extends StatefulWidget {
  const CoHostSheet({super.key, this.currentGuest, required this.isActive});

  final String? currentGuest;
  final bool isActive;

  @override
  State<CoHostSheet> createState() => _CoHostSheetState();
}

class _CoHostSheetState extends State<CoHostSheet> {
  final _potentialGuests = const [
    'Noah K.',
    'Val Phoenix',
    'Iris Bloom',
    'Ravi',
    'Eli',
  ];
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentGuest ?? _potentialGuests.first;
  }

  @override
  Widget build(BuildContext context) {
    return _GlassSheet(
      title: 'Manage co-host',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isActive && widget.currentGuest != null) ...[
            _SheetInfoBanner(text: '${widget.currentGuest} is co-hosting'),
            const SizedBox(height: 16),
          ] else ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select a guest to invite',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _potentialGuests.map((guest) {
                final selected = _selected == guest;
                return ChoiceChip(
                  label: Text(guest),
                  selected: selected,
                  onSelected: (_) => setState(() => _selected = guest),
                  selectedColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                  ),
                  backgroundColor: Colors.white.withOpacity(0.15),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
          if (widget.isActive)
            _PrimarySheetButton(
              label: 'Remove co-host',
              destructive: true,
              onPressed: () => Navigator.of(context).pop(CoHostAction.remove()),
            )
          else
            _PrimarySheetButton(
              label: 'Invite ${_selected ?? 'guest'}',
              onPressed: () => Navigator.of(
                context,
              ).pop(CoHostAction.invite(_selected ?? 'Guest')),
            ),
        ],
      ),
    );
  }
}

class LiveSettingsSheet extends StatefulWidget {
  const LiveSettingsSheet({
    super.key,
    required this.micOn,
    required this.commentsEnabled,
    required this.giftsEnabled,
    required this.coHostActive,
    required this.onToggleMic,
    required this.onToggleComments,
    required this.onToggleGifts,
    required this.onToggleCoHost,
    required this.onEndLive,
  });

  final bool micOn;
  final bool commentsEnabled;
  final bool giftsEnabled;
  final bool coHostActive;
  final Future<void> Function() onToggleMic;
  final ValueChanged<bool> onToggleComments;
  final ValueChanged<bool> onToggleGifts;
  final ValueChanged<bool> onToggleCoHost;
  final VoidCallback onEndLive;

  @override
  State<LiveSettingsSheet> createState() => _LiveSettingsSheetState();
}

class _LiveSettingsSheetState extends State<LiveSettingsSheet> {
  late bool _micOn;
  late bool _commentsEnabled;
  late bool _giftsEnabled;
  late bool _coHostActive;

  @override
  void initState() {
    super.initState();
    _micOn = widget.micOn;
    _commentsEnabled = widget.commentsEnabled;
    _giftsEnabled = widget.giftsEnabled;
    _coHostActive = widget.coHostActive;
  }

  @override
  Widget build(BuildContext context) {
    return _GlassSheet(
      title: 'Live controls',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile.adaptive(
            value: _micOn,
            onChanged: (_) async {
              await widget.onToggleMic();
              if (!mounted) return;
              setState(() => _micOn = !_micOn);
            },
            title: const Text(
              'Microphone',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _micOn ? 'Your audience can hear you' : 'Mic muted',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            secondary: const Icon(Icons.mic_rounded, color: Colors.white70),
            activeColor: Colors.white,
          ),
          const Divider(color: Color(0x22FFFFFF)),
          SwitchListTile.adaptive(
            value: _commentsEnabled,
            onChanged: (value) {
              widget.onToggleComments(value);
              setState(() => _commentsEnabled = value);
            },
            title: const Text(
              'Allow comments',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _commentsEnabled
                  ? 'Viewers can participate in the chat'
                  : 'Chat is currently disabled',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            secondary: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white70,
            ),
            activeColor: Colors.white,
          ),
          const Divider(color: Color(0x22FFFFFF)),
          SwitchListTile.adaptive(
            value: _giftsEnabled,
            onChanged: (value) {
              widget.onToggleGifts(value);
              setState(() => _giftsEnabled = value);
            },
            title: const Text(
              'Enable gifts',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _giftsEnabled
                  ? 'Viewers can send live gifts'
                  : 'Gift reactions disabled',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            secondary: const Icon(
              Icons.card_giftcard_rounded,
              color: Colors.white70,
            ),
            activeColor: Colors.white,
          ),
          const Divider(color: Color(0x22FFFFFF)),
          SwitchListTile.adaptive(
            value: _coHostActive,
            onChanged: (value) {
              widget.onToggleCoHost(value);
              setState(() => _coHostActive = value);
            },
            title: const Text(
              'Co-host slot',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _coHostActive ? 'Co-host session active' : 'No guest connected',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            secondary: const Icon(Icons.group_rounded, color: Colors.white70),
            activeColor: Colors.white,
          ),
          const SizedBox(height: 20),
          _PrimarySheetButton(
            label: 'End live',
            destructive: true,
            onPressed: () {
              Navigator.of(context).pop();
              widget.onEndLive();
            },
          ),
        ],
      ),
    );
  }
}

class EndLiveSummarySheet extends StatelessWidget {
  const EndLiveSummarySheet({
    super.key,
    required this.totalViewers,
    required this.totalLikes,
    required this.totalComments,
    required this.duration,
  });

  final String totalViewers;
  final String totalLikes;
  final String totalComments;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return _GlassSheet(
      title: 'Live summary',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryStat(label: 'Viewers', value: totalViewers),
              _SummaryStat(label: 'Likes', value: totalLikes),
              _SummaryStat(label: 'Comments', value: totalComments),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_rounded, color: Colors.white70),
                const SizedBox(width: 12),
                Text(
                  'Live duration',
                  style: TextStyle(color: Colors.white.withOpacity(0.75)),
                ),
                const Spacer(),
                Text(
                  duration,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _PrimarySheetButton(
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
      ],
    );
  }
}

class _GlassSheet extends StatelessWidget {
  const _GlassSheet({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24 + 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.78),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimarySheetButton extends StatelessWidget {
  const _PrimarySheetButton({
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: destructive ? const Color(0xFFFF3B30) : Colors.white,
          foregroundColor: destructive ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _SheetInfoBanner extends StatelessWidget {
  const _SheetInfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
