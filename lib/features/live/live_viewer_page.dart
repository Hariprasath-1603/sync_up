import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'go_live_page.dart';

class LiveViewerPage extends StatefulWidget {
  const LiveViewerPage({
    super.key,
    this.hostName = 'Harper Ray',
    this.hostAvatarUrl =
        'https://images.unsplash.com/photo-1614289371518-722f2615943c?auto=format&fit=crop&w=200&q=80',
    this.streamTitle = 'Weekly AMA + Behind the Scenes',
    this.coverImageUrl =
        'https://images.unsplash.com/photo-1525182008055-f88b95ff7980?auto=format&fit=crop&w=900&q=80',
    this.initialViewerCount = 3200,
  });

  final String hostName;
  final String hostAvatarUrl;
  final String streamTitle;
  final String coverImageUrl;
  final int initialViewerCount;

  @override
  State<LiveViewerPage> createState() => _LiveViewerPageState();
}

class _LiveViewerPageState extends State<LiveViewerPage> {
  final _commentController = LiveCommentFeedController();
  final _reactionController = FloatingReactionController();
  final _textController = TextEditingController();
  final List<LiveComment> _commentHistory = [];

  final _mockUsernames = <String>[
    'Priya',
    'Noah',
    'Lena',
    'Diego',
    'Haru',
    'Maya',
    'Ezra',
    'Nova',
  ];

  final _mockMessages = <String>[
    'This looks incredible! 🔥',
    'Loving the energy.',
    'Greetings from Toronto!',
    'Can you save this live?',
    'Drop the playlist please 🎶',
    'Best session yet!',
    'Camera quality is insane!',
  ];

