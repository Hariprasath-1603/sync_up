import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';
import '../models/post_model.dart';
import 'widgets/floating_reactions.dart';

/// Instagram-style post viewer (not full-screen, with card-like UI)
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
  final GlobalKey<FloatingReactionsState> _reactionsKey = GlobalKey();

  bool _showLikeAnimation = false;
  int _currentMediaIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.initialPost;
    final initialIndex = widget.allPosts.indexWhere(
      (p) => p.id == widget.initialPost.id,
    );
    _pageController = PageController(
      initialPage: initialIndex >= 0 ? initialIndex : 0,
    );

    _likeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (index >= 0 && index < widget.allPosts.length) {
      setState(() {
        _currentPost = widget.allPosts[index];
        _currentMediaIndex = 0;
      });
      widget.onPostChanged?.call(_currentPost);
      HapticFeedback.selectionClick();
    }
  }

  void _toggleLike() {
    setState(() {
      _currentPost.isLiked = !_currentPost.isLiked;
      _currentPost.likes += _currentPost.isLiked ? 1 : -1;
    });

    if (_currentPost.isLiked) {
      _likeAnimationController.forward(from: 0);
      _reactionsKey.currentState?.addReaction('❤️');
      HapticFeedback.mediumImpact();
    }
  }

  void _doubleTapLike() {
    if (!_currentPost.isLiked) {
      _toggleLike();
    }
    setState(() => _showLikeAnimation = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showLikeAnimation = false);
    });
  }

  void _toggleSave() {
    setState(() {
      _currentPost.isSaved = !_currentPost.isSaved;
      _currentPost.saves += _currentPost.isSaved ? 1 : -1;
    });
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _currentPost.isSaved ? 'Saved to collection' : 'Removed from saved',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openComments() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Comments coming soon!')));
  }

  void _openShare() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Share coming soon!')));
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

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar (Instagram-style)
            _buildTopBar(isDark),

            // Scrollable Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                onPageChanged: _onPageChanged,
                itemCount: widget.allPosts.length,
                itemBuilder: (context, index) {
                  final post = widget.allPosts[index];
                  return _buildPostCard(post, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            'Post',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(PostModel post, bool isDark) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Post Header
        _buildPostHeader(post, isDark),

        // Post Image with Double-Tap
        _buildPostImage(post),

        // Action Buttons
        _buildActionButtons(post, isDark),

        // Likes Count
        if (!post.hideLikeCount)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              '${_formatCount(post.likes)} likes',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),

        // Caption
        if (post.caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: post.username,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 14,
                    ),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: post.caption,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // View Comments
        if (post.comments > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: GestureDetector(
              onTap: _openComments,
              child: Text(
                'View all ${_formatCount(post.comments)} comments',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontSize: 14,
                ),
              ),
            ),
          ),

        // Timestamp
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            '${_formatTimestamp(post.timestamp)} ago',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostHeader(PostModel post, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Profile Picture
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kPrimary, width: 2),
            ),
            child: CircleAvatar(backgroundImage: NetworkImage(post.userAvatar)),
          ),
          const SizedBox(width: 10),

          // Username
          Expanded(
            child: Text(
              post.username,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),

          // Options Menu
          IconButton(
            icon: Icon(
              Icons.more_horiz,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Options coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostImage(PostModel post) {
    return GestureDetector(
      onDoubleTap: _doubleTapLike,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Image
          AspectRatio(
            aspectRatio: 1.0, // Square like Instagram
            child: post.mediaUrls.isNotEmpty
                ? Image.network(
                    post.mediaUrls[_currentMediaIndex],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.image_not_supported, size: 48),
                    ),
                  )
                : Container(
                    color: Colors.grey[900],
                    child: const Icon(Icons.image, size: 48),
                  ),
          ),

          // Floating Reactions (hearts)
          Positioned.fill(child: FloatingReactions(key: _reactionsKey)),

          // Double-Tap Like Animation
          if (_showLikeAnimation)
            ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1.3).animate(
                CurvedAnimation(
                  parent: _likeAnimationController,
                  curve: Curves.elasticOut,
                ),
              ),
              child: FadeTransition(
                opacity: Tween<double>(
                  begin: 1.0,
                  end: 0.0,
                ).animate(_likeAnimationController),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 120,
                  shadows: [Shadow(blurRadius: 20, color: Colors.black54)],
                ),
              ),
            ),

          // Carousel Indicators (if multiple images)
          if (post.hasMultipleMedia)
            Positioned(
              bottom: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  post.mediaUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentMediaIndex
                          ? kPrimary
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(PostModel post, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Like Button
          IconButton(
            icon: Icon(
              post.isLiked ? Icons.favorite : Icons.favorite_border,
              color: post.isLiked
                  ? Colors.red
                  : (isDark ? Colors.white : Colors.black),
              size: 28,
            ),
            onPressed: _toggleLike,
          ),

          // Comment Button
          IconButton(
            icon: Icon(
              Icons.chat_bubble_outline,
              color: isDark ? Colors.white : Colors.black,
              size: 26,
            ),
            onPressed: _openComments,
          ),

          // Share Button
          IconButton(
            icon: Icon(
              Icons.send_outlined,
              color: isDark ? Colors.white : Colors.black,
              size: 26,
            ),
            onPressed: _openShare,
          ),

          const Spacer(),

          // Save Button
          IconButton(
            icon: Icon(
              post.isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: post.isSaved
                  ? kPrimary
                  : (isDark ? Colors.white : Colors.black),
              size: 28,
            ),
            onPressed: _toggleSave,
          ),
        ],
      ),
    );
  }
}
