import 'package:flutter/material.dart';

class ReelsPageNew extends StatefulWidget {
  const ReelsPageNew({super.key});

  @override
  State<ReelsPageNew> createState() => _ReelsPageNewState();
}

class _ReelsPageNewState extends State<ReelsPageNew>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentReelIndex = 0;
  bool _isFollowingTab = false;
  late AnimationController _likeAnimationController;
  bool _showLikeAnimation = false;

  // For You Reels (all reels)
  final List<ReelData> _forYouReels = [
    ReelData(
      id: 'r12345',
      username: '@YNxz',
      profilePic: 'https://i.pravatar.cc/150?img=1',
      caption: 'It is not easy to meet each other in such a big world 🌍',
      musicName: 'Something Just Like This',
      musicArtist: '@Coldplay',
      videoUrl: 'https://picsum.photos/seed/reel1/1080/1920',
      likes: 15300,
      comments: 6686,
      shares: 2333,
      views: 120000,
      isLiked: false,
      isSaved: false,
      isFollowing: false,
      location: 'New York, USA',
    ),
    ReelData(
      id: 'r12346',
      username: '@alex_travel',
      profilePic: 'https://i.pravatar.cc/150?img=2',
      caption: 'Paradise found 🏝️ Living my best life! #travel #adventure',
      musicName: 'Blinding Lights',
      musicArtist: '@TheWeeknd',
      videoUrl: 'https://picsum.photos/seed/reel2/1080/1920',
      likes: 28400,
      comments: 8945,
      shares: 4120,
      views: 250000,
      isLiked: false,
      isSaved: false,
      isFollowing: true,
      location: 'Bali, Indonesia',
    ),
    ReelData(
      id: 'r12347',
      username: '@fitness_king',
      profilePic: 'https://i.pravatar.cc/150?img=3',
      caption: 'No excuses! 💪 Day 30 of the challenge #fitness #motivation',
      musicName: 'Eye of the Tiger',
      musicArtist: '@Survivor',
      videoUrl: 'https://picsum.photos/seed/reel3/1080/1920',
      likes: 45600,
      comments: 12300,
      shares: 5678,
      views: 380000,
      isLiked: true,
      isSaved: true,
      isFollowing: false,
      location: 'Los Angeles, CA',
    ),
    ReelData(
      id: 'r12348',
      username: '@foodie_life',
      profilePic: 'https://i.pravatar.cc/150?img=4',
      caption: 'Homemade pasta from scratch 🍝 Recipe in bio! #cooking #food',
      musicName: 'Italian Kitchen',
      musicArtist: '@ChefVibes',
      videoUrl: 'https://picsum.photos/seed/reel4/1080/1920',
      likes: 19800,
      comments: 5432,
      shares: 3214,
      views: 150000,
      isLiked: false,
      isSaved: false,
      isFollowing: true,
      location: 'Rome, Italy',
    ),
    ReelData(
      id: 'r12349',
      username: '@dance_queen',
      profilePic: 'https://i.pravatar.cc/150?img=5',
      caption: 'New choreography alert! 💃 Who wants to learn? #dance #viral',
      musicName: 'Levitating',
      musicArtist: '@DuaLipa',
      videoUrl: 'https://picsum.photos/seed/reel5/1080/1920',
      likes: 67800,
      comments: 15600,
      shares: 8900,
      views: 520000,
      isLiked: false,
      isSaved: false,
      isFollowing: false,
      location: 'Mumbai, India',
    ),
  ];

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
    _likeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _switchTab(bool isFollowing) {
    setState(() {
      _isFollowingTab = isFollowing;
      _currentReelIndex = 0;
      _pageController.jumpToPage(0);
    });
  }

  void _toggleLike(int index) {
    setState(() {
      _currentReels[index].isLiked = !_currentReels[index].isLiked;
      if (_currentReels[index].isLiked) {
        _currentReels[index].likes++;
        _showLikeAnimation = true;
        _likeAnimationController.forward().then((_) {
          _likeAnimationController.reverse();
          setState(() {
            _showLikeAnimation = false;
          });
        });
      } else {
        _currentReels[index].likes--;
      }
    });
  }

  void _toggleSave(int index) {
    setState(() {
      _currentReels[index].isSaved = !_currentReels[index].isSaved;
    });
  }

  void _toggleFollow(int index) {
    setState(() {
      _currentReels[index].isFollowing = !_currentReels[index].isFollowing;
    });
  }

  void _showCommentsModal(ReelData reel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsModal(reel: reel),
    );
  }

  void _showShareSheet(ReelData reel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareSheet(reel: reel),
    );
  }

  void _showMusicPage(ReelData reel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MusicReelsPage(musicName: reel.musicName),
    );
  }

  void _showMoreOptions(ReelData reel, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MoreOptionsSheet(
        reel: reel,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Vertical Scrolling Reels
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _currentReels.length,
            onPageChanged: (index) {
              setState(() {
                _currentReelIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildReelItem(_currentReels[index], index);
            },
          ),

          // Top Bar with Following/For You Toggle
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tab Toggle
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _switchTab(true),
                          child: Text(
                            'Following',
                            style: TextStyle(
                              color: _isFollowingTab
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              fontSize: 16,
                              fontWeight: _isFollowingTab
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: () => _switchTab(false),
                          child: Text(
                            'For You',
                            style: TextStyle(
                              color: !_isFollowingTab
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              fontSize: 16,
                              fontWeight: !_isFollowingTab
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Camera/Search Icons
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                          onPressed: () {},
                        ),
                      ],
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
      onDoubleTap: () => _toggleLike(index),
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

          // Double Tap Like Animation
          if (_showLikeAnimation && _currentReelIndex == index)
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

          // Right Side Action Buttons
          Positioned(
            right: 12,
            bottom: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Picture with Follow Button
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        image: DecorationImage(
                          image: NetworkImage(reel.profilePic),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (!reel.isFollowing)
                      Positioned(
                        bottom: -5,
                        child: GestureDetector(
                          onTap: () => _toggleFollow(index),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF3B5C),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
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

                // Save Button
                _buildActionButton(
                  icon: reel.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  count: '',
                  color: reel.isSaved ? Colors.yellow : Colors.white,
                  onTap: () => _toggleSave(index),
                ),
                const SizedBox(height: 24),

                // More Options (3 dots)
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
            bottom: 120,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Username
                  Row(
                    children: [
                      Text(
                        reel.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!reel.isFollowing) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _toggleFollow(index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Follow',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Caption with See More
                  _buildExpandableCaption(reel.caption),
                  const SizedBox(height: 10),

                  // Location Tag
                  if (reel.location != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            reel.location!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Music Bar
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => _showMusicPage(reel),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${reel.musicName} • ${reel.musicArtist}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Views Counter (Bottom Right)
          Positioned(
            right: 16,
            bottom: 120,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _formatCount(reel.views),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
          Icon(icon, color: color, size: 32),
          if (count.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
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
class CommentsModal extends StatelessWidget {
  final ReelData reel;

  const CommentsModal({super.key, required this.reel});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1D24),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle Bar
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${reel.comments} Comments',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 10,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(
                              'https://i.pravatar.cc/150?img=${index + 10}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '@user_${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${index + 1}h',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Amazing content! Keep it up 🔥',
                                  style: TextStyle(
                                    color: Colors.grey[200],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      'Reply',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      '${(index + 1) * 5} likes',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.favorite_border,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Comment Input
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0E13),
                  border: Border(
                    top: BorderSide(color: Colors.grey[800]!, width: 1),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/150?img=1',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1D24),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            'Add a comment...',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: () {},
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
}

// Share Sheet
class ShareSheet extends StatelessWidget {
  final ReelData reel;

  const ShareSheet({super.key, required this.reel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1D24),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
          const Text(
            'Share',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildShareOption(Icons.person_add, 'Share to Story', () {}),
          _buildShareOption(Icons.link, 'Copy Link', () {}),
          _buildShareOption(
            Icons.chat_bubble_outline,
            'Send via Direct Message',
            () {},
          ),
          _buildShareOption(Icons.video_library, 'Remix This Reel', () {}),
          _buildShareOption(Icons.download, 'Save to Device', () {}),
          _buildShareOption(Icons.qr_code, 'QR Code', () {}),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}

// More Options Sheet
class MoreOptionsSheet extends StatelessWidget {
  final ReelData reel;
  final VoidCallback onReport;
  final VoidCallback onNotInterested;
  final VoidCallback onCopyLink;

  const MoreOptionsSheet({
    super.key,
    required this.reel,
    required this.onReport,
    required this.onNotInterested,
    required this.onCopyLink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1D24),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
          _buildOption(Icons.report_outlined, 'Report', onReport),
          _buildOption(
            Icons.not_interested_outlined,
            'Not Interested',
            onNotInterested,
          ),
          _buildOption(Icons.link, 'Copy Link', onCopyLink),
          _buildOption(Icons.person_add_outlined, 'About This Account', () {
            Navigator.pop(context);
          }),
          _buildOption(Icons.share_outlined, 'Share Profile', () {
            Navigator.pop(context);
          }),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
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

// Reel Data Model
class ReelData {
  final String id;
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