  Timer? _mockCommentTimer;
  Timer? _mockReactionTimer;
  Timer? _viewerCountTimer;
  late int _viewerCount;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _viewerCount = widget.initialViewerCount;
    _seedInitialComments();
    _startMockActivity();
  }

  @override
  void dispose() {
    _mockCommentTimer?.cancel();
    _mockReactionTimer?.cancel();
    _viewerCountTimer?.cancel();
    _commentController.dispose();
    _reactionController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _seedInitialComments() {
    const seed = [
      LiveComment(username: 'Priya', message: 'Notification squad! 🙌'),
      LiveComment(username: 'Noah', message: 'Been waiting for this.'),
      LiveComment(username: 'Lena', message: 'Camera quality is unreal!'),
    ];
    for (final comment in seed) {
      _pushComment(comment);
    }
  }

  void _startMockActivity() {
    final random = Random();
    _mockCommentTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final username = _mockUsernames[random.nextInt(_mockUsernames.length)];
      final message = _mockMessages[random.nextInt(_mockMessages.length)];
      _pushComment(LiveComment(username: username, message: message));
    });

    _mockReactionTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      const emojis = ['❤️', '💜', '💛', '🔥'];
      _reactionController.addReaction(emojis[random.nextInt(emojis.length)]);
    });

    _viewerCountTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      final delta = random.nextInt(120) - 50;
      setState(() {
        _viewerCount = max(0, _viewerCount + delta);
      });
    });
  }

  void _pushComment(LiveComment comment) {
    _commentHistory.insert(0, comment);
    if (_commentHistory.length > 200) {
      _commentHistory.removeLast();
    }
    _commentController.addComment(comment);
  }

  void _submitComment(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _pushComment(LiveComment(username: 'You', message: trimmed));
    _textController.clear();
    _reactionController.addReaction('❤️');
  }

  void _sendHeart() {
    const palette = ['❤️', '💗', '💜', '💛', '🔥'];
    _reactionController.addReaction(palette[Random().nextInt(palette.length)]);
  }

  void _toggleFollow() {
    setState(() => _isFollowing = !_isFollowing);
    _showSnack(
      _isFollowing
          ? 'You will be notified about new lives from ${widget.hostName}.'
          : 'Live notifications muted for now.',
    );
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
    final gifts = GiftDisplay.samples();
    final selected = await showModalBottomSheet<GiftDisplay>(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.85),
      barrierColor: Colors.black54,
      builder: (context) => GiftMenuSheet(gifts: gifts),
    );
    if (selected != null && mounted) {
      _showSnack('Sent ${selected.label}!');
      _reactionController.addReaction(selected.emoji);
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

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _formattedViewerCount {
    if (_viewerCount >= 1000000) {
      return '${(_viewerCount / 1000000).toStringAsFixed(1)}M';
    }
    if (_viewerCount >= 1000) {
      return '${(_viewerCount / 1000).toStringAsFixed(1)}K';
    }
    return '$_viewerCount';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 170),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildHeader(context),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildLiveStage(context),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildStreamDetails(context),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildEngagementRow(context),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ViewerInputBar(
                controller: _textController,
                onSubmitted: _submitComment,
                onSendHeart: _sendHeart,
                onOpenGifts: _openGiftMenu,
                onOpenComments: _openCommentSheet,
                onShare: _openShareSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.white;
    return Row(
      children: [
        _HeaderIconButton(
          icon: Icons.close,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        CircleAvatar(backgroundImage: NetworkImage(widget.hostAvatarUrl)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.hostName,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\u2022 $_formattedViewerCount watching',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _FollowBadge(isFollowing: _isFollowing, onToggle: _toggleFollow),
        const SizedBox(width: 12),
        _HeaderIconButton(
          icon: Icons.chat_bubble_outline,
          onTap: _openCommentSheet,
        ),
      ],
    );
  }

  Widget _buildLiveStage(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onDoubleTap: _sendHeart,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: (rect) => const LinearGradient(
                      colors: [Color(0xFF42275A), Color(0xFF734B6D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(rect),
                    child: Image.network(
                      widget.coverImageUrl,
                      fit: BoxFit.cover,
                      color: Colors.white.withOpacity(0.8),
                      colorBlendMode: BlendMode.softLight,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xAA000000)],
                      ),
                    ),
                  ),
                ),
                Positioned(top: 20, left: 20, child: _LiveBadge(theme: theme)),
                Positioned(
                  top: 20,
                  right: 20,
                  child: _ViewerCountBadge(
                    text: '$_formattedViewerCount watching',
                  ),
                ),
                Positioned(
                  top: 76,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.streamTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Hosted by ${widget.hostName}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.78),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 110,
                  child: SizedBox(
                    width: min(MediaQuery.of(context).size.width * 0.55, 220),
                    child: LiveCommentFeed(
                      controller: _commentController,
                      displayDuration: const Duration(seconds: 6),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 80,
                  child: SizedBox(
                    width: 120,
                    height: 220,
                    child: FloatingReactionsLayer(
                      controller: _reactionController,
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 40,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.waves, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Double tap to send hearts',
                          style: TextStyle(color: Colors.white, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreamDetails(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark ? Colors.white70 : Colors.white70;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live chat highlights',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        ..._commentHistory
            .take(3)
            .map(
              (comment) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: kPrimary.withOpacity(0.2),
                      child: Text(
                        comment.username.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: kPrimary, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment.message,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildEngagementRow(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _EngagementChip(
          icon: Icons.favorite_rounded,
          label: 'Send heart',
          onTap: _sendHeart,
        ),
        _EngagementChip(
          icon: Icons.card_giftcard_rounded,
          label: 'Send gift',
          onTap: _openGiftMenu,
        ),
        _EngagementChip(
          icon: Icons.share_rounded,
          label: 'Share',
          onTap: _openShareSheet,
        ),
        _EngagementChip(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Open chat',
          onTap: _openCommentSheet,
        ),
      ],
    );
  }
}

class _ViewerInputBar extends StatelessWidget {
  const _ViewerInputBar({
    required this.controller,
    required this.onSubmitted,
    required this.onSendHeart,
    required this.onOpenGifts,
    required this.onOpenComments,
    required this.onShare,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSendHeart;
  final VoidCallback onOpenGifts;
  final VoidCallback onOpenComments;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, padding + 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0xCC000000)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: TextField(
                        controller: controller,
                        style: const TextStyle(color: Colors.white),
                        onSubmitted: onSubmitted,
                        decoration: InputDecoration(
                          hintText: 'Say something nice…',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                          ),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => onSubmitted(controller.text),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _RoundIconButton(
                icon: Icons.favorite_rounded,
                onTap: onSendHeart,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF512F), Color(0xFFF09819)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _ViewerActionButton(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Gifts',
                  onTap: onOpenGifts,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ViewerActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chat',
                  onTap: onOpenComments,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ViewerActionButton(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  onTap: onShare,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.gradient,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? Colors.white.withOpacity(0.12) : null,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: gradient == null
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x55FF512F),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _ViewerActionButton extends StatelessWidget {
  const _ViewerActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _FollowBadge extends StatelessWidget {
  const _FollowBadge({required this.isFollowing, required this.onToggle});

  final bool isFollowing;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isFollowing
              ? const LinearGradient(
                  colors: [Color(0xFF00B09B), Color(0xFF96C93D)],
                )
              : const LinearGradient(
                  colors: [Color(0xFFFF512F), Color(0xFFF09819)],
                ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFollowing ? Icons.notifications_active : Icons.add,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              isFollowing ? 'Following' : 'Follow',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x55FF416C), blurRadius: 18, spreadRadius: 2),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.flash_on, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerCountBadge extends StatelessWidget {
  const _ViewerCountBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EngagementChip extends StatelessWidget {
  const _EngagementChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
