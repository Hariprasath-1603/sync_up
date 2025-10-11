import 'dart:async';
import 'package:flutter/material.dart';
import 'models/live_stream_model.dart';
import 'models/stream_config.dart';
import 'models/live_chat_message.dart';
import 'widgets/live_chat_widget.dart';

class LiveHostPage extends StatefulWidget {
  final LiveStreamModel stream;

  const LiveHostPage({super.key, required this.stream});

  @override
  State<LiveHostPage> createState() => _LiveHostPageState();
}

class _LiveHostPageState extends State<LiveHostPage> {
  late LiveStreamModel _stream;
  StreamHealthMetrics _healthMetrics = StreamHealthMetrics();
  Timer? _healthTimer;
  Timer? _durationTimer;
  Duration _streamDuration = Duration.zero;
  bool _isStreaming = false;
  bool _isPaused = false;
  bool _showChat = true;
  bool _showControls = true;

  final List<LiveChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _stream = widget.stream;
    _startStream();
  }

  @override
  void dispose() {
    _healthTimer?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }

  void _startStream() {
    setState(() {
      _isStreaming = true;
      _stream = _stream.copyWith(
        status: LiveStreamStatus.live,
        startedAt: DateTime.now(),
      );
    });

    // Simulate health metrics updates
    _healthTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _isStreaming && !_isPaused) {
        setState(() {
          _healthMetrics = StreamHealthMetrics(
            bitrate: 2400 + (DateTime.now().second % 300),
            fps: 30,
            droppedFrames: DateTime.now().second % 5,
            bandwidth: 2.5 + (DateTime.now().second % 10) / 10,
            latency: 150 + (DateTime.now().second % 100),
            quality: 'HD',
            isStable: true,
          );
        });
      }
    });

    // Update stream duration
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isStreaming && !_isPaused) {
        setState(() {
          _streamDuration += const Duration(seconds: 1);
        });
      }
    });

    // Simulate viewer count changes
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _isStreaming) {
        setState(() {
          final change = (DateTime.now().second % 3) - 1;
          _stream = _stream.copyWith(
            viewerCount: (_stream.viewerCount + change).clamp(0, 10000),
          );
        });
      }
    });
  }

  void _endStream() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'End Live Stream?',
          style: TextStyle(color: _getTextColor(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your stream will end and viewers will no longer be able to watch.',
              style: TextStyle(color: _getSubtitleColor(context)),
            ),
            const SizedBox(height: 16),
            _buildStat('Duration', _formatDuration(_streamDuration)),
            _buildStat('Peak Viewers', '${_stream.viewerCount}'),
            _buildStat('Total Views', '${_stream.totalViews}'),
            _buildStat('Likes', '${_stream.likeCount}'),
            _buildStat('Comments', '${_stream.commentCount}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: _getSubtitleColor(context)),
            ),
          ),
          TextButton(
            onPressed: () {
              _healthTimer?.cancel();
              _durationTimer?.cancel();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text(
              'End Stream',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: _getSubtitleColor(context), fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: _getTextColor(context),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    _showSnackBar(
      _isPaused ? 'Stream paused' : 'Stream resumed',
      const Color(0xFF4A6CF7),
    );
  }

  void _showStreamOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _getBorderColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildOption(Icons.person_add, 'Invite Guest', () {
              Navigator.pop(context);
              _showSnackBar('Guest invite feature coming soon', Colors.orange);
            }),
            _buildOption(Icons.settings, 'Stream Settings', () {
              Navigator.pop(context);
              _showStreamSettings();
            }),
            _buildOption(Icons.bar_chart, 'Analytics', () {
              Navigator.pop(context);
              _showAnalytics();
            }),
            _buildOption(Icons.block, 'Moderation', () {
              Navigator.pop(context);
              _showModeration();
            }),
            _buildOption(Icons.share, 'Share Stream', () {
              Navigator.pop(context);
              _showSnackBar('Share link copied!', const Color(0xFF4A6CF7));
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: _getTextColor(context)),
      title: Text(title, style: TextStyle(color: _getTextColor(context))),
      onTap: onTap,
    );
  }

  void _showStreamSettings() {
    _showSnackBar('Stream settings coming soon', Colors.orange);
  }

  void _showAnalytics() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _getBorderColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Stream Analytics',
              style: TextStyle(
                color: _getTextColor(context),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildAnalyticCard(
              'Current Viewers',
              '${_stream.viewerCount}',
              Icons.visibility,
            ),
            _buildAnalyticCard(
              'Total Views',
              '${_stream.totalViews}',
              Icons.remove_red_eye,
            ),
            _buildAnalyticCard('Likes', '${_stream.likeCount}', Icons.favorite),
            _buildAnalyticCard(
              'Comments',
              '${_stream.commentCount}',
              Icons.chat_bubble,
            ),
            _buildAnalyticCard(
              'Tips Received',
              '\$${_stream.totalTips.toStringAsFixed(2)}',
              Icons.attach_money,
            ),
            _buildAnalyticCard(
              'Stream Duration',
              _formatDuration(_streamDuration),
              Icons.timer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4A6CF7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF4A6CF7)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _getSubtitleColor(context),
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: _getTextColor(context),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showModeration() {
    _showSnackBar('Moderation tools coming soon', Colors.orange);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0F1419)
        : const Color(0xFFF8F9FA);
  }

  Color _getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1D24)
        : Colors.white;
  }

  Color _getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  Color _getSubtitleColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF8899A6)
        : const Color(0xFF536471);
  }

  Color _getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2F3336)
        : const Color(0xFFE1E8ED);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Camera Preview (simulated)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam,
                    size: 100,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Camera Feed',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _stream.title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top overlay
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    // Live badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
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
                          const SizedBox(width: 6),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Duration
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatDuration(_streamDuration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Viewer count
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_stream.viewerCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // More options
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: _showStreamOptions,
                    ),
                  ],
                ),
              ),
            ),

          // Chat overlay
          if (_showChat)
            Positioned(
              left: 16,
              right: 16,
              bottom: 150,
              child: LiveChatWidget(
                streamId: _stream.id,
                messages: _messages,
                onSendMessage: (message) {
                  // Handle send message
                },
              ),
            ),

          // Bottom controls
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  top: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      _isPaused ? Icons.play_arrow : Icons.pause,
                      _isPaused ? 'Resume' : 'Pause',
                      _togglePause,
                    ),
                    _buildControlButton(
                      Icons.flip_camera_ios,
                      'Flip',
                      () => _showSnackBar('Camera flipped', Colors.blue),
                    ),
                    _buildControlButton(
                      _showChat ? Icons.chat : Icons.chat_bubble_outline,
                      'Chat',
                      () => setState(() => _showChat = !_showChat),
                    ),
                    _buildControlButton(
                      Icons.mic,
                      'Mic',
                      () => _showSnackBar('Mic toggled', Colors.blue),
                    ),
                    _buildControlButton(
                      Icons.stop,
                      'End',
                      _endStream,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),

          // Stream health indicator
          if (_showControls)
            Positioned(
              top: MediaQuery.of(context).padding.top + 100,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: _getCardColor(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        'Stream Health',
                        style: TextStyle(color: _getTextColor(context)),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHealthStat(
                            'Bitrate',
                            '${_healthMetrics.bitrate} kbps',
                          ),
                          _buildHealthStat('FPS', '${_healthMetrics.fps}'),
                          _buildHealthStat(
                            'Dropped Frames',
                            '${_healthMetrics.droppedFrames}',
                          ),
                          _buildHealthStat(
                            'Bandwidth',
                            '${_healthMetrics.bandwidth.toStringAsFixed(1)} Mbps',
                          ),
                          _buildHealthStat(
                            'Latency',
                            '${_healthMetrics.latency} ms',
                          ),
                          _buildHealthStat('Quality', _healthMetrics.quality),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Close',
                            style: TextStyle(color: Color(0xFF4A6CF7)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _healthMetrics.isStable
                        ? Colors.green.withOpacity(0.9)
                        : Colors.orange.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _healthMetrics.isStable
                            ? Icons.signal_cellular_4_bar
                            : Icons.signal_cellular_alt_2_bar,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_healthMetrics.bitrate}\nkbps',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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

  Widget _buildControlButton(
    IconData icon,
    String label,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color ?? Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: _getSubtitleColor(context), fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: _getTextColor(context),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
