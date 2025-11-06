import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/scaffold_with_nav_bar.dart';
import '../../../core/services/interaction_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/custom_video_player.dart';
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

  // Services
  final InteractionService _interactionService = InteractionService();
  final NotificationService _notificationService = NotificationService();
  bool _isLiking = false; // Prevent double-tap

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
    _loadLikeStatus();
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
                            backgroundImage: post.userAvatarUrl.isNotEmpty
                                ? NetworkImage(post.userAvatarUrl)
                                : null,
                            child: post.userAvatarUrl.isEmpty
                                ? Icon(
                                    Icons.person,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  )
                                : null,
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
                            // Show video player for video posts, image for others
                            if (post.isVideo &&
                                post.videoUrl != null &&
                                post.videoUrl!.isNotEmpty)
                              SizedBox(
                                width: double.infinity,
                                height: 280,
                                child: CompactVideoPlayer(
                                  videoUrl: post.videoUrl!,
                                  thumbnailUrl:
                                      post.thumbnailUrl ?? post.imageUrl,
                                ),
                              )
                            else
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
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image_outlined,
                                        size: 64,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Could not load image',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
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

  // Load initial like status from backend
  Future<void> _loadLikeStatus() async {
    final isLiked = await _interactionService.isPostLiked(post.id);
    if (mounted) {
      setState(() {
        _isLiked = isLiked;
      });
    }
  }

  // Toggle like with backend integration
  Future<void> _toggleLike() async {
    if (_isLiking) return; // Prevent double-tap
    _isLiking = true;

    // Optimistic UI update
    final wasLiked = _isLiked;
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likeCount += 1;
      } else if (_likeCount > 0) {
        _likeCount -= 1;
      }
      _compressLikeCount = false;
    });

    try {
      // Call backend
      final nowLiked = await _interactionService.toggleLike(post.id);

      // Send notification if now liked (and not our own post)
      if (nowLiked) {
        final currentUserId = _notificationService.getCurrentUserId();
        if (currentUserId != null && currentUserId != post.userId) {
          await _notificationService.sendLikeNotification(
            fromUserId: currentUserId,
            toUserId: post.userId,
            postId: post.id,
          );
        }
      }

      // Update UI with backend response
      if (mounted) {
        setState(() {
          _isLiked = nowLiked;
        });
      }
    } catch (e) {
      // Revert on error
      print('❌ Error toggling like: $e');
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
          if (wasLiked) {
            _likeCount += 1;
          } else if (_likeCount > 0) {
            _likeCount -= 1;
          }
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to update like')));
      }
    } finally {
      _isLiking = false;
    }
  }

  void _toggleLikeWithHearts() {
    // Store the old like state before toggling
    final wasLiked = _isLiked;
    _toggleLike();
    // Show hearts from center of image when liking via button
    if (!wasLiked && !_isLiked) {
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
        barrierColor: Colors.black54,
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
                  // REMOVED: No more nested replies
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
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => _ShareSheet(
        imageUrl: post.imageUrl,
        userName: post.userName,
        onDismissed: () => navVisibility?.value = true,
      ),
    ).whenComplete(() => navVisibility?.value = true);
  }

  void _openPostViewer(BuildContext context) {
    final navVisibility = NavBarVisibilityScope.maybeOf(context);
    navVisibility?.value = false;

    // Convert home Post model to profile PostModel
    // Generate consistent userId from userHandle
    final userId = 'user_${post.userHandle.replaceAll('@', '')}';

    final profilePost = profile_post.PostModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
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
      location: null,
    );

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => PostViewerInstagramStyle(
              initialPost: profilePost,
              allPosts: [profilePost],
            ),
          ),
        )
        .whenComplete(() => navVisibility?.value = true);
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
      barrierColor: Colors.black54,
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
  });

  final String text;
  final DateTime timestamp;
  int likes;
  bool isLiked;
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

  List<_Comment> get comments => widget.comments;

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
                      ),
                    ),
            ),
            const Divider(height: 1),
            // Input field
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSubmit(context),
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
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
                      onPressed: () => _handleSubmit(context),
                      icon: const Icon(Icons.send_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
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
  const _CommentTile({required this.comment, required this.onLike});

  final _Comment comment;
  final VoidCallback onLike;

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
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
