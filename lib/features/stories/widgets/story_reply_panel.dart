import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';

/// Story Reply Panel - Instagram-style swipe-up reply interface
class StoryReplyPanel extends StatefulWidget {
  final String storyId;
  final String storyOwnerId;
  final String currentUserId;
  final Function(String message, String? emoji) onSendReply;
  final VoidCallback? onClose;

  const StoryReplyPanel({
    Key? key,
    required this.storyId,
    required this.storyOwnerId,
    required this.currentUserId,
    required this.onSendReply,
    this.onClose,
  }) : super(key: key);

  @override
  State<StoryReplyPanel> createState() => _StoryReplyPanelState();
}

class _StoryReplyPanelState extends State<StoryReplyPanel>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  String? _selectedEmoji;
  bool _isSending = false;
  bool _showSentConfirmation = false;

  // Quick reaction emojis (Instagram-style)
  final List<String> _quickReactions = ['❤️', '😂', '😍', '😢', '👏', '🔥'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();

    // Auto-focus text field
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSendReply() async {
    final message = _messageController.text.trim();

    if (message.isEmpty && _selectedEmoji == null) return;

    setState(() => _isSending = true);

    try {
      // Haptic feedback
      HapticFeedback.mediumImpact();

      // Send reply
      await widget.onSendReply(message, _selectedEmoji);

      // Show confirmation animation
      setState(() {
        _showSentConfirmation = true;
      });

      // Close after brief delay
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        _closePanel();
      }
    } catch (e) {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reply: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _handleQuickReaction(String emoji) async {
    // Haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _selectedEmoji = emoji;
      _isSending = true;
    });

    try {
      // Send emoji reaction
      await widget.onSendReply('', emoji);

      // Show floating emoji animation
      _showFloatingEmoji(emoji);

      // Close after animation
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        _closePanel();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reaction: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSending = false;
          _selectedEmoji = null;
        });
      }
    }
  }

  void _showFloatingEmoji(String emoji) {
    // Show emoji overlay with bounce animation
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => _FloatingEmojiOverlay(emoji: emoji),
    );
  }

  void _closePanel() {
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onClose?.call();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_showSentConfirmation) {
      return _buildSentConfirmation(isDark);
    }

    return GestureDetector(
      onTap: () {
        // Close panel when tapping outside
        _closePanel();
      },
      child: Container(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {}, // Prevent closing when tapping inside panel
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildReplyPanel(isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPanel(bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E).withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Draggable handle
              _buildHandle(isDark),

              // Quick reaction emojis
              _buildQuickReactions(isDark),

              // Text input field
              _buildTextField(isDark),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[700] : Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildQuickReactions(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _quickReactions.map((emoji) {
          final isSelected = _selectedEmoji == emoji;
          return GestureDetector(
            onTap: _isSending ? null : () => _handleQuickReaction(emoji),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 200),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: isSelected ? 1.2 : 1.0,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? kPrimary.withOpacity(0.2)
                          : isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? kPrimary
                            : isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Transform.scale(
                        scale: 0.5 + (value * 0.5),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextField(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Text field
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              enabled: !_isSending,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSendReply(),
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Reply to this story...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: _isSending ? null : _handleSendReply,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    _messageController.text.isNotEmpty || _selectedEmoji != null
                    ? kPrimary
                    : isDark
                    ? Colors.grey[800]
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentConfirmation(bool isDark) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E1E).withOpacity(0.95)
                      : Colors.white.withOpacity(0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: kPrimary,
                  size: 64,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Floating emoji overlay animation
class _FloatingEmojiOverlay extends StatefulWidget {
  final String emoji;

  const _FloatingEmojiOverlay({required this.emoji});

  @override
  State<_FloatingEmojiOverlay> createState() => _FloatingEmojiOverlayState();
}

class _FloatingEmojiOverlayState extends State<_FloatingEmojiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.5), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.2), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.8), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _slideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, 0.5), end: const Offset(0, -0.1)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, -0.1), end: const Offset(0, -0.3)),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Auto-close after animation
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Text(widget.emoji, style: const TextStyle(fontSize: 120)),
          ),
        ),
      ),
    );
  }
}
