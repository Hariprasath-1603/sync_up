import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';
import '../models/post_model.dart';
import 'widgets/floating_reactions.dart';
import 'widgets/post_actions_bar.dart';
import 'widgets/post_header.dart';
import 'widgets/music_bar.dart';

/// Full-screen post/reel viewer with premium interactions
class PostViewerPage extends StatefulWidget {
  const PostViewerPage({
    super.key,
    required this.initialPost,
    required this.allPosts,
    this.onPostChanged,
  });

  final PostModel initialPost;
  final List<PostModel> allPosts;
  final ValueChanged<PostModel>? onPostChanged;

  @override
  State<PostViewerPage> createState() => _PostViewerPageState();
}

class _PostViewerPageState extends State<PostViewerPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late PostModel _currentPost;
  late AnimationController _likeAnimationController;
  late AnimationController _saveAnimationController;
  final GlobalKey<FloatingReactionsState> _reactionsKey = GlobalKey();

  bool _showLikeAnimation = false;
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

    _likeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _saveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _likeAnimationController.dispose();
    _saveAnimationController.dispose();
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

  void _doubleTapLike(TapDownDetails details) {
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
    _saveAnimationController.forward(from: 0);
    HapticFeedback.lightImpact();

    // Show save confirmation
    if (_currentPost.isSaved) {
      _showSaveDialog();
    }
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => _SavedDialog(postId: _currentPost.id),
    );
  }

  void _togglePause() {
    if (_currentPost.isVideo) {
      setState(() => _isPaused = !_isPaused);
      HapticFeedback.selectionClick();
    }
  }

  void _openComments() {
    HapticFeedback.mediumImpact();
    // TODO: Open comments bottom sheet
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Comments coming soon!')));
  }

  void _openShare() {
    HapticFeedback.lightImpact();
    // TODO: Open share sheet
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Share coming soon!')));
  }

  void _openOptions() {
    HapticFeedback.mediumImpact();
    // TODO: Open extended menu
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Options coming soon!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Main content with vertical page view
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            itemCount: widget.allPosts.length,
            itemBuilder: (context, index) {
              final post = widget.allPosts[index];
              return _buildPostContent(post);
            },
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: PostHeader(
              post: _currentPost,
              onBack: () => Navigator.pop(context),
              onOptions: _openOptions,
            ),
          ),

          // Bottom actions and info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Caption and info
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_currentPost.caption.isNotEmpty)
                              _CaptionText(caption: _currentPost.caption),
                            if (_currentPost.location != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _currentPost.location!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (_currentPost.musicName != null) ...[
                              const SizedBox(height: 12),
                              MusicBar(
                                musicName: _currentPost.musicName!,
                                artist: _currentPost.musicArtist,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Action buttons
                      PostActionsBar(
                        post: _currentPost,
                        onLike: _toggleLike,
                        onComment: _openComments,
                        onShare: _openShare,
                        onSave: _toggleSave,
                        likeAnimation: _likeAnimationController,
                        saveAnimation: _saveAnimationController,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Double-tap heart animation
          if (_showLikeAnimation)
            Center(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.5, end: 1.5).animate(
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
                  ),
                ),
              ),
            ),

          // Floating reactions overlay
          Positioned.fill(
            child: IgnorePointer(child: FloatingReactions(key: _reactionsKey)),
          ),
        ],
      ),
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

  Widget _buildImageContent(PostModel post) {
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 3.0,
      child: Image.network(
        post.mediaUrls.first,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[900],
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
            color: Colors.grey[900],
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

/// Saved confirmation dialog
class _SavedDialog extends StatelessWidget {
  const _SavedDialog({required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bookmark, color: kPrimary, size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Saved to 📁 Favorites',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Navigate to collections page
                  },
                  child: Text(
                    'Change Collection',
                    style: TextStyle(
                      color: kPrimary.withOpacity(0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
}
