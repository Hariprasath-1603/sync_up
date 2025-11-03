import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/scaffold_with_nav_bar.dart';
import '../../core/theme.dart';
import '../profile/pages/widgets/floating_reactions.dart';
import '../profile/other_user_profile_page.dart';
import 'pages/upload_reel_page.dart';

// Global key for accessing ReelsPageNew state from anywhere
final GlobalKey<_ReelsPageNewState> reelsPageKey =
    GlobalKey<_ReelsPageNewState>();

class ReelsPageNew extends StatefulWidget {
  final ReelData? initialReel;
  final int? initialIndex;
  final bool shouldRefresh;

  const ReelsPageNew({
    super.key,
    this.initialReel,
    this.initialIndex,
    this.shouldRefresh = false,
  });

  @override
  State<ReelsPageNew> createState() => _ReelsPageNewState();
}

class _ReelsPageNewState extends State<ReelsPageNew>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentReelIndex = 0;
  bool _isFollowingTab = false;
  final GlobalKey<FloatingReactionsState> _reactionsKey = GlobalKey();

  // Video progress tracking
  late AnimationController _progressController;
  bool _isLongPressing = false;
  bool _isRefreshing = false;
  bool _autoScroll = true; // Auto-scroll feature (on by default)

  // For You Reels (all reels)
  final List<ReelData> _forYouReels = [];
  // Following Reels (only from followed users)
  List<ReelData> get _followingReels {
    return _forYouReels.where((reel) => reel.isFollowing).toList();
  }

  // Current reels based on selected tab
  List<ReelData> get _currentReels {
    return _isFollowingTab ? _followingReels : _forYouReels;
  }

  @override
  void initState() {
    super.initState();

    // Initialize progress controller for video progress
    _progressController =
        AnimationController(
            vsync: this,
            duration: const Duration(seconds: 15), // Assume 15 seconds per reel
          )
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            // Auto-scroll to next reel when current one completes
            if (status == AnimationStatus.completed && _autoScroll) {
              if (_currentReelIndex < _currentReels.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            }
          });

    // If an initial reel is provided, add it to the beginning of the list
    if (widget.initialReel != null) {
      _forYouReels.insert(0, widget.initialReel!);
    }

    // If an initial index is provided, jump to that index
    if (widget.initialIndex != null) {
      _currentReelIndex = widget.initialIndex!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(widget.initialIndex!);
        }
      });
    }

    // Start progress only if there are reels
    if (_currentReels.isNotEmpty) {
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _switchTab(bool isFollowing) {
    setState(() {
      _isFollowingTab = isFollowing;
      _currentReelIndex = 0;
      if (_currentReels.isNotEmpty) {
        _pageController.jumpToPage(0);
        _progressController.reset();
        _progressController.forward();
      }
    });
  }

  Future<void> refreshReels() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    // Simulate loading new reels with animation
    await Future.delayed(const Duration(milliseconds: 1500));

    // In a real app, you would fetch new reels from an API here
    // For now, we'll shuffle the existing reels
    setState(() {
      _forYouReels.shuffle();
      _isRefreshing = false;
      _currentReelIndex = 0;
      if (_currentReels.isNotEmpty) {
        _progressController.reset();
        _progressController.forward();
      }
    });

    // Jump to first reel if there are reels
    if (_pageController.hasClients && _currentReels.isNotEmpty) {
      _pageController.jumpToPage(0);
    }
  }

  void _onPageChanged(int index) {
    if (_currentReels.isEmpty) return;

    setState(() {
      _currentReelIndex = index;
      _progressController.reset();
      _progressController.forward();
    });
  }

  void _seekBackward() {
    // Go back 5 seconds (approximately 33% of 15 second video)
    final newValue = (_progressController.value - 0.33).clamp(0.0, 1.0);
    setState(() {
      _progressController.value = newValue;
    });
    _progressController.forward(from: newValue);

    // Show visual feedback
    _showSeekFeedback('âª -5s', Icons.fast_rewind_rounded);
  }

  void _seekForward() {
    // Go forward 5 seconds (approximately 33% of 15 second video)
    final newValue = (_progressController.value + 0.33).clamp(0.0, 1.0);
    setState(() {
      _progressController.value = newValue;
    });
    _progressController.forward(from: newValue);

    // Show visual feedback
    _showSeekFeedback('â© +5s', Icons.fast_forward_rounded);
  }

  void _showSeekFeedback(String text, IconData icon) {
    // Visual feedback removed per user request
    // Seek happens silently now
  }

  void _toggleLike(int index) {
    if (index < 0 || index >= _currentReels.length) return;

    setState(() {
      _currentReels[index].isLiked = !_currentReels[index].isLiked;
      if (_currentReels[index].isLiked) {
        _currentReels[index].likes++;
        // Add multiple floating hearts from bottom
        _reactionsKey.currentState?.addReaction('â¤ï¸');
      } else {
        _currentReels[index].likes--;
      }
    });
  }

  void _toggleSave(int index) {
    if (index < 0 || index >= _currentReels.length) return;

    setState(() {
      _currentReels[index].isSaved = !_currentReels[index].isSaved;
    });
  }

  void _toggleFollow(int index) async {
    if (index < 0 || index >= _currentReels.length) return;

    final reel = _currentReels[index];

    // If already following, show confirmation dialog
    if (reel.isFollowing) {
      final shouldUnfollow = await showDialog<bool>(
        context: context,
        builder: (context) =>
            _UnfollowConfirmationDialog(username: reel.username),
      );

      if (shouldUnfollow == true) {
        setState(() {
          _currentReels[index].isFollowing = false;
        });
      }
    } else {
      // If not following, just follow
      setState(() {
        _currentReels[index].isFollowing = true;
      });
    }
  }

  void _showCommentsModal(ReelData reel) {
    final navVisibility = NavBarVisibilityScope.maybeOf(context);
    navVisibility?.value = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => CommentsModal(reel: reel),
    ).whenComplete(() => navVisibility?.value = true);
  }

  void _showShareSheet(ReelData reel) {
    final navVisibility = NavBarVisibilityScope.maybeOf(context);
    navVisibility?.value = false;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => ShareSheet(reel: reel),
    ).whenComplete(() => navVisibility?.value = true);
  }

  void _showMusicPage(ReelData reel) {
    final navVisibility = NavBarVisibilityScope.maybeOf(context);
    navVisibility?.value = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => MusicReelsPage(musicName: reel.musicName),
    ).whenComplete(() => navVisibility?.value = true);
  }

  void _showMoreOptions(ReelData reel, int index) {
    final navVisibility = NavBarVisibilityScope.maybeOf(context);
    navVisibility?.value = false;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => MoreOptionsSheet(
        reel: reel,
        autoScroll: _autoScroll,
        onAutoScrollChanged: (value) {
          setState(() {
            _autoScroll = value;
          });
        },
        onSave: () {
          Navigator.pop(context);
          _toggleSave(index);
        },
        onReport: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Reel reported')));
        },
        onNotInterested: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Marked as not interested')),
          );
        },
        onCopyLink: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Link copied to clipboard')),
          );
        },
      ),
    ).whenComplete(() => navVisibility?.value = true);
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatViewCount(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Vertical Scrolling Reels with Pull-to-Refresh
          RefreshIndicator(
            onRefresh: () async {
              if (_currentReelIndex == 0) {
                await refreshReels();
              }
            },
            color: Colors.white,
            backgroundColor: Colors.black87,
            displacement: 50,
            child: _currentReels.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 80,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No reels available',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade300,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isFollowingTab
                              ? 'Follow users to see their reels here'
                              : 'Be the first to create a reel!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF4A6CF7),
                                Color(0xFF7C3AED),
                                Color(0xFFEC4899),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4A6CF7).withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: const Color(0xFFEC4899).withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const UploadReelPage(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.add_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Create Reel',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: _currentReels.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      return _buildReelItem(_currentReels[index], index);
                    },
                  ),
          ),

          // Enhanced Progress Indicator at the top - Shows current video progress
          if (_currentReels.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Stack(
                      children: [
                        // Background - All reels indicator
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        // Current video progress
                        FractionallySizedBox(
                          widthFactor: _progressController.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF4A6CF7),
                                  Color(0xFF7C3AED),
                                  Color(0xFFEC4899),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4A6CF7,
                                  ).withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
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
            ),

          // Loading indicator when refreshing - Simple centered spinner
          if (_isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Top Bar with Following/For You Toggle - Modern Glass Effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tab Toggle with Glass Pills
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _switchTab(true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: _isFollowingTab
                                    ? LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.4),
                                          Colors.white.withOpacity(0.2),
                                        ],
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(40),
                                border: _isFollowingTab
                                    ? Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Text(
                                'Following',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: _isFollowingTab
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _switchTab(false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: !_isFollowingTab
                                    ? LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.4),
                                          Colors.white.withOpacity(0.2),
                                        ],
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(40),
                                border: !_isFollowingTab
                                    ? Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Text(
                                'For You',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: !_isFollowingTab
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // View Count with Glass Effect
                    if (_currentReels.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.black.withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility_rounded,
                              color: Colors.white.withOpacity(0.9),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatViewCount(
                                _isFollowingTab
                                    ? _followingReels[_currentReelIndex].views
                                    : _forYouReels[_currentReelIndex].views,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(color: Colors.black45, blurRadius: 4),
                                ],
                              ),
                            ),
                          ],
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

  Widget _buildReelItem(ReelData reel, int index) {
    return GestureDetector(
      onDoubleTapDown: (details) {
        // Double tap regions:
        // Left 25% = go back 5 seconds
        // Center 50% = like the reel
        // Right 25% = go forward 5 seconds
        final screenWidth = MediaQuery.of(context).size.width;
        final tapPosition = details.globalPosition.dx;

        if (tapPosition < screenWidth * 0.25) {
          // Left 25% - go back 5 seconds
          _seekBackward();
        } else if (tapPosition > screenWidth * 0.75) {
          // Right 25% - go forward 5 seconds
          _seekForward();
        } else {
          // Center 50% - like the reel
          _toggleLike(index);
        }
      },
      onLongPressStart: (details) {
        // Long press for 2x speed
        setState(() {
          _isLongPressing = true;
          // Speed up the animation to 2x
          _progressController.duration = const Duration(
            milliseconds: 7500,
          ); // Half of 15 seconds
        });
      },
      onLongPressEnd: (details) {
        // Return to normal speed
        setState(() {
          _isLongPressing = false;
          // Reset to normal speed
          _progressController.duration = const Duration(seconds: 15);
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Background with Gradient Overlay
          Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                reel.videoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade900,
                          Colors.purple.shade900,
                          Colors.pink.shade700,
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Bottom Gradient for Readability
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
            ],
          ),

          // Floating Hearts Animation (from bottom)
          if (_currentReelIndex == index)
            Positioned.fill(child: FloatingReactions(key: _reactionsKey)),

          // 2x Speed Indicator (when long pressing)
          if (_isLongPressing && _currentReelIndex == index)
            Positioned(
              top: 100,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kPrimary.withOpacity(0.9),
                      kPrimary.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.fast_forward_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '2x',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Right Side Action Buttons
          Positioned(
            right: 12,
            bottom: 140,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Picture with Follow Button - Enhanced Glass Effect
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    GestureDetector(
                      onTap: () => _toggleFollow(index),
                      child: Container(
                        width: 56,
                        height: 56,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
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
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(reel.profilePic),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!reel.isFollowing)
                      Positioned(
                        bottom: -5,
                        child: GestureDetector(
                          onTap: () => _toggleFollow(index),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [kPrimary, kPrimary.withOpacity(0.8)],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimary.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Like Button
                _buildActionButton(
                  icon: reel.isLiked ? Icons.favorite : Icons.favorite_border,
                  count: _formatCount(reel.likes),
                  color: reel.isLiked ? Colors.red : Colors.white,
                  onTap: () => _toggleLike(index),
                ),
                const SizedBox(height: 24),

                // Comment Button
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  count: _formatCount(reel.comments),
                  color: Colors.white,
                  onTap: () => _showCommentsModal(reel),
                ),
                const SizedBox(height: 24),

                // Share Button
                _buildActionButton(
                  icon: Icons.send,
                  count: _formatCount(reel.shares),
                  color: Colors.white,
                  onTap: () => _showShareSheet(reel),
                ),
                const SizedBox(height: 24),

                // More Options (3 dots) - Same size as other buttons
                _buildActionButton(
                  icon: Icons.more_horiz,
                  count: '',
                  color: Colors.white,
                  onTap: () => _showMoreOptions(reel, index),
                ),
              ],
            ),
          ),

          // Bottom Left Content
          Positioned(
            left: 16,
            right: 80,
            bottom: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Username with Glass Effect - Clickable to navigate to profile
                GestureDetector(
                  onTap: () {
                    final navVisibility = NavBarVisibilityScope.maybeOf(
                      context,
                    );
                    navVisibility?.value = false;

                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (context) => OtherUserProfilePage(
                              userId: reel.userId,
                              username: reel.username,
                              avatarUrl: reel.profilePic,
                            ),
                          ),
                        )
                        .whenComplete(() {
                          navVisibility?.value = true;
                        });
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
                      reel.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Caption with See More
                _buildExpandableCaption(reel.caption),
                const SizedBox(height: 10),

                // Location Tag with Glass Effect
                if (reel.location != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
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
                            reel.location!,
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
                  ),

                // Music Bar with Modern Glass Effect
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => _showMusicPage(reel),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
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
                              '${reel.musicName} â€¢ ${reel.musicArtist}',
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
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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

  Widget _buildExpandableCaption(String caption) {
    final isLong = caption.length > 80;
    if (!isLong) {
      return Text(
        caption,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      );
    }

    return _ExpandableText(caption: caption);
  }
}

class _ExpandableText extends StatefulWidget {
  final String caption;

  const _ExpandableText({required this.caption});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isExpanded ? widget.caption : '${widget.caption.substring(0, 80)}...',
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: isExpanded ? null : 2,
          overflow: isExpanded ? null : TextOverflow.ellipsis,
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: Text(
            isExpanded ? 'See less' : 'See more',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// Comments Modal
class CommentsModal extends StatefulWidget {
  final ReelData reel;

  const CommentsModal({super.key, required this.reel});

  @override
  State<CommentsModal> createState() => _CommentsModalState();
}

class _CommentsModalState extends State<CommentsModal> {
  final Map<int, bool> _likedComments = {};
  final Map<int, bool> _showReplies = {};
  final Map<int, int> _likeCounts = {};
  final Map<int, List<Map<String, dynamic>>> _replies = {};
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  int? _replyingToIndex;
  String? _replyingToUsername;

  @override
  void initState() {
    super.initState();
    // Initialize like counts and some sample replies
    for (int i = 0; i < 10; i++) {
      _likeCounts[i] = (i + 1) * 5;
      // Add sample replies for every 3rd comment
      if (i % 3 == 0) {
        _replies[i] = [
          {
            'username': '@replier_1',
            'text': 'Thanks for sharing!',
            'time': '${i}m',
            'avatar': 'https://i.pravatar.cc/150?img=${i + 20}',
          },
          {
            'username': '@replier_2',
            'text': 'Agreed! ðŸ’¯',
            'time': '${i + 1}m',
            'avatar': 'https://i.pravatar.cc/150?img=${i + 21}',
          },
        ];
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _toggleLike(int index) {
    setState(() {
      _likedComments[index] = !(_likedComments[index] ?? false);
      _likeCounts[index] =
          (_likeCounts[index] ?? 0) + (_likedComments[index]! ? 1 : -1);
    });
  }

  void _toggleReplies(int index) {
    setState(() {
      _showReplies[index] = !(_showReplies[index] ?? false);
    });
  }

  void _startReply(int index, String username) {
    setState(() {
      _replyingToIndex = index;
      _replyingToUsername = username;
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
      final replies = _replies[_replyingToIndex!] ?? [];
      replies.add({
        'username':
            '@you', // placeholder kept; UI will be updated dynamically at runtime
        'text': _replyController.text.trim(),
        'time': 'Just now',
        'avatar': 'https://i.pravatar.cc/150?img=1',
      });
      _replies[_replyingToIndex!] = replies;
      _showReplies[_replyingToIndex!] =
          true; // Auto-show replies after submitting
      _replyController.clear();
      _replyingToIndex = null;
      _replyingToUsername = null;
    });
  }

  void _submitComment() {
    if (_commentController.text.trim().isEmpty) return;
    // TODO: Implement actual comment submission
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1D24) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle Bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.reel.comments} Comments',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
              Divider(
                color: isDark ? Colors.grey[800] : Colors.grey[300],
                height: 1,
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 10,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final isLiked = _likedComments[index] ?? false;
                    final likeCount = _likeCounts[index] ?? 0;
                    final showReplies = _showReplies[index] ?? false;

                    return Column(
                      children: [
                        _buildCommentItem(
                          index,
                          '@user_${index + 1}',
                          '${index + 1}h',
                          'Amazing content! Keep it up ðŸ”¥',
                          isLiked,
                          likeCount,
                          'https://i.pravatar.cc/150?img=${index + 10}',
                          hasReplies: index % 3 == 0,
                          showReplies: showReplies,
                          isDark: isDark,
                        ),
                        // Show replies if toggled
                        if (showReplies && index % 3 == 0)
                          _buildRepliesSection(index, isDark),
                      ],
                    );
                  },
                ),
              ),
              // Comment/Reply Input
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0B0E13) : Colors.grey[100],
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
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
                                ? const Color(0xFF1A1D24)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Replying to $_replyingToUsername',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
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
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(
                              'https://i.pravatar.cc/150?img=1',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _replyingToIndex != null
                                  ? _replyController
                                  : _commentController,
                              decoration: InputDecoration(
                                hintText: _replyingToIndex != null
                                    ? 'Write a reply...'
                                    : 'Add a comment...',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF1A1D24)
                                    : Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF4A6CF7),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) {
                                if (_replyingToIndex != null) {
                                  _submitReply();
                                } else {
                                  _submitComment();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Color(0xFF4A6CF7),
                            ),
                            onPressed: () {
                              if (_replyingToIndex != null) {
                                _submitReply();
                              } else {
                                _submitComment();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentItem(
    int index,
    String username,
    String time,
    String comment,
    bool isLiked,
    int likeCount,
    String avatarUrl, {
    bool hasReplies = false,
    bool showReplies = false,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 18, backgroundImage: NetworkImage(avatarUrl)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      username,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment,
                  style: TextStyle(
                    color: isDark ? Colors.grey[200] : Colors.black87,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Reply button
                    GestureDetector(
                      onTap: () => _startReply(index, username),
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (hasReplies) ...[
                      const SizedBox(width: 16),
                      // View/Hide replies button
                      GestureDetector(
                        onTap: () => _toggleReplies(index),
                        child: Text(
                          showReplies
                              ? 'Hide replies'
                              : 'View ${(_replies[index]?.length ?? 0) + 2} replies',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 16),
                    // Like count
                    GestureDetector(
                      onTap: () => _toggleLike(index),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked
                                ? Colors.red
                                : (isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600]),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$likeCount',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
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
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked
                  ? Colors.red
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
              size: 20,
            ),
            onPressed: () => _toggleLike(index),
          ),
        ],
      ),
    );
  }

  Widget _buildRepliesSection(int parentIndex, bool isDark) {
    final replies = _replies[parentIndex] ?? [];

    if (replies.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 42, bottom: 16),
      child: Column(
        children: replies
            .map(
              (reply) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundImage: NetworkImage(reply['avatar']),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                reply['username'],
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                reply['time'],
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            reply['text'],
                            style: TextStyle(
                              color: isDark ? Colors.grey[200] : Colors.black87,
                              fontSize: 13,
                            ),
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
    );
  }
}

// Share Sheet
class ShareSheet extends StatelessWidget {
  final ReelData reel;

  const ShareSheet({super.key, required this.reel});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Share',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildShareOption(context, Icons.person_add, 'Share to Story', () {}),
          _buildShareOption(context, Icons.link, 'Copy Link', () {}),
          _buildShareOption(
            context,
            Icons.chat_bubble_outline,
            'Send via Direct Message',
            () {},
          ),
          _buildShareOption(
            context,
            Icons.video_library,
            'Remix This Reel',
            () {},
          ),
          _buildShareOption(context, Icons.download, 'Save to Device', () {}),
          _buildShareOption(context, Icons.qr_code, 'QR Code', () {}),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.grey : Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.white : Colors.black87),
      title: Text(
        label,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      ),
      onTap: onTap,
    );
  }
}

// More Options Sheet
class MoreOptionsSheet extends StatefulWidget {
  final ReelData reel;
  final bool autoScroll;
  final ValueChanged<bool> onAutoScrollChanged;
  final VoidCallback onSave;
  final VoidCallback onReport;
  final VoidCallback onNotInterested;
  final VoidCallback onCopyLink;

  const MoreOptionsSheet({
    super.key,
    required this.reel,
    required this.autoScroll,
    required this.onAutoScrollChanged,
    required this.onSave,
    required this.onReport,
    required this.onNotInterested,
    required this.onCopyLink,
  });

  @override
  State<MoreOptionsSheet> createState() => _MoreOptionsSheetState();
}

class _MoreOptionsSheetState extends State<MoreOptionsSheet> {
  late bool _localAutoScroll;

  @override
  void initState() {
    super.initState();
    _localAutoScroll = widget.autoScroll;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Auto-scroll toggle
                _buildSwitchOption(
                  context,
                  Icons.auto_awesome_motion_rounded,
                  'Auto Scroll',
                  'Automatically play next reel',
                  _localAutoScroll,
                  (value) {
                    setState(() {
                      _localAutoScroll = value;
                    });
                    widget.onAutoScrollChanged(value);
                  },
                ),
                // Save option
                _buildOption(
                  context,
                  widget.reel.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  widget.reel.isSaved ? 'Remove from Saved' : 'Save',
                  widget.onSave,
                ),
                _buildOption(
                  context,
                  Icons.report_outlined,
                  'Report',
                  widget.onReport,
                ),
                _buildOption(
                  context,
                  Icons.not_interested_outlined,
                  'Not Interested',
                  widget.onNotInterested,
                ),
                _buildOption(
                  context,
                  Icons.link,
                  'Copy Link',
                  widget.onCopyLink,
                ),
                _buildOption(
                  context,
                  Icons.person_add_outlined,
                  'About This Account',
                  () {
                    Navigator.pop(context);
                  },
                ),
                _buildOption(
                  context,
                  Icons.share_outlined,
                  'Share Profile',
                  () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? Colors.grey : Colors.grey.shade600,
                      fontSize: 16,
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

  Widget _buildSwitchOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.white : Colors.black87),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.grey.shade600,
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: kPrimary,
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.white : Colors.black87),
      title: Text(
        label,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      ),
      onTap: onTap,
    );
  }
}

// Music Reels Page
class MusicReelsPage extends StatelessWidget {
  final String musicName;

  const MusicReelsPage({super.key, required this.musicName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1D24),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.music_note, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Original Audio',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        musicName,
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.grey, height: 1),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 9 / 16,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: 20,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://picsum.photos/seed/music$index/400/800',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 14,
                            ),
                            Text(
                              '${(index + 1) * 12}K',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Unfollow Confirmation Dialog
class _UnfollowConfirmationDialog extends StatelessWidget {
  final String username;

  const _UnfollowConfirmationDialog({required this.username});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A1D24).withOpacity(0.95)
                  : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        kPrimary.withOpacity(0.2),
                        kPrimary.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.person_remove_outlined,
                    size: 32,
                    color: kPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Unfollow $username?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  'Their posts will no longer appear in your feed',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (isDark ? Colors.white : Colors.black)
                                .withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Unfollow Button
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [kPrimary, kPrimary.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimary.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Unfollow',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Reel Data Model
class ReelData {
  final String id;
  final String userId;
  final String username;
  final String profilePic;
  final String caption;
  final String musicName;
  final String musicArtist;
  final String videoUrl;
  int likes;
  final int comments;
  final int shares;
  final int views;
  bool isLiked;
  bool isSaved;
  bool isFollowing;
  final String? location;

  ReelData({
    required this.id,
    required this.userId,
    required this.username,
    required this.profilePic,
    required this.caption,
    required this.musicName,
    required this.musicArtist,
    required this.videoUrl,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.views,
    required this.isLiked,
    required this.isSaved,
    required this.isFollowing,
    this.location,
  });
}
