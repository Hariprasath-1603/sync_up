import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post_model.dart';
import 'widgets/floating_reactions.dart';

/// Modern glassmorphism post viewer (like reels page)
class PostViewerPageV2 extends StatefulWidget {
  const PostViewerPageV2({
    super.key,
    required this.initialPost,
    required this.allPosts,
    this.onPostChanged,
  });

  final PostModel initialPost;
  final List<PostModel> allPosts;
  final ValueChanged<PostModel>? onPostChanged;

  @override
  State<PostViewerPageV2> createState() => _PostViewerPageV2State();
}

class _PostViewerPageV2State extends State<PostViewerPageV2>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late PostModel _currentPost;
  late AnimationController _heartAnimationController;
  final GlobalKey<FloatingReactionsState> _reactionsKey = GlobalKey();

  bool _isPaused = false;
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

    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heartAnimationController.dispose();
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
      _heartAnimationController.forward(from: 0).then((_) {
        _heartAnimationController.reverse();
      });
      _reactionsKey.currentState?.addReaction('❤️');
      HapticFeedback.mediumImpact();
    }
  }

  void _doubleTapLike(TapDownDetails details) {
    if (!_currentPost.isLiked) {
      _toggleLike();
    } else {
      // Just show animation if already liked
      _heartAnimationController.forward(from: 0).then((_) {
        _heartAnimationController.reverse();
      });
      _reactionsKey.currentState?.addReaction('❤️');
      HapticFeedback.mediumImpact();
    }
  }

  void _toggleSave() {
    setState(() {
      _currentPost.isSaved = !_currentPost.isSaved;
    });
    HapticFeedback.lightImpact();
  }

  void _togglePause() {
    if (_currentPost.isVideo) {
      setState(() => _isPaused = !_isPaused);
      HapticFeedback.selectionClick();
    }
  }

  void _openComments() {
    // TODO: Implement comments modal
    HapticFeedback.lightImpact();
  }

  void _openShare() {
    // TODO: Implement share sheet
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.1),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: _onPageChanged,
        itemCount: widget.allPosts.length,
        itemBuilder: (context, index) {
          return _buildPostView(widget.allPosts[index]);
        },
      ),
    );
  }

  Widget _buildPostView(PostModel post) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Post content
        _buildPostContent(post),

        // Bottom gradient for readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),

        // Heart animation (smaller, centered)
        Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.2).animate(
              CurvedAnimation(
                parent: _heartAnimationController,
                curve: Curves.easeOut,
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _heartAnimationController,
                  curve: const Interval(0.0, 0.5),
                ),
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 80,
                shadows: [Shadow(color: Colors.black45, blurRadius: 20)],
              ),
            ),
          ),
        ),

        // Floating hearts from bottom
        Positioned.fill(
          child: IgnorePointer(child: FloatingReactions(key: _reactionsKey)),
        ),

        // Right side action buttons (glassmorphism)
        Positioned(
          right: 12,
          bottom: 140,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Picture
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to profile
                },
                child: Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.4),
                        Colors.white.withOpacity(0.2),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(post.userAvatar),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Like Button
              _buildActionButton(
                icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                count: _formatCount(post.likes),
                color: post.isLiked ? Colors.red : Colors.white,
                onTap: _toggleLike,
              ),
              const SizedBox(height: 24),

              // Comment Button
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                count: _formatCount(post.comments),
                color: Colors.white,
                onTap: _openComments,
              ),
              const SizedBox(height: 24),

              // Share Button
              _buildActionButton(
                icon: Icons.send,
                count: _formatCount(post.shares),
                color: Colors.white,
                onTap: _openShare,
              ),
              const SizedBox(height: 24),

              // Save Button
              _buildActionButton(
                icon: post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                count: '',
                color: post.isSaved ? Colors.yellow : Colors.white,
                onTap: _toggleSave,
              ),
            ],
          ),
        ),

        // Bottom content with glassmorphism
        Positioned(
          left: 16,
          right: 80,
          bottom: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Username with glass effect
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to profile
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    post.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                ),
              ),
              if (post.caption.isNotEmpty) ...[
                const SizedBox(height: 10),
                _CaptionText(caption: post.caption),
              ],
              if (post.location != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: Colors.red.shade300,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.location!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (post.musicName != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.pink.withOpacity(0.6),
                              Colors.purple.withOpacity(0.6),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          '${post.musicName} • ${post.musicArtist ?? "Unknown"}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostContent(PostModel post) {
    return GestureDetector(
      onTap: _togglePause,
      onDoubleTapDown: _doubleTapLike,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Media content
          if (post.isVideo)
            _buildVideoContent(post)
          else if (post.isCarousel)
            _buildCarouselContent(post)
          else
            _buildImageContent(post),

          // Pause indicator for videos
          if (post.isVideo && _isPaused)
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pause, color: Colors.white, size: 48),
              ),
            ),

          // Carousel indicators
          if (post.isCarousel)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: _buildCarouselIndicators(post),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          if (count.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                count,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageContent(PostModel post) {
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 3.0,
      child: Image.network(
        post.mediaUrls.first,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.purple.shade900],
            ),
          ),
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent(PostModel post) {
    // TODO: Implement video player
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(post.thumbnailUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Icon(
          _isPaused ? Icons.play_circle_outline : Icons.pause_circle_outline,
          color: Colors.white.withOpacity(0.7),
          size: 72,
        ),
      ),
    );
  }

  Widget _buildCarouselContent(PostModel post) {
    return PageView.builder(
      onPageChanged: (index) {
        setState(() => _currentMediaIndex = index);
        HapticFeedback.selectionClick();
      },
      itemCount: post.mediaUrls.length,
      itemBuilder: (context, index) {
        return Image.network(
          post.mediaUrls[index],
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.purple.shade900],
              ),
            ),
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCarouselIndicators(PostModel post) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          post.mediaUrls.length,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _currentMediaIndex == index
                  ? Colors.white
                  : Colors.white.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
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
}

/// Caption text with "see more" expansion
class _CaptionText extends StatefulWidget {
  const _CaptionText({required this.caption});

  final String caption;

  @override
  State<_CaptionText> createState() => _CaptionTextState();
}

class _CaptionTextState extends State<_CaptionText> {
  bool _isExpanded = false;
  static const _maxLines = 2;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.caption,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
          maxLines: _isExpanded ? null : _maxLines,
          overflow: _isExpanded ? null : TextOverflow.ellipsis,
        ),
        if (widget.caption.length > 80)
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _isExpanded ? 'see less' : 'see more',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
