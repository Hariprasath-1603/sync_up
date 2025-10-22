import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/scaffold_with_nav_bar.dart';
import '../profile/other_user_profile_page.dart';

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final PageController _pageController = PageController();

  final List<ReelData> _reels = [
    ReelData(
      videoUrl: 'https://picsum.photos/seed/reel1/400/800',
      username: 'john_doe',
      description: 'Amazing sunset vibes 🌅 #nature #sunset #beautiful',
      avatarUrl: 'https://i.pravatar.cc/100?img=10',
      likes: 1234,
      comments: 89,
      shares: 45,
      isLiked: false,
      isSaved: false,
    ),
    ReelData(
      videoUrl: 'https://picsum.photos/seed/reel2/400/800',
      username: 'travel_diaries',
      description: 'Exploring the mountains ⛰️ #travel #adventure #explore',
      avatarUrl: 'https://i.pravatar.cc/100?img=20',
      likes: 5678,
      comments: 234,
      shares: 123,
      isLiked: false,
      isSaved: false,
    ),
    ReelData(
      videoUrl: 'https://picsum.photos/seed/reel3/400/800',
      username: 'fitness_guru',
      description: 'Morning workout routine 💪 #fitness #gym #motivation',
      avatarUrl: 'https://i.pravatar.cc/100?img=30',
      likes: 3456,
      comments: 156,
      shares: 78,
      isLiked: true,
      isSaved: false,
    ),
    ReelData(
      videoUrl: 'https://picsum.photos/seed/reel4/400/800',
      username: 'food_lover',
      description: 'Delicious pasta recipe 🍝 #food #cooking #foodie',
      avatarUrl: 'https://i.pravatar.cc/100?img=40',
      likes: 2890,
      comments: 98,
      shares: 67,
      isLiked: false,
      isSaved: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Reels Content
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              // Page changed to index
            },
            itemCount: _reels.length,
            itemBuilder: (context, index) {
              return _buildReelItem(_reels[index], index);
            },
          ),

          // Top Bar with Camera and search
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar(isDark)),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 45, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Reels',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
            ),
          ),
          Row(
            children: [
              _buildTopBarButton(Icons.camera_alt_outlined, () {
                _showMessage('Open Camera');
              }),
              const SizedBox(width: 10),
              _buildTopBarButton(Icons.search, () {
                _showMessage('Search Reels');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBarButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
          shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
        ),
      ),
    );
  }

  Widget _buildReelItem(ReelData reel, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video/Image Background
        Image.network(reel.videoUrl, fit: BoxFit.cover),

        // Gradient Overlays
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
        ),

        // Right Side Actions
        Positioned(
          right: 8,
          bottom: 180,
          child: _buildActionButtons(reel, index),
        ),

        // Bottom User Info
        Positioned(
          left: 12,
          right: 70,
          bottom: 120,
          child: _buildUserInfo(reel),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ReelData reel, int index) {
    return Column(
      children: [
        // Like Button
        _buildActionButton(
          icon: reel.isLiked ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(reel.likes),
          color: reel.isLiked ? Colors.red : Colors.white,
          onTap: () {
            setState(() {
              _reels[index].isLiked = !_reels[index].isLiked;
              if (_reels[index].isLiked) {
                _reels[index].likes++;
              } else {
                _reels[index].likes--;
              }
            });
            _showMessage(reel.isLiked ? 'Liked' : 'Unliked');
          },
        ),
        const SizedBox(height: 20),

        // Comment Button
        _buildActionButton(
          icon: Icons.mode_comment_outlined,
          label: _formatCount(reel.comments),
          onTap: () {
            _showCommentsSheet(reel);
          },
        ),
        const SizedBox(height: 20),

        // Share Button
        _buildActionButton(
          icon: Icons.send,
          label: _formatCount(reel.shares),
          onTap: () {
            _showShareSheet(reel);
          },
        ),
        const SizedBox(height: 20),

        // Save Button
        _buildActionButton(
          icon: reel.isSaved ? Icons.bookmark : Icons.bookmark_border,
          label: '',
          color: reel.isSaved ? Colors.yellow : Colors.white,
          onTap: () {
            setState(() {
              _reels[index].isSaved = !_reels[index].isSaved;
            });
            _showMessage(reel.isSaved ? 'Saved' : 'Removed from saved');
          },
        ),
        const SizedBox(height: 20),

        // More Options Button
        _buildActionButton(
          icon: Icons.more_vert,
          label: '',
          onTap: () {
            _showMoreOptions(reel);
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
            shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserInfo(ReelData reel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Username and Follow Button
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(reel.avatarUrl),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              reel.username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                _showMessage('Follow ${reel.username}');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Follow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Description
        Text(
          reel.description,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),

        // Audio Info
        Row(
          children: [
            const Icon(Icons.music_note, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Original Audio • ${reel.username}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCommentsSheet(ReelData reel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(reel: reel),
    );
  }

  void _showShareSheet(ReelData reel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShareSheet(reel: reel),
    );
  }

  void _showMoreOptions(ReelData reel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MoreOptionsSheet(reel: reel),
    );
  }
}

// Data Model
class ReelData {
  final String videoUrl;
  final String username;
  final String description;
  final String avatarUrl;
  int likes;
  final int comments;
  final int shares;
  bool isLiked;
  bool isSaved;

  ReelData({
    required this.videoUrl,
    required this.username,
    required this.description,
    required this.avatarUrl,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.isLiked,
    required this.isSaved,
  });
}

// Comments Bottom Sheet
class _CommentsSheet extends StatefulWidget {
  final ReelData reel;

  const _CommentsSheet({required this.reel});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
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
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.reel.comments} Comments',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Comments List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) {
                return _buildCommentItem(index);
              },
            ),
          ),

          // Comment Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: kPrimary),
                    onPressed: () {
                      if (_commentController.text.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Comment posted!')),
                        );
                        _commentController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(
              'https://i.pravatar.cc/100?img=${index + 50}',
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
                      'user_${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${index + 1}h',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'This is an amazing reel! Love the content 🔥',
                  style: TextStyle(color: Colors.grey[800], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Reply',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, size: 18),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// Share Bottom Sheet
class _ShareSheet extends StatelessWidget {
  final ReelData reel;

  const _ShareSheet({required this.reel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Share to',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShareOption(Icons.link, 'Copy Link', () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Link copied!')));
                }),
                _buildShareOption(Icons.message, 'Messages', () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share to Messages')),
                  );
                }),
                _buildShareOption(Icons.share, 'Other Apps', () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share to other apps')),
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// More Options Bottom Sheet
class _MoreOptionsSheet extends StatelessWidget {
  final ReelData reel;

  const _MoreOptionsSheet({required this.reel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _buildOptionItem(Icons.report_outlined, 'Report', () {
            Navigator.pop(context);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Report submitted')));
          }),
          _buildOptionItem(Icons.block_outlined, 'Not Interested', () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Marked as not interested')),
            );
          }),
          _buildOptionItem(
            Icons.person_remove_outlined,
            'Hide posts from ${reel.username}',
            () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Hidden posts from ${reel.username}')),
              );
            },
          ),
          _buildOptionItem(Icons.info_outline, 'About this account', () {
            Navigator.pop(context);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Account info')));
          }),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
      ),
    );
  }

  Widget _buildOptionItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(leading: Icon(icon), title: Text(label), onTap: onTap);
  }
}
