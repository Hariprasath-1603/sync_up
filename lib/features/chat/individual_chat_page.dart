import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class IndividualChatPage extends StatefulWidget {
  final String userName;
  final String userId;

  const IndividualChatPage({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<IndividualChatPage> createState() => _IndividualChatPageState();
}

class _IndividualChatPageState extends State<IndividualChatPage>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isRecording = false;
  bool _showEmojiPicker = false;
  double _recordingDuration = 0.0;
  Timer? _recordingTimer;

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hey! How are you doing today? 😊',
      isSent: false,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      messageType: MessageType.text,
    ),
    ChatMessage(
      text: 'I\'m great! Thanks for asking. How about you?',
      isSent: true,
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 1)),
      messageType: MessageType.text,
    ),
    ChatMessage(
      text: 'Doing well! Working on some exciting projects',
      isSent: false,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      messageType: MessageType.text,
    ),
    ChatMessage(
      text: 'That sounds awesome! Tell me more about it',
      isSent: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      messageType: MessageType.text,
    ),
    ChatMessage(
      text: '',
      isSent: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      messageType: MessageType.voice,
      duration: 15,
    ),
    ChatMessage(
      text: 'That\'s really interesting! 🎉',
      isSent: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
      messageType: MessageType.text,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    if (!mounted) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: _messageController.text.trim(),
          isSent: true,
          timestamp: DateTime.now(),
          messageType: MessageType.text,
        ),
      );
      _messageController.clear();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendVoiceMessage() {
    if (!mounted) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: '',
          isSent: true,
          timestamp: DateTime.now(),
          messageType: MessageType.voice,
          duration: _recordingDuration.toInt(),
        ),
      );
      _isRecording = false;
      _recordingDuration = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [kDarkBackground, kDarkBackground.withOpacity(0.8)]
                : [kLightBackground, const Color(0xFFF0F2F8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(child: _buildMessagesList(isDark)),
              if (_isRecording) _buildRecordingIndicator(isDark),
              _buildMessageInput(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
        border: Border(
          bottom: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => context.pop(),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar with online status
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: kPrimary.withOpacity(0.2),
                child: Text(
                  widget.userName[0].toUpperCase(),
                  style: TextStyle(
                    color: kPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? kDarkBackground : kLightBackground,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  'Active now',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Call buttons
          Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.call_rounded, color: kPrimary, size: 22),
              onPressed: () {
                _showCallDialog(false);
              },
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimary, kPrimary.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.videocam_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () {
                _showCallDialog(true);
              },
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final showTimestamp =
            index == 0 ||
            _messages[index - 1].timestamp
                    .difference(message.timestamp)
                    .inMinutes
                    .abs() >
                30;

        return Column(
          children: [
            if (showTimestamp) _buildTimestamp(message.timestamp, isDark),
            _buildMessageBubble(message, isDark),
          ],
        );
      },
    );
  }

  Widget _buildTimestamp(DateTime timestamp, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _formatTimestamp(timestamp),
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white60 : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: message.isSent
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isSent) const SizedBox(width: 40),
          Flexible(
            child: message.messageType == MessageType.voice
                ? _buildVoiceMessage(message, isDark)
                : _buildTextMessage(message, isDark),
          ),
          if (message.isSent) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTextMessage(ChatMessage message, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: message.isSent
            ? LinearGradient(colors: [kPrimary, kPrimary.withOpacity(0.8)])
            : null,
        color: message.isSent
            ? null
            : (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(message.isSent ? 20 : 4),
          bottomRight: Radius.circular(message.isSent ? 4 : 20),
        ),
        border: !message.isSent
            ? Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                width: 1,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: TextStyle(
              fontSize: 15,
              color: message.isSent
                  ? Colors.white
                  : (isDark ? Colors.white : Colors.black87),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatMessageTime(message.timestamp),
                style: TextStyle(
                  fontSize: 11,
                  color: message.isSent
                      ? Colors.white.withOpacity(0.8)
                      : (isDark ? Colors.white60 : Colors.grey.shade600),
                ),
              ),
              if (message.isSent) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.done_all_rounded,
                  size: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceMessage(ChatMessage message, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: message.isSent
            ? LinearGradient(colors: [kPrimary, kPrimary.withOpacity(0.8)])
            : null,
        color: message.isSent
            ? null
            : (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(message.isSent ? 20 : 4),
          bottomRight: Radius.circular(message.isSent ? 4 : 20),
        ),
        border: !message.isSent
            ? Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                width: 1,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: message.isSent
                  ? Colors.white.withOpacity(0.2)
                  : kPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: message.isSent ? Colors.white : kPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          // Waveform visualization
          ...List.generate(
            20,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 2,
              height: (index % 3 + 1) * 8.0,
              decoration: BoxDecoration(
                color: message.isSent
                    ? Colors.white.withOpacity(0.6)
                    : kPrimary.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '0:${message.duration.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 12,
              color: message.isSent
                  ? Colors.white.withOpacity(0.8)
                  : (isDark ? Colors.white60 : Colors.grey.shade600),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border(
          top: BorderSide(color: Colors.red.withOpacity(0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Recording...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 100),
                  duration: const Duration(seconds: 60),
                  onEnd: () {
                    _recordingTimer?.cancel();
                  },
                  builder: (context, value, child) {
                    _recordingDuration = value;
                    return Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: value / 100,
                              backgroundColor: Colors.red.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.red,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${(value / 60).floor()}:${(value % 60).floor().toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () {
              setState(() {
                _isRecording = false;
                _recordingDuration = 0.0;
              });
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimary, kPrimary.withOpacity(0.8)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            onPressed: _sendVoiceMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
        border: Border(
          top: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Emoji/Attachment buttons
          Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: kPrimary,
                size: 24,
              ),
              onPressed: () {
                _showAttachmentOptions();
              },
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 8),
          // Message input
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(
                      0.05,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(
                        0.1,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLines: 4,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: 'Message...',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.white60
                                  : Colors.grey.shade400,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.emoji_emotions_outlined,
                          color: kPrimary,
                          size: 22,
                        ),
                        onPressed: () {
                          setState(() {
                            _showEmojiPicker = !_showEmojiPicker;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send/Voice button
          _messageController.text.trim().isEmpty
              ? GestureDetector(
                  onLongPressStart: (_) {
                    setState(() {
                      _isRecording = true;
                      _recordingDuration = 0.0;
                    });
                    // Start a timer to track recording duration
                    _recordingTimer?.cancel();
                    _recordingTimer = Timer.periodic(
                      const Duration(milliseconds: 100),
                      (timer) {
                        if (mounted) {
                          setState(() {
                            _recordingDuration += 0.1;
                          });
                        }
                      },
                    );
                  },
                  onLongPressEnd: (_) {
                    _recordingTimer?.cancel();
                    if (_recordingDuration > 1) {
                      _sendVoiceMessage();
                    } else {
                      if (mounted) {
                        setState(() {
                          _isRecording = false;
                          _recordingDuration = 0.0;
                        });
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimary, kPrimary.withOpacity(0.8)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimary, kPrimary.withOpacity(0.8)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _showCallDialog(bool isVideo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isVideo ? Icons.videocam_rounded : Icons.call_rounded,
              color: kPrimary,
            ),
            const SizedBox(width: 12),
            Text(isVideo ? 'Video Call' : 'Audio Call'),
          ],
        ),
        content: Text(
          'Start a ${isVideo ? 'video' : 'audio'} call with ${widget.userName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Starting ${isVideo ? 'video' : 'audio'} call with ${widget.userName}...',
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: kPrimary),
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? kDarkBackground : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: Colors.purple,
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: Colors.pink,
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file_rounded,
                  label: 'Document',
                  color: Colors.blue,
                ),
                _buildAttachmentOption(
                  icon: Icons.location_on_rounded,
                  label: 'Location',
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label selected'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

enum MessageType { text, voice, image, video }

class ChatMessage {
  final String text;
  final bool isSent;
  final DateTime timestamp;
  final MessageType messageType;
  final int? duration; // For voice messages

  ChatMessage({
    required this.text,
    required this.isSent,
    required this.timestamp,
    required this.messageType,
    this.duration,
  });
}
