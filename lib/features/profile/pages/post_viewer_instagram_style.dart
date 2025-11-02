import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/scaffold_with_nav_bar.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/post_service.dart';
import '../models/post_model.dart';
import 'widgets/floating_reactions.dart';

/// Instagram-style post viewer with adaptive theme and advanced interactions
class PostViewerInstagramStyle extends StatefulWidget {
  const PostViewerInstagramStyle({
    super.key,
    required this.initialPost,
    required this.allPosts,
    this.onPostChanged,
  });

  final PostModel initialPost;
  final List<PostModel> allPosts;
  final ValueChanged<PostModel>? onPostChanged;

  @override
  State<PostViewerInstagramStyle> createState() =>
      _PostViewerInstagramStyleState();
}

class _PostViewerInstagramStyleState extends State<PostViewerInstagramStyle>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late PostModel _currentPost;
  late AnimationController _likeAnimationController;
  late AnimationController _exitAnimationController;
  late TransformationController _transformationController;
  final GlobalKey<FloatingReactionsState> _reactionsKey = GlobalKey();

  // Services
  final PostService _postService = PostService();

  int _currentMediaIndex = 0;
  int _currentPostIndex = 0;
  bool _isZoomed = false;
  bool _isCaptionExpanded = false;
  TapDownDetails? _doubleTapDetails;

  // Nav bar visibility control
  ValueNotifier<bool>? _navBarVisibility;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.initialPost;
    final initialIndex = widget.allPosts.indexWhere(
      (p) => p.id == widget.initialPost.id,
    );
    _currentPostIndex = initialIndex >= 0 ? initialIndex : 0;
    _pageController = PageController(initialPage: _currentPostIndex);

    _likeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _exitAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _transformationController = TransformationController();

    // Hide nav bar on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navBarVisibility?.value = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get nav bar visibility notifier
    _navBarVisibility = NavBarVisibilityScope.maybeOf(context);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _likeAnimationController.dispose();
    _exitAnimationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (index >= 0 && index < widget.allPosts.length) {
      setState(() {
        _currentPost = widget.allPosts[index];
        _currentPostIndex = index;
        _currentMediaIndex = 0;
        _isZoomed = false;
        _isCaptionExpanded = false; // Reset caption state on post change
        _transformationController.value = Matrix4.identity();
      });
      widget.onPostChanged?.call(_currentPost);

      // Haptic feedback on post transition
      HapticFeedback.selectionClick();
    }
  }

  void _toggleLike() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to like posts')),
      );
      return;
    }

    final wasLiked = _currentPost.isLiked;

    // Optimistic update
    setState(() {
      _currentPost.isLiked = !_currentPost.isLiked;
      _currentPost.likes += _currentPost.isLiked ? 1 : -1;
    });
    HapticFeedback.mediumImpact();

    // Call backend
    final success = wasLiked
        ? await _postService.unlikePost(_currentPost.id)
        : await _postService.likePost(_currentPost.id);

    // Revert on failure
    if (!success) {
      setState(() {
        _currentPost.isLiked = wasLiked;
        _currentPost.likes += wasLiked ? 1 : -1;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to update like')));
      }
    }
  }

  void _handleDoubleTap() {
    // Store tap position for zoom
    if (_doubleTapDetails != null && _currentPost.type == PostType.image) {
      final position = _doubleTapDetails!.localPosition;

      if (_isZoomed) {
        // Zoom out
        _transformationController.value = Matrix4.identity();
        setState(() => _isZoomed = false);
      } else {
        // Zoom in to tap position
        final double scale = 2.5;
        final double translationX = -position.dx * (scale - 1);
        final double translationY = -position.dy * (scale - 1);

        _transformationController.value = Matrix4.identity()
          ..translate(translationX, translationY)
          ..scale(scale);
        setState(() => _isZoomed = true);
      }
    } else {
      // Like/Unlike toggle with animation
      _toggleLike();

      // Show heart animation only when liking
      if (_currentPost.isLiked) {
        _reactionsKey.currentState?.addReaction('❤️');
      }
    }
  }

  void _toggleSave() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save posts')),
      );
      return;
    }

    final wasSaved = _currentPost.isSaved;

    // Optimistic update
    setState(() {
      _currentPost.isSaved = !_currentPost.isSaved;
      _currentPost.saves += _currentPost.isSaved ? 1 : -1;
    });
    HapticFeedback.lightImpact();

    // Call backend
    final success = wasSaved
        ? await _postService.unsavePost(_currentPost.id)
        : await _postService.savePost(_currentPost.id);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _currentPost.isSaved
                  ? 'Saved to collection'
                  : 'Removed from saved',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Revert on failure
      setState(() {
        _currentPost.isSaved = wasSaved;
        _currentPost.saves += wasSaved ? 1 : -1;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update save status')),
        );
      }
    }
  }

  void _openComments() {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCommentsSheet(),
    );
  }

  void _openShare() {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildShareSheet(),
    );
  }

  void _showOptionsMenu() {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOptionsSheet(),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? kDarkBackground : kLightBackground;
    final surfaceColor = isDark ? const Color(0xFF1A1D24) : Colors.white;

    return WillPopScope(
      onWillPop: () async {
        await _handleExit();
        return true;
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        extendBodyBehindAppBar: true,
        body: GestureDetector(
          // Swipe down to dismiss
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta! > 10 && _currentPostIndex == 0) {
              // Only dismiss on first post when swiping down
              _handleSwipeDownDismiss(details.primaryDelta!);
            }
          },
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity! > 500) {
              _handleExit();
            }
          },
          child: Stack(
            children: [
              // Adaptive background with blur transitions
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            kDarkBackground,
                            const Color(0xFF0B0E13),
                            kDarkBackground,
                          ]
                        : [kLightBackground, Colors.white, kLightBackground],
                  ),
                ),
              ),

              // Content with fade animation
              FadeTransition(
                opacity: _exitAnimationController.drive(
                  Tween<double>(begin: 1.0, end: 0.0),
                ),
                child: SlideTransition(
                  position: _exitAnimationController.drive(
                    Tween<Offset>(
                      begin: Offset.zero,
                      end: const Offset(0, 0.3),
                    ).chain(CurveTween(curve: Curves.easeInOut)),
                  ),
                  child: Column(
                    children: [
                      // Top App Bar with Glassmorphism
                      _buildGlassTopBar(isDark),

                      // Page indicator
                      _buildPageIndicator(isDark),

                      // Scrollable Content
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          onPageChanged: _onPageChanged,
                          itemCount: widget.allPosts.length,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final post = widget.allPosts[index];
                            return _buildPostCard(post, isDark, surfaceColor);
                          },
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

  Future<void> _handleExit() async {
    // Animate exit
    await _exitAnimationController.forward();

    // Show nav bar with spring animation
    _navBarVisibility?.value = true;

    // Pop with result
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleSwipeDownDismiss(double delta) {
    // Calculate progress based on swipe distance
    final progress = (delta / 300).clamp(0.0, 1.0);
    _exitAnimationController.value = progress;
  }

  Widget _buildPageIndicator(bool isDark) {
    if (widget.allPosts.length <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.08),
                      ]
                    : [
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.08),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Text(
              '${_currentPostIndex + 1} / ${widget.allPosts.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTopBar(bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Back button with glass effect
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: GestureDetector(
                  onTap: _handleExit,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                              ]
                            : [
                                Colors.black.withOpacity(0.15),
                                Colors.black.withOpacity(0.08),
                              ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.3)
                            : Colors.black.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : Colors.black87,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Options menu button
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: GestureDetector(
                  onTap: _showOptionsMenu,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                              ]
                            : [
                                Colors.black.withOpacity(0.15),
                                Colors.black.withOpacity(0.08),
                              ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.3)
                            : Colors.black.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.more_vert_rounded,
                      color: isDark ? Colors.white : Colors.black87,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(PostModel post, bool isDark, Color surfaceColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get available height for the card
        final screenHeight = MediaQuery.of(context).size.height;
        final availableHeight =
            screenHeight - 100; // Account for top bar and padding

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                constraints: BoxConstraints(maxHeight: availableHeight),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.white.withOpacity(0.12),
                            Colors.white.withOpacity(0.06),
                          ]
                        : [
                            Colors.black.withOpacity(0.05),
                            Colors.black.withOpacity(0.02),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.black.withOpacity(0.1),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Post Header
                    _buildGlassPostHeader(post, isDark),

                    // Post Image/Video with Double-Tap and Zoom
                    _buildPostImage(post, isDark),

                    // Action Buttons and Description in Row
                    _buildActionRow(post, isDark),

                    // View Comments
                    if (post.comments > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                        child: GestureDetector(
                          onTap: _openComments,
                          child: Text(
                            'View all ${_formatCount(post.comments)} comments',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.black54,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                    // Timestamp
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Text(
                        '${_formatTimestamp(post.timestamp)} ago',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black45,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Bottom Interaction Bar (Comment, Save, Share)
                    _buildBottomBar(post, isDark),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionRow(PostModel post, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Like Button with haptic feedback
          GestureDetector(
            onTap: () {
              _toggleLike();
              HapticFeedback.mediumImpact(); // Haptic on like/unlike
            },
            child: Row(
              children: [
                Icon(
                  post.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  color: post.isLiked
                      ? Colors.red
                      : (isDark ? Colors.white : Colors.black87),
                  size: 28,
                ),
                const SizedBox(width: 12),
                if (!post.hideLikeCount)
                  Text(
                    '${_formatCount(post.likes)} likes',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
              ],
            ),
          ),

          // Liked by section
          if (post.likes > 0 && !post.hideLikeCount) ...[
            const SizedBox(height: 12),
            _buildLikedBySection(post, isDark),
          ],

          // Description Section (Below Like Button) - only show if caption exists
          if (post.caption.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildExpandableCaption(post, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildLikedBySection(PostModel post, bool isDark) {
    // TODO: Fetch actual liked users from database
    final String likedByName = post.username.isNotEmpty
        ? post.username
        : 'user_${post.userId.substring(0, 6)}';
    final int otherLikes = post.likes > 1 ? post.likes - 1 : 0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // TODO: Show list of users who liked
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Show liked by users')));
      },
      child: Row(
        children: [
          // Generic likes icon instead of avatars
          Icon(
            Icons.favorite,
            size: 20,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? Colors.white.withOpacity(0.9)
                      : Colors.black87,
                ),
                children: [
                  const TextSpan(text: 'Liked by '),
                  TextSpan(
                    text: likedByName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (otherLikes > 0)
                    TextSpan(
                      text:
                          ' and $otherLikes ${otherLikes == 1 ? 'other' : 'others'}',
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableCaption(PostModel post, bool isDark) {
    // Calculate if text needs "Show more" button
    final textSpan = TextSpan(
      text: '${post.username} ${post.caption}',
      style: TextStyle(
        fontSize: 14,
        height: 1.4,
        color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      maxLines: 3,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(
      maxWidth: MediaQuery.of(context).size.width - 80,
    ); // Account for padding
    final bool shouldShowMore =
        textPainter.didExceedMaxLines || post.caption.length > 150;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: post.username,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
              const TextSpan(text: ' '),
              TextSpan(
                text: post.caption,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.9)
                      : Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
          maxLines: _isCaptionExpanded ? null : 3,
          overflow: _isCaptionExpanded
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
        ),

        // "Show more" / "Show less" button
        if (shouldShowMore)
          GestureDetector(
            onTap: () {
              setState(() {
                _isCaptionExpanded = !_isCaptionExpanded;
              });
              HapticFeedback.lightImpact();
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _isCaptionExpanded ? 'Show less' : 'more',
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : Colors.black45,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMusicAttribution(PostModel post, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.2),
                    ]
                  : [
                      Colors.white.withOpacity(0.4),
                      Colors.white.withOpacity(0.2),
                    ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.music_note_rounded,
                size: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (post.musicName != null)
                      Text(
                        post.musicName!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (post.musicArtist != null)
                      Text(
                        post.musicArtist!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassPostHeader(PostModel post, bool isDark) {
    final authProvider = context.read<AuthProvider>();
    final bool isOwnPost = authProvider.isOwnPost(post.userId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Profile Picture with Glass Effect - Tap to view profile
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              // TODO: Navigate to user profile
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Navigate to ${post.username}\'s profile'),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          Colors.white.withOpacity(0.4),
                          Colors.white.withOpacity(0.2),
                        ]
                      : [kPrimary.withOpacity(0.4), kPrimary.withOpacity(0.2)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : kPrimary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(post.userAvatar),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Username and Location
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                // TODO: Navigate to user profile
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Navigate to ${post.username}\'s profile'),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (post.location != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black54,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            post.location!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.black54,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Follow/Unfollow Button (Only for others' posts)
          if (!isOwnPost) _buildFollowButton(post, isDark),
        ],
      ),
    );
  }

  Widget _buildFollowButton(PostModel post, bool isDark) {
    return GestureDetector(
      onTap: () async {
        final authProvider = context.read<AuthProvider>();
        if (!authProvider.isAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to follow users')),
          );
          return;
        }

        final wasFollowing = post.isFollowing;

        // Optimistic update
        setState(() {
          post.isFollowing = !post.isFollowing;
        });
        HapticFeedback.mediumImpact();

        // Call backend
        final success = wasFollowing
            ? await authProvider.unfollowUser(post.userId)
            : await authProvider.followUser(post.userId);

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  post.isFollowing
                      ? 'Following ${post.username}'
                      : 'Unfollowed ${post.username}',
                ),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          // Revert on failure
          setState(() {
            post.isFollowing = wasFollowing;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to update follow status')),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: post.isFollowing
              ? null
              : LinearGradient(colors: [kPrimary, kPrimary.withOpacity(0.8)]),
          color: post.isFollowing
              ? (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05))
              : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: post.isFollowing
                ? (isDark
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.2))
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          post.isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            color: post.isFollowing
                ? (isDark ? Colors.white : Colors.black87)
                : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPostImage(PostModel post, bool isDark) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: _handleDoubleTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Image with pinch-to-zoom
              AspectRatio(
                aspectRatio: 1.0,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 1.0,
                  maxScale: 4.0,
                  onInteractionStart: (_) {
                    setState(() => _isZoomed = true);
                  },
                  onInteractionEnd: (_) {
                    if (_transformationController.value == Matrix4.identity()) {
                      setState(() => _isZoomed = false);
                    }
                  },
                  child: post.mediaUrls.isNotEmpty
                      ? Image.network(
                          post.mediaUrls[_currentMediaIndex],
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [Colors.grey[800]!, Colors.grey[900]!]
                                    : [Colors.grey[200]!, Colors.grey[300]!],
                              ),
                            ),
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              size: 64,
                              color: isDark ? Colors.white38 : Colors.black26,
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [Colors.grey[800]!, Colors.grey[900]!]
                                  : [Colors.grey[200]!, Colors.grey[300]!],
                            ),
                          ),
                          child: Icon(
                            Icons.image_rounded,
                            size: 64,
                            color: isDark ? Colors.white38 : Colors.black26,
                          ),
                        ),
                ),
              ),

              // Floating Reactions (multiple hearts) - NO big heart animation
              Positioned.fill(child: FloatingReactions(key: _reactionsKey)),

              // Music Attribution for Videos/Reels
              if (post.isVideo &&
                  (post.musicName != null || post.musicArtist != null))
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: _buildMusicAttribution(post, isDark),
                ),

              // Carousel Indicators with Glass Effect
              if (post.hasMultipleMedia)
                Positioned(
                  bottom: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    Colors.white.withOpacity(0.15),
                                    Colors.white.withOpacity(0.08),
                                  ]
                                : [
                                    Colors.black.withOpacity(0.15),
                                    Colors.black.withOpacity(0.08),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.2)
                                : Colors.black.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            post.mediaUrls.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: index == _currentMediaIndex ? 20 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                gradient: index == _currentMediaIndex
                                    ? LinearGradient(
                                        colors: [kPrimary, Colors.purple],
                                      )
                                    : null,
                                color: index == _currentMediaIndex
                                    ? null
                                    : isDark
                                    ? Colors.white.withOpacity(0.4)
                                    : Colors.black.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(PostModel post, bool isDark) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.04),
                    ]
                  : [
                      Colors.black.withOpacity(0.04),
                      Colors.black.withOpacity(0.02),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Comment',
                onTap: _openComments,
                isDark: isDark,
              ),
              _buildBottomButton(
                icon: post.isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                label: 'Save',
                onTap: _toggleSave,
                isDark: isDark,
                isActive: post.isSaved,
              ),
              _buildBottomButton(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: _openShare,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? kPrimary
                  : (isDark ? Colors.white : Colors.black87),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? kPrimary
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom Sheets
  Widget _buildCommentsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final commentController = TextEditingController();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? kDarkBackground : kLightBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Comments list
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Sample comments - replace with actual data
                    _buildCommentItem(
                      isDark: isDark,
                      username: 'user_1',
                      comment: 'Amazing photo! 😍',
                      timeAgo: '2h',
                      likes: 12,
                    ),
                    const SizedBox(height: 16),
                    _buildCommentItem(
                      isDark: isDark,
                      username: 'user_2',
                      comment: 'Love this! Where is this place?',
                      timeAgo: '5h',
                      likes: 8,
                    ),
                    const SizedBox(height: 16),
                    _buildCommentItem(
                      isDark: isDark,
                      username: 'user_3',
                      comment: 'Stunning view! 🌄',
                      timeAgo: '1d',
                      likes: 24,
                    ),
                  ],
                ),
              ),

              // Comment input box
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: isDark ? kDarkBackground : kLightBackground,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // User avatar
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isDark
                          ? Colors.grey[800]
                          : Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        size: 20,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Text input
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white.withOpacity(0.5)
                                : Colors.black54,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    // Send button
                    IconButton(
                      icon: Icon(Icons.send_rounded, color: kPrimary),
                      onPressed: () {
                        if (commentController.text.trim().isNotEmpty) {
                          // TODO: Send comment
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Comment posted!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          commentController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentItem({
    required bool isDark,
    required String username,
    required String comment,
    required String timeAgo,
    required int likes,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar - Use theme-based placeholder
        CircleAvatar(
          radius: 18,
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
          child: Icon(
            Icons.person,
            size: 20,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(width: 12),
        // Comment content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: comment,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    timeAgo,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$likes likes',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Reply',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Like button
        IconButton(
          icon: Icon(
            Icons.favorite_outline_rounded,
            size: 16,
            color: isDark ? Colors.white.withOpacity(0.7) : Colors.black54,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
          },
        ),
      ],
    );
  }

  Widget _buildShareSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? kDarkBackground : kLightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.3)
                  : Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(
            'Share Post',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),

          const SizedBox(height: 24),

          _buildShareOption(
            icon: Icons.auto_stories_rounded,
            label: 'Share to Story',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening story creator...')),
              );
            },
            isDark: isDark,
          ),

          _buildShareOption(
            icon: Icons.send_rounded,
            label: 'Send in DM',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening direct messages...')),
              );
            },
            isDark: isDark,
          ),

          _buildShareOption(
            icon: Icons.copy_rounded,
            label: 'Copy Link',
            onTap: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
              final postLink = _postService.getPostLink(_currentPost.id);
              Clipboard.setData(ClipboardData(text: postLink));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link copied to clipboard!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            isDark: isDark,
          ),

          _buildShareOption(
            icon: Icons.share_outlined,
            label: 'Share Externally',
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement native share
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening share menu...')),
              );
            },
            isDark: isDark,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOptionsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.read<AuthProvider>();
    final bool isOwnPost = authProvider.isOwnPost(_currentPost.userId);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isDark
                ? kDarkBackground.withOpacity(0.95)
                : kLightBackground.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Text(
                  'Post Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Divider
              Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08),
              ),

              const SizedBox(height: 8),

              // Scrollable options list
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Options for viewing other's posts
                      if (!isOwnPost) ...[
                        _buildShareOption(
                          icon: Icons.report_outlined,
                          label: 'Report Post',
                          onTap: () {
                            Navigator.pop(context);
                            _showReportDialog();
                          },
                          isDark: isDark,
                          isDestructive: true,
                        ),

                        _buildDivider(isDark),

                        _buildShareOption(
                          icon: Icons.link_rounded,
                          label: 'Copy Link',
                          onTap: () {
                            Navigator.pop(context);
                            HapticFeedback.lightImpact();
                            final postLink = _postService.getPostLink(
                              _currentPost.id,
                            );
                            Clipboard.setData(ClipboardData(text: postLink));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Link copied!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          isDark: isDark,
                        ),

                        _buildDivider(isDark),

                        _buildShareOption(
                          icon: Icons.volume_off_outlined,
                          label: 'Mute ${_currentPost.username}',
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Muted ${_currentPost.username}'),
                              ),
                            );
                          },
                          isDark: isDark,
                        ),

                        _buildDivider(isDark),

                        _buildShareOption(
                          icon: _currentPost.isFollowing
                              ? Icons.person_remove_outlined
                              : Icons.person_add_outlined,
                          label: _currentPost.isFollowing
                              ? 'Unfollow ${_currentPost.username}'
                              : 'Follow ${_currentPost.username}',
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _currentPost.isFollowing =
                                  !_currentPost.isFollowing;
                            });
                          },
                          isDark: isDark,
                        ),

                        _buildDivider(isDark),

                        _buildShareOption(
                          icon: Icons.block_outlined,
                          label: 'Block ${_currentPost.username}',
                          onTap: () {
                            Navigator.pop(context);
                            _showBlockDialog();
                          },
                          isDark: isDark,
                          isDestructive: true,
                        ),

                        _buildDivider(isDark),

                        _buildShareOption(
                          icon: Icons.notifications_outlined,
                          label: 'Turn on Post Notifications',
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Post notifications enabled'),
                              ),
                            );
                          },
                          isDark: isDark,
                        ),

                        _buildDivider(isDark),

                        _buildShareOption(
                          icon: Icons.person_outlined,
                          label: 'View Account',
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: Navigate to user profile
                          },
                          isDark: isDark,
                        ),

                        _buildDivider(isDark),

                        _buildShareOption(
                          icon: Icons.visibility_off_outlined,
                          label: 'Hide this Post',
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Post hidden')),
                            );
                          },
                          isDark: isDark,
                        ),

                        _buildDivider(isDark),

                        _buildShareOption(
                          icon: Icons.not_interested_outlined,
                          label: 'Not Interested',
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'We\'ll show you fewer posts like this',
                                ),
                              ),
                            );
                          },
                          isDark: isDark,
                        ),
                      ],

                      // Options for own posts
                      if (isOwnPost) ...[
                        _buildShareOption(
                          icon: Icons.edit_outlined,
                          label: 'Edit Post',
                          onTap: () {
                            Navigator.pop(context);
                            _showEditCaptionDialog();
                          },
                          isDark: isDark,
                        ),

                        _buildDivider(isDark),

                        _buildShareOption(
                          icon: Icons.bar_chart_rounded,
                          label: 'View Insights',
                          onTap: () {
                            Navigator.pop(context);
                            _showInsightsSheet();
                          },
                          isDark: isDark,
                        ),

                        _buildDivider(isDark),

                        _buildShareOption(
                          icon: Icons.share_outlined,
                          label: 'Share Post',
                          onTap: () {
                            Navigator.pop(context);
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Share functionality coming soon',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          isDark: isDark,
                        ),

                        _buildDivider(isDark),

                        _buildShareOption(
                          icon: Icons.link_rounded,
                          label: 'Copy Link',
                          onTap: () {
                            Navigator.pop(context);
                            HapticFeedback.lightImpact();
                            final postLink = _postService.getPostLink(
                              _currentPost.id,
                            );
                            Clipboard.setData(ClipboardData(text: postLink));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Link copied to clipboard'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          isDark: isDark,
                        ),

                        _buildDivider(isDark),

                        _buildShareOption(
                          icon: Icons.people_outline,
                          label: 'Post Settings',
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Post settings feature coming soon',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          isDark: isDark,
                        ),

                        _buildDivider(isDark),

                        _buildShareOption(
                          icon: Icons.archive_outlined,
                          label: _currentPost.isArchived
                              ? 'Unarchive'
                              : 'Archive',
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _currentPost.isArchived =
                                  !_currentPost.isArchived;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _currentPost.isArchived
                                      ? 'Post archived'
                                      : 'Post unarchived',
                                ),
                              ),
                            );
                          },
                          isDark: isDark,
                        ),

                        _buildDivider(isDark),

                        _buildShareOption(
                          icon: _currentPost.commentsEnabled
                              ? Icons.comments_disabled_outlined
                              : Icons.comment_outlined,
                          label: _currentPost.commentsEnabled
                              ? 'Turn Off Comments'
                              : 'Turn On Comments',
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _currentPost.commentsEnabled =
                                  !_currentPost.commentsEnabled;
                            });
                          },
                          isDark: isDark,
                        ),

                        _buildDivider(isDark),

                        _buildShareOption(
                          icon: _currentPost.hideLikeCount
                              ? Icons.favorite_outline
                              : Icons.favorite_border,
                          label: _currentPost.hideLikeCount
                              ? 'Show Like Count'
                              : 'Hide Like Count',
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _currentPost.hideLikeCount =
                                  !_currentPost.hideLikeCount;
                            });
                          },
                          isDark: isDark,
                        ),

                        _buildDivider(isDark),

                        _buildShareOption(
                          icon: Icons.push_pin_outlined,
                          label: _currentPost.isPinned
                              ? 'Unpin from Profile'
                              : 'Pin to Profile',
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _currentPost.isPinned = !_currentPost.isPinned;
                            });
                          },
                          isDark: isDark,
                        ),

                        _buildDivider(isDark),

                        _buildShareOption(
                          icon: Icons.campaign_outlined,
                          label: 'Promote Post',
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Opening promotion settings...'),
                              ),
                            );
                          },
                          isDark: isDark,
                        ),

                        _buildDivider(isDark),

                        _buildShareOption(
                          icon: Icons.people_outlined,
                          label: 'See Who Saved This',
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Showing saved users...'),
                              ),
                            );
                          },
                          isDark: isDark,
                        ),

                        _buildDivider(isDark),

                        _buildShareOption(
                          icon: Icons.delete_outline,
                          label: 'Delete Post',
                          onTap: () {
                            Navigator.pop(context);
                            _showDeleteDialog();
                          },
                          isDark: isDark,
                          isDestructive: true,
                        ),
                      ],

                      const SizedBox(height: 16),
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

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: const Text('Why are you reporting this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Post reported. Thank you for your feedback.'),
                ),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block ${_currentPost.username}?'),
        content: Text(
          '${_currentPost.username} won\'t be able to find your profile or see your content.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_currentPost.username} has been blocked'),
                ),
              );
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Close post viewer
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Post deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditCaptionDialog() {
    final controller = TextEditingController(text: _currentPost.caption);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Caption'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Write a caption...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _currentPost.caption;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Caption updated')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showInsightsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? kDarkBackground : kLightBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.3)
                    : Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Post Insights',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildInsightCard(
                    icon: Icons.visibility_rounded,
                    label: 'Views',
                    value: _formatCount(_currentPost.views),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildInsightCard(
                    icon: Icons.favorite_rounded,
                    label: 'Likes',
                    value: _formatCount(_currentPost.likes),
                    color: Colors.red,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildInsightCard(
                    icon: Icons.comment_rounded,
                    label: 'Comments',
                    value: _formatCount(_currentPost.comments),
                    color: kPrimary,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildInsightCard(
                    icon: Icons.share_rounded,
                    label: 'Shares',
                    value: _formatCount(_currentPost.shares),
                    color: Colors.green,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildInsightCard(
                    icon: Icons.bookmark_rounded,
                    label: 'Saves',
                    value: _formatCount(_currentPost.saves),
                    color: Colors.orange,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Engagement Rate',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kPrimary.withOpacity(0.2),
                          Colors.purple.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: kPrimary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${((_currentPost.likes + _currentPost.comments + _currentPost.shares) / (_currentPost.views > 0 ? _currentPost.views : 1) * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: kPrimary,
                          ),
                        ),
                        const Text(
                          'Total Engagement',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.04)]
              : [
                  Colors.black.withOpacity(0.04),
                  Colors.black.withOpacity(0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (color ?? kPrimary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color ?? kPrimary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive
                    ? Colors.red
                    : (isDark ? Colors.white : Colors.black87),
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDestructive
                        ? Colors.red
                        : (isDark ? Colors.white : Colors.black87),
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 0,
      endIndent: 0,
      color: isDark
          ? Colors.white.withOpacity(0.1)
          : Colors.black.withOpacity(0.08),
    );
  }
}
