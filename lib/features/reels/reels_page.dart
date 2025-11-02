import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../profile/models/post_model.dart';

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final PageController _pageController = PageController();
  final SupabaseClient _supabase = Supabase.instance.client;

  List<PostModel> _reels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReels();
  }

  Future<void> _loadReels() async {
    try {
      setState(() => _isLoading = true);

      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get reels from database
      final result = await _supabase
          .from('posts')
          .select('''
            *,
            users!posts_user_id_fkey(
              uid,
              username,
              username_display,
              display_name,
              photo_url
            )
          ''')
          .eq('type', 'reel')
          .order('created_at', ascending: false)
          .limit(30);

      final reels = (result as List).map((postData) {
        final user = postData['users'];
        final username =
            user['username_display'] ??
            user['display_name'] ??
            user['username'] ??
            'User';

        final mediaUrls = postData['media_urls'] != null
            ? List<String>.from(postData['media_urls'])
            : <String>[];

        return PostModel(
          id: postData['id'],
          userId: postData['user_id'],
          type: PostType.reel,
          mediaUrls: mediaUrls,
          thumbnailUrl:
              postData['thumbnail_url'] ??
              (mediaUrls.isNotEmpty ? mediaUrls[0] : ''),
          username: username,
          userAvatar: user['photo_url'] ?? '',
          timestamp: DateTime.parse(postData['created_at']),
          caption: postData['caption'] ?? '',
          location: postData['location'],
          likes: postData['likes_count'] ?? 0,
          comments: postData['comments_count'] ?? 0,
          shares: postData['shares_count'] ?? 0,
          views: postData['views_count'] ?? 0,
          isFollowing: postData['user_id'] != currentUserId,
        );
      }).toList();

      setState(() {
        _reels = reels;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading reels: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _reels.isEmpty
          ? const Center(
              child: Text(
                'No reels available',
                style: TextStyle(color: Colors.white),
              ),
            )
          : Stack(
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

                // Top Bar with camera and search
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildTopBar(isDark),
                ),
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

  Widget _buildReelItem(PostModel reel, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video/Image Background
        if (reel.mediaUrls.isNotEmpty)
          Image.network(reel.mediaUrls.first, fit: BoxFit.cover)
        else
          Container(color: Colors.grey[900]),

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

  Widget _buildActionButtons(PostModel reel, int index) {
    return Column(
      children: [
        // Like Button
        _buildActionButton(
          icon: Icons.favorite_border, // TODO: Check if liked
          label: _formatCount(reel.likes),
          color: Colors.white,
          onTap: () {
            _showMessage('Like feature coming soon');
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
          icon: Icons.bookmark_border, // TODO: Check if saved
          label: '',
          color: Colors.white,
          onTap: () {
            _showMessage('Save feature coming soon');
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

  Widget _buildUserInfo(PostModel reel) {
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
                backgroundImage: reel.userAvatar.isNotEmpty
                    ? NetworkImage(reel.userAvatar)
                    : null,
                child: reel.userAvatar.isEmpty
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
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
            if (reel.isFollowing)
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

        // Description/Caption
        if (reel.caption.isNotEmpty)
          Text(
            reel.caption,
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

  void _showCommentsSheet(PostModel reel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(postId: reel.id),
    );
  }

  void _showShareSheet(PostModel reel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShareSheet(reel: reel),
    );
  }

  void _showMoreOptions(PostModel reel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MoreOptionsSheet(reel: reel),
    );
  }
}

// Comments Bottom Sheet with Real Data
class _CommentsSheet extends StatefulWidget {
  final String postId;

  const _CommentsSheet({required this.postId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      setState(() => _isLoading = true);

      final result = await _supabase
          .from('comments')
          .select('''
            *,
            users!comments_user_id_fkey(
              username,
              username_display,
              display_name,
              photo_url
            )
          ''')
          .eq('post_id', widget.postId)
          .order('created_at', ascending: false);

      final comments = (result as List).map((commentData) {
        final user = commentData['users'];
        final username =
            user['username_display'] ??
            user['display_name'] ??
            user['username'] ??
            'User';

        return {
          'id': commentData['id'],
          'text': commentData['text'],
          'username': username,
          'userAvatar': user['photo_url'] ?? '',
          'timestamp': DateTime.parse(commentData['created_at']),
          'likes': commentData['likes_count'] ?? 0,
        };
      }).toList();

      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading comments: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      await _supabase.from('comments').insert({
        'post_id': widget.postId,
        'user_id': currentUser.id,
        'text': _commentController.text,
        'likes_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Increment comments count
      await _supabase.rpc(
        'increment_comments_count',
        params: {'post_id_input': widget.postId},
      );

      _commentController.clear();
      _loadComments(); // Reload comments

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comment posted!')));
      }
    } catch (e) {
      print('❌ Error adding comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to post comment')));
      }
    }
  }

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
                  '${_comments.length} Comments',
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                ? const Center(child: Text('No comments yet'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      return _buildCommentItem(_comments[index]);
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
                    onPressed: _addComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final timestamp = comment['timestamp'] as DateTime;
    final timeDiff = DateTime.now().difference(timestamp);
    final timeAgo = timeDiff.inDays > 0
        ? '${timeDiff.inDays}d'
        : timeDiff.inHours > 0
        ? '${timeDiff.inHours}h'
        : '${timeDiff.inMinutes}m';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: comment['userAvatar'].isNotEmpty
                ? NetworkImage(comment['userAvatar'])
                : null,
            child: comment['userAvatar'].isEmpty
                ? const Icon(Icons.person, size: 18)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment['username'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment['text'],
                  style: TextStyle(color: Colors.grey[800], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${comment['likes']} likes',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(width: 16),
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
  final PostModel reel;

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
  final PostModel reel;

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
