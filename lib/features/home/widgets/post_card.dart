import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/scaffold_with_nav_bar.dart';
import '../../../core/theme.dart';
import '../models/post_model.dart';
import '../../profile/models/post_model.dart' as profile_post;
import '../../profile/pages/post_viewer_instagram_style.dart';
import '../../profile/other_user_profile_page.dart';
import 'floating_hearts_from_position.dart';

class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.post});

  final Post post;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  late bool _isBookmarked;
  late int _likeCount;
  late int _commentCount;
  late bool _compressLikeCount;
  late bool _compressCommentCount;
  late final NumberFormat _decimalFormat;
  final List<_Comment> _comments = [];
  final GlobalKey<FloatingHeartsFromPositionState> _heartsKey = GlobalKey();

  Post get post => widget.post;

  @override
  void initState() {
    super.initState();
    _isLiked = false;
    _isBookmarked = false;
    _likeCount = _parseCount(post.likes);
    _commentCount = _parseCount(post.comments);
    _compressLikeCount = _isAbbreviated(post.likes);
    _compressCommentCount = _isAbbreviated(post.comments);
    _decimalFormat = NumberFormat.decimalPattern();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _openUserProfile(context),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                kPrimary.withOpacity(0.8),
                                kPrimary.withOpacity(0.4),
                              ],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(post.userAvatarUrl),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openUserProfile(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                post.userHandle,
                                style: TextStyle(
                                  color: isDark ? Colors.white60 : Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: GestureDetector(
                              onTap: () => _openPostOptions(context),
                              child: Icon(
                                Icons.more_horiz,
                                color: isDark ? Colors.white70 : Colors.black54,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _openPostViewer(context),
                  onDoubleTapDown: (details) {
                    // Store the old like state
                    final wasLiked = _isLiked;
                    // Toggle like on double tap
                    _toggleLike();
                    // Show hearts from tap position only if we're now liked (changed from unliked to liked)
                    // This ensures hearts show immediately when liking
                    if (!wasLiked && _isLiked) {
                      _heartsKey.currentState?.addHeartsFromPosition(
                        details.localPosition,
                      );
                    }
                  },
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                        child: Stack(
                          children: [
                            Image.network(
                              post.imageUrl,
                              width: double.infinity,
                              height: 280,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: double.infinity,
                                height: 280,
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.image_not_supported_rounded,
                                  size: 48,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.3),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Hearts overlay
                      Positioned.fill(
                        child: FloatingHeartsFromPosition(key: _heartsKey),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _GlassActionButton(
                        icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                        label: _formatCount(
                          _likeCount,
                          compress: _compressLikeCount,
                        ),
                        isDark: isDark,
                        isActive: _isLiked,
                        accentColor: Colors.red.shade400,
                        onPressed: _toggleLikeWithHearts,
                      ),
                      const SizedBox(width: 16),
                      _GlassActionButton(
                        icon: Icons.chat_bubble_outline,
                        label: _formatCount(
                          _commentCount,
                          compress: _compressCommentCount,
                        ),
                        isDark: isDark,
                        isActive: false,
                        onPressed: () => _openComments(context),
                      ),
                      const SizedBox(width: 16),
                      _GlassActionButton(
                        icon: Icons.send_outlined,
                        label: post.shares,
                        isDark: isDark,
                        isActive: false,
                        onPressed: () => _openShareSheet(context),
                      ),
                      const Spacer(),
                      _GlassActionButton(
                        icon: _isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        label: '',
                        isDark: isDark,
                        isActive: _isBookmarked,
                        showCount: false,
                        onPressed: _toggleBookmark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likeCount += 1;
      } else if (_likeCount > 0) {
        _likeCount -= 1;
      }
      _compressLikeCount = false;
    });
  }

  void _toggleLikeWithHearts() {
    // Store the old like state before toggling
    final wasLiked = _isLiked;
    _toggleLike();
    // Show hearts from center of image when liking via button
    if (!wasLiked && _isLiked) {
      // Trigger hearts from center of the image (140px from left, 140px from top of image)
      _heartsKey.currentState?.addHeartsFromPosition(const Offset(140, 140));
    }
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _isBookmarked ? 'Saved to bookmarks' : 'Removed from bookmarks',
        ),
      ),
    );
  }

  Future<void> _openComments(BuildContext context) async {
    final navVisibility = NavBarVisibilityScope.maybeOf(context);
    navVisibility?.value = false;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => _CommentsSheet(
          comments: _comments,
          onSubmit: (value) {
            setState(() {
              _comments.insert(
                0,
                _Comment(
                  text: value.trim(),
                  timestamp: DateTime.now(),
                  likes: 0,
                  isLiked: false,
                  replies: _comments.isEmpty
                      ? [
                          _Comment(
                            text: 'Great comment!',
                            timestamp: DateTime.now().subtract(
                              const Duration(minutes: 5),
                            ),
                          ),
                          _Comment(
                            text: 'I agree with this',
                            timestamp: DateTime.now().subtract(
                              const Duration(minutes: 10),
                            ),
                          ),
                        ]
                      : null,
                ),
              );
              _commentCount += 1;
              _compressCommentCount = false;
            });
          },
        ),
      );
    } finally {
      navVisibility?.value = true;
    }
  }

  void _openShareSheet(BuildContext context) {
    final navVisibility = NavBarVisibilityScope.maybeOf(context);
    navVisibility?.value = false;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor:
          Theme.of(context).bottomSheetTheme.backgroundColor ??
          Theme.of(context).colorScheme.surface,
      builder: (context) => _ShareSheet(
        imageUrl: post.imageUrl,
        userName: post.userName,
        onDismissed: () => navVisibility?.value = true,
      ),
    ).whenComplete(() => navVisibility?.value = true);
  }

  void _openPostViewer(BuildContext context) {
    // Convert home Post model to profile PostModel
    final profilePost = profile_post.PostModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: profile_post.PostType.image,
      mediaUrls: [post.imageUrl],
      thumbnailUrl: post.imageUrl,
      username: post.userName,
      userAvatar: post.userAvatarUrl,
      timestamp: DateTime.now(),
      caption: '',
      likes: _likeCount,
      comments: _commentCount,
      shares: _parseCount(post.shares),
      views: _likeCount * 10, // Estimate
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PostViewerInstagramStyle(
          initialPost: profilePost,
          allPosts: [profilePost],
        ),
      ),
    );
  }

  void _openUserProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OtherUserProfilePage(
          userId: post.userHandle,
          username: post.userName,
          avatarUrl: post.userAvatarUrl,
        ),
      ),
    );
  }

  void _openPostOptions(BuildContext context) {
    final navVisibility = NavBarVisibilityScope.maybeOf(context);
    navVisibility?.value = false;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor:
          Theme.of(context).bottomSheetTheme.backgroundColor ??
          Theme.of(context).colorScheme.surface,
      builder: (context) =>
          _PostOptionsSheet(onDismissed: () => navVisibility?.value = true),
    ).whenComplete(() => navVisibility?.value = true);
  }

  int _parseCount(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return 0;
    if (trimmed.endsWith('k')) {
      final number = double.tryParse(trimmed.replaceAll('k', '')) ?? 0;
      return (number * 1000).round();
    }
    if (trimmed.endsWith('m')) {
      final number = double.tryParse(trimmed.replaceAll('m', '')) ?? 0;
      return (number * 1000000).round();
    }
    return int.tryParse(trimmed.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  bool _isAbbreviated(String value) {
    final lower = value.trim().toLowerCase();
    return lower.endsWith('k') || lower.endsWith('m');
  }

  String _formatCount(int value, {required bool compress}) {
    if (!compress || value < 1000) {
      return _decimalFormat.format(value);
    }

    if (value >= 1000000) {
      final fixed = value % 1000000 == 0 ? 0 : 1;
      return '${(value / 1000000).toStringAsFixed(fixed)}M';
    }
    if (value >= 1000) {
      final fixed = value % 1000 == 0 ? 0 : 1;
      return '${(value / 1000).toStringAsFixed(fixed)}K';
    }
    return value.toString();
  }
}

class _GlassActionButton extends StatelessWidget {
  const _GlassActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.isActive,
    required this.onPressed,
    this.showCount = true,
    this.accentColor,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final bool isActive;
  final VoidCallback onPressed;
  final bool showCount;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final baseColor = (isDark ? Colors.white : Colors.black).withOpacity(0.05);
    final borderColor = (isDark ? Colors.white : Colors.black).withOpacity(
      0.08,
    );
    final iconColor = isActive
        ? (accentColor ?? Theme.of(context).colorScheme.primary)
        : (accentColor ?? (isDark ? Colors.white70 : Colors.black87));

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: baseColor,
          child: InkWell(
            onTap: onPressed,
            splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  if (showCount && label.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Comment {
  _Comment({
    required this.text,
    required this.timestamp,
    this.likes = 0,
    this.isLiked = false,
    List<_Comment>? replies,
  }) : replies = replies ?? [];

  final String text;
  final DateTime timestamp;
  int likes;
  bool isLiked;
  final List<_Comment> replies;
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.comments, required this.onSubmit});

  final List<_Comment> comments;
  final ValueChanged<String> onSubmit;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  late final TextEditingController _controller;
  late final TextEditingController _replyController;
  final Map<int, bool> _expandedReplies = {};
  int? _replyingToIndex;
  String? _replyingToUsername;

  List<_Comment> get comments => widget.comments;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _replyController = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _startReply(int index) {
    setState(() {
      _replyingToIndex = index;
      _replyingToUsername = 'User'; // In real app, get from comment data
      _expandedReplies[index] = true; // Auto-expand to see where reply will go
    });
    // Focus on reply input
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _cancelReply() {
    setState(() {
      _replyingToIndex = null;
      _replyingToUsername = null;
      _replyController.clear();
    });
  }

  void _submitReply() {
    if (_replyController.text.trim().isEmpty || _replyingToIndex == null) {
      return;
    }

    setState(() {
      comments[_replyingToIndex!].replies.add(
        _Comment(text: _replyController.text.trim(), timestamp: DateTime.now()),
      );
      _replyController.clear();
      _replyingToIndex = null;
      _replyingToUsername = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      duration: const Duration(milliseconds: 100),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color:
              theme.bottomSheetTheme.backgroundColor ??
              (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              height: 4,
              width: 48,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Comments',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            // Comments list
            Flexible(
              child: comments.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'Be the first to leave a comment!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: comments.length,
                      itemBuilder: (context, index) => _CommentTile(
                        comment: comments[index],
                        onLike: () {
                          setState(() {
                            comments[index].isLiked = !comments[index].isLiked;
                            comments[index].likes += comments[index].isLiked
                                ? 1
                                : -1;
                          });
                        },
                        onToggleReplies: () {
                          setState(() {
                            _expandedReplies[index] =
                                !(_expandedReplies[index] ?? false);
                          });
                        },
                        isExpanded: _expandedReplies[index] ?? false,
                        onReply: () => _startReply(index),
                      ),
                    ),
            ),
            const Divider(height: 1),
            // Input field
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Show replying-to banner if replying
                    if (_replyingToIndex != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Replying to $_replyingToUsername',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey
                                      : Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _cancelReply,
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: isDark
                                    ? Colors.grey
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyingToIndex != null
                                ? _replyController
                                : _controller,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) {
                              if (_replyingToIndex != null) {
                                _submitReply();
                              } else {
                                _handleSubmit(context);
                              }
                            },
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: _replyingToIndex != null
                                  ? 'Write a reply...'
                                  : 'Write a comment...',
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: () {
                            if (_replyingToIndex != null) {
                              _submitReply();
                            } else {
                              _handleSubmit(context);
                            }
                          },
                          icon: const Icon(Icons.send_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    setState(() {});
    _controller.clear();
    FocusScope.of(context).unfocus();
  }
}

class _ShareSheet extends StatelessWidget {
  const _ShareSheet({
    required this.imageUrl,
    required this.userName,
    this.onDismissed,
  });

  final String imageUrl;
  final String userName;
  final VoidCallback? onDismissed;

  @override
  Widget build(BuildContext context) {
    final options = <_SheetOption>[
      const _SheetOption('Share to feed', Icons.dynamic_feed_rounded),
      const _SheetOption('Share to messages', Icons.chat_rounded),
      const _SheetOption('Copy link', Icons.link_rounded),
      const _SheetOption('Share externally', Icons.ios_share_rounded),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 48,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Share $userName's post",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...options.map(
              (option) => ListTile(
                leading: Icon(option.icon, color: option.color),
                title: Text(option.label),
                onTap: () {
                  Navigator.of(context).pop();
                  onDismissed?.call();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${option.label} coming soon.')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostOptionsSheet extends StatelessWidget {
  const _PostOptionsSheet({this.onDismissed});

  final VoidCallback? onDismissed;

  @override
  Widget build(BuildContext context) {
    final options = <_SheetOption>[
      const _SheetOption('Report post', Icons.flag_rounded, Colors.redAccent),
      const _SheetOption('Mute @user', Icons.volume_off_rounded),
      const _SheetOption('Unfollow', Icons.person_off_rounded),
      const _SheetOption(
        'Why am I seeing this post?',
        Icons.help_outline_rounded,
      ),
    ];

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final backgroundColor =
        theme.bottomSheetTheme.backgroundColor ??
        (isDark ? const Color(0xFF11141D) : Colors.white);

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 48,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Post options',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...options.map(
                (option) => ListTile(
                  leading: Icon(
                    option.icon,
                    color: option.color ?? secondaryTextColor,
                  ),
                  title: Text(
                    option.label,
                    style: TextStyle(color: option.color ?? defaultTextColor),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    onDismissed?.call();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${option.label} coming soon.')),
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
}

class _SheetOption {
  const _SheetOption(this.label, this.icon, [this.color]);

  final String label;
  final IconData icon;
  final Color? color;
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onLike,
    required this.onToggleReplies,
    required this.isExpanded,
    required this.onReply,
  });

  final _Comment comment;
  final VoidCallback onLike;
  final VoidCallback onToggleReplies;
  final VoidCallback onReply;
  final bool isExpanded;

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary,
                child: const Icon(Icons.person, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'You',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getTimeAgo(comment.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(comment.text, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        InkWell(
                          onTap: onLike,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  comment.isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 16,
                                  color: comment.isLiked
                                      ? Colors.red
                                      : (isDark
                                            ? Colors.grey
                                            : Colors.grey.shade600),
                                ),
                                if (comment.likes > 0) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '${comment.likes}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: comment.isLiked
                                          ? Colors.red
                                          : (isDark
                                                ? Colors.grey
                                                : Colors.grey.shade600),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: onReply,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Text(
                              'Reply',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.grey
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: InkWell(
                onTap: onToggleReplies,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isExpanded
                            ? 'Hide replies'
                            : 'Show ${comment.replies.length} ${comment.replies.length == 1 ? 'reply' : 'replies'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isExpanded) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 42),
                child: Column(
                  children: comment.replies
                      .map(
                        (reply) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: theme.colorScheme.primary
                                    .withOpacity(0.7),
                                child: const Icon(
                                  Icons.person,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'User',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _getTimeAgo(reply.timestamp),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.grey
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      reply.text,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
