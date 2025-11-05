import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/reel_model.dart';
import '../../../core/services/reel_service.dart';
import '../widgets/reel_video_player.dart';
import '../widgets/reel_action_buttons.dart';
import '../widgets/reel_info_overlay.dart';
import '../widgets/reel_comments_sheet.dart';
import '../../profile/other_user_profile_page.dart';

/// Main reel feed page with vertical scrolling TikTok-style interface
///
/// Supports two modes:
/// 1. Global Feed Mode (default): Shows all reels with For You/Following tabs
/// 2. Profile Reels Mode: Shows user's own reels with edit/delete controls
class ReelFeedPage extends StatefulWidget {
  final List<ReelModel>? initialReels;
  final int? initialIndex;

  /// If true, shows profile reels mode with edit/delete controls
  final bool isOwnProfile;

  /// User ID to filter reels (required if isOwnProfile is true)
  final String? userId;

  const ReelFeedPage({
    super.key,
    this.initialReels,
    this.initialIndex,
    this.isOwnProfile = false,
    this.userId,
  });

  @override
  State<ReelFeedPage> createState() => _ReelFeedPageState();
}

class _ReelFeedPageState extends State<ReelFeedPage> {
  final ReelService _reelService = ReelService();
  final PageController _pageController = PageController();

  List<ReelModel> _reels = [];
  Set<String> _likedReels = {};
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Real-time subscription
  RealtimeChannel? _reelChannel;

  @override
  void initState() {
    super.initState();

    // Set to fullscreen immersive mode
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );

    _initializeReels();
    _setupRealtimeSubscription();
    _pageController.addListener(_onPageScroll);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _reelChannel?.unsubscribe();

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    super.dispose();
  }

  Future<void> _initializeReels() async {
    if (widget.initialReels != null) {
      setState(() {
        _reels = widget.initialReels!;
        _currentIndex = widget.initialIndex ?? 0;
        _isLoading = false;
      });

      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }

      // Check liked status for initial reels
      _checkLikedStatus();
    } else {
      await _loadReels();
    }
  }

  Future<void> _loadReels({bool refresh = false}) async {
    if (!refresh && _isLoadingMore) return;

    setState(() {
      if (refresh) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final offset = refresh ? 0 : _reels.length;
      final List<ReelModel> newReels;

      // Fetch reels based on mode
      if (widget.isOwnProfile && widget.userId != null) {
        // Profile mode: Fetch only user's reels
        newReels = await _reelService.fetchUserReels(
          userId: widget.userId!,
          limit: 10,
          offset: offset,
        );
      } else {
        // Global feed mode: Fetch all reels
        newReels = await _reelService.fetchFeedReels(limit: 10, offset: offset);
      }

      if (mounted) {
        setState(() {
          if (refresh) {
            _reels = newReels;
            _currentIndex = 0;
          } else {
            _reels.addAll(newReels);
          }

          _hasMore = newReels.length >= 10;
          _isLoading = false;
          _isLoadingMore = false;
        });

        // Check liked status for new reels
        _checkLikedStatus();
      }
    } catch (e) {
      debugPrint('❌ Error loading reels: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _checkLikedStatus() async {
    for (final reel in _reels) {
      final isLiked = await _reelService.hasLikedReel(reel.id);
      if (isLiked && mounted) {
        setState(() {
          _likedReels.add(reel.id);
        });
      }
    }
  }

  void _setupRealtimeSubscription() {
    final supabase = Supabase.instance.client;

    _reelChannel = supabase
        .channel('reels_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'reels',
          callback: (payload) {
            _handleReelUpdate(payload);
          },
        )
        .subscribe();
  }

  void _handleReelUpdate(PostgresChangePayload payload) {
    final updatedData = payload.newRecord;
    final reelId = updatedData['id'] as String;

    // Find and update the reel in the list
    final index = _reels.indexWhere((r) => r.id == reelId);
    if (index != -1 && mounted) {
      setState(() {
        _reels[index] = _reels[index].copyWith(
          likesCount: updatedData['likes_count'] as int?,
          commentsCount: updatedData['comments_count'] as int?,
          sharesCount: updatedData['shares_count'] as int?,
          viewsCount: updatedData['views_count'] as int?,
        );
      });
    }
  }

  void _onPageScroll() {
    final page = _pageController.page?.round() ?? 0;

    if (page != _currentIndex) {
      setState(() {
        _currentIndex = page;
      });

      // Record view for the new reel
      if (page < _reels.length) {
        _reelService.recordView(_reels[page].id);
      }

      // Load more reels when near the end
      if (page >= _reels.length - 3 && _hasMore && !_isLoadingMore) {
        _loadReels();
      }
    }
  }

  Future<void> _toggleLike(ReelModel reel) async {
    final isLiked = _likedReels.contains(reel.id);

    // Optimistic UI update
    setState(() {
      if (isLiked) {
        _likedReels.remove(reel.id);
        reel = reel.copyWith(likesCount: reel.likesCount - 1);
      } else {
        _likedReels.add(reel.id);
        reel = reel.copyWith(likesCount: reel.likesCount + 1);
      }

      // Update in list
      final index = _reels.indexWhere((r) => r.id == reel.id);
      if (index != -1) {
        _reels[index] = reel;
      }
    });

    // Send to backend
    final success = isLiked
        ? await _reelService.unlikeReel(reel.id)
        : await _reelService.likeReel(reel.id);

    // Revert if failed
    if (!success && mounted) {
      setState(() {
        if (isLiked) {
          _likedReels.add(reel.id);
          reel = reel.copyWith(likesCount: reel.likesCount + 1);
        } else {
          _likedReels.remove(reel.id);
          reel = reel.copyWith(likesCount: reel.likesCount - 1);
        }

        final index = _reels.indexWhere((r) => r.id == reel.id);
        if (index != -1) {
          _reels[index] = reel;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update like'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openComments(ReelModel reel) async {
    await ReelCommentsSheet.show(context, reel.id);

    // Refresh reel to update comment count
    final updatedReels = await _reelService.fetchFeedReels(limit: 1, offset: 0);
    if (updatedReels.isNotEmpty && mounted) {
      final index = _reels.indexWhere((r) => r.id == reel.id);
      if (index != -1) {
        setState(() {
          _reels[index] = updatedReels.first;
        });
      }
    }
  }

  Future<void> _shareReel(ReelModel reel) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShareBottomSheet(
        reel: reel,
        onShareComplete: () async {
          await _reelService.shareReel(reelId: reel.id, sharedTo: 'external');

          // Update share count
          final index = _reels.indexWhere((r) => r.id == reel.id);
          if (index != -1 && mounted) {
            setState(() {
              _reels[index] = _reels[index].copyWith(
                sharesCount: _reels[index].sharesCount + 1,
              );
            });
          }
        },
      ),
    );
  }

  void _navigateToProfile(String userId) {
    // Get reel to find username
    final reel = _reels.firstWhere(
      (r) => r.userId == userId,
      orElse: () => _reels.first,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OtherUserProfilePage(
          userId: userId,
          username: reel.username ?? 'user',
        ),
      ),
    );
  }

  // ========================================
  // PROFILE MODE ACTIONS
  // ========================================

  /// Edit reel caption and settings
  Future<void> _editReel(ReelModel reel) async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditReelSheet(reel: reel),
    );

    if (result != null && mounted) {
      // Update reel with new data
      final index = _reels.indexWhere((r) => r.id == reel.id);
      if (index != -1) {
        setState(() {
          _reels[index] = _reels[index].copyWith(
            caption: result['caption'] as String?,
          );
        });
      }
    }
  }

  /// Show reel insights (views, likes, saves)
  void _showInsights(ReelModel reel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _InsightsSheet(reel: reel),
    );
  }

  /// Archive reel (hide from profile)
  Future<void> _archiveReel(ReelModel reel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Reel?'),
        content: const Text(
          'This reel will be hidden from your profile. You can restore it later from your archive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implement archive functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Archive feature coming soon')),
      );
    }
  }

  /// Delete reel permanently
  Future<void> _deleteReel(ReelModel reel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reel?'),
        content: const Text(
          'This reel will be permanently deleted. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _reelService.deleteReel(reel.id);

        if (mounted) {
          setState(() {
            _reels.removeWhere((r) => r.id == reel.id);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reel deleted successfully')),
          );

          // Exit if no more reels
          if (_reels.isEmpty) {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete reel: $e')));
        }
      }
    }
  }

  /// Show more options menu
  void _showMoreOptions(ReelModel reel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MoreOptionsSheet(
        reel: reel,
        onEditCaption: () {
          Navigator.pop(context);
          _editReel(reel);
        },
        onChangeThumbnail: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Change thumbnail coming soon')),
          );
        },
        onToggleComments: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Toggle comments coming soon')),
          );
        },
        onToggleRemix: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Toggle remix coming soon')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (_reels.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.video_library_outlined,
                  size: 80,
                  color: Colors.white54,
                ),
                const SizedBox(height: 24),
                const Text(
                  'No reels available',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Be the first to create a reel!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Navigate to create reel page
                    // TODO: Implement navigation
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Reel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _reels.length + (_hasMore ? 1 : 0),
        onPageChanged: (index) {
          // This is handled by _onPageScroll listener
        },
        itemBuilder: (context, index) {
          // Show loading indicator at the end
          if (index >= _reels.length) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }

          final reel = _reels[index];
          final isCurrentReel = index == _currentIndex;
          final isLiked = _likedReels.contains(reel.id);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Video Player
              ReelVideoPlayer(
                videoUrl: reel.videoUrl,
                isCurrentReel: isCurrentReel,
              ),

              // Double tap to like overlay
              GestureDetector(
                onDoubleTap: () {
                  if (!isLiked) {
                    _toggleLike(reel);
                    _showLikeAnimation();
                  }
                },
                child: Container(color: Colors.transparent),
              ),

              // Reel Info Overlay (bottom left)
              ReelInfoOverlay(
                reel: reel,
                onUsernameTap: () => _navigateToProfile(reel.userId),
              ),

              // Action Buttons (right side) - conditional based on mode
              Positioned(
                right: 0,
                bottom: 0,
                top: 0,
                child: widget.isOwnProfile
                    ? _buildProfileModeControls(reel)
                    : ReelActionButtons(
                        reel: reel,
                        isLiked: isLiked,
                        onLikeTap: () => _toggleLike(reel),
                        onCommentTap: () => _openComments(reel),
                        onShareTap: () => _shareReel(reel),
                        onProfileTap: () => _navigateToProfile(reel.userId),
                      ),
              ),

              // Back button (top left)
              SafeArea(
                child: Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build profile mode control buttons (edit, insights, archive, delete)
  Widget _buildProfileModeControls(ReelModel reel) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(right: 12, bottom: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Edit button
            _ProfileActionButton(
              icon: Icons.edit,
              label: 'Edit',
              onTap: () => _editReel(reel),
            ),
            const SizedBox(height: 24),

            // Insights button
            _ProfileActionButton(
              icon: Icons.bar_chart,
              label: 'Insights',
              onTap: () => _showInsights(reel),
            ),
            const SizedBox(height: 24),

            // Archive button
            _ProfileActionButton(
              icon: Icons.archive_outlined,
              label: 'Archive',
              onTap: () => _archiveReel(reel),
            ),
            const SizedBox(height: 24),

            // Delete button
            _ProfileActionButton(
              icon: Icons.delete_outline,
              label: 'Delete',
              onTap: () => _deleteReel(reel),
              color: Colors.red,
            ),
            const SizedBox(height: 24),

            // More options button
            _ProfileActionButton(
              icon: Icons.more_vert,
              label: 'More',
              onTap: () => _showMoreOptions(reel),
            ),
          ],
        ),
      ),
    );
  }

  void _showLikeAnimation() {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: 1.0 - value,
                child: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 120,
                  shadows: [Shadow(color: Colors.black, blurRadius: 20)],
                ),
              ),
            );
          },
          onEnd: () {
            overlayEntry.remove();
          },
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }
}

/// Share bottom sheet widget
class _ShareBottomSheet extends StatelessWidget {
  final ReelModel reel;
  final VoidCallback onShareComplete;

  const _ShareBottomSheet({required this.reel, required this.onShareComplete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Share Reel',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 24),

          // Share options
          _ShareOption(
            icon: Icons.link,
            label: 'Copy Link',
            onTap: () {
              Clipboard.setData(ClipboardData(text: reel.videoUrl));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard')),
              );
              onShareComplete();
            },
          ),
          const SizedBox(height: 16),
          _ShareOption(
            icon: Icons.share,
            label: 'Share via...',
            onTap: () async {
              Navigator.pop(context);
              await Share.share(
                'Check out this reel!\n${reel.videoUrl}',
                subject: 'SyncUp Reel',
              );
              onShareComplete();
            },
          ),
          const SizedBox(height: 16),
          _ShareOption(
            icon: Icons.download,
            label: 'Save Video',
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement video download
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download feature coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDark ? Colors.white : Colors.black),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile action button widget (for profile mode controls)
class _ProfileActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color ?? Colors.white,
              size: 28,
              shadows: const [Shadow(color: Colors.black, blurRadius: 8)],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Edit reel bottom sheet
class _EditReelSheet extends StatefulWidget {
  final ReelModel reel;

  const _EditReelSheet({required this.reel});

  @override
  State<_EditReelSheet> createState() => _EditReelSheetState();
}

class _EditReelSheetState extends State<_EditReelSheet> {
  late TextEditingController _captionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.reel.caption);
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      final reelService = ReelService();
      await reelService.updateReelCaption(
        reelId: widget.reel.id,
        caption: _captionController.text,
      );

      if (mounted) {
        Navigator.pop(context, {'caption': _captionController.text});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Edit Reel',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 24),

          // Caption field
          TextField(
            controller: _captionController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Caption',
              hintText: 'Write a caption...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          ElevatedButton(
            onPressed: _isLoading ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}

/// Reel insights bottom sheet
class _InsightsSheet extends StatelessWidget {
  final ReelModel reel;

  const _InsightsSheet({required this.reel});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Reel Insights',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 32),

          // Insights
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InsightItem(
                icon: Icons.remove_red_eye,
                label: 'Views',
                value: reel.formattedViewsCount,
              ),
              _InsightItem(
                icon: Icons.favorite,
                label: 'Likes',
                value: reel.formattedLikesCount,
              ),
              _InsightItem(
                icon: Icons.comment,
                label: 'Comments',
                value: reel.formattedCommentsCount,
              ),
              _InsightItem(
                icon: Icons.share,
                label: 'Shares',
                value: reel.formattedSharesCount,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Engagement rate (mock data)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Engagement Rate',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  '${((reel.likesCount + reel.commentsCount) / (reel.viewsCount + 1) * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InsightItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Icon(icon, size: 32, color: isDark ? Colors.white : Colors.black),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }
}

/// More options bottom sheet
class _MoreOptionsSheet extends StatelessWidget {
  final ReelModel reel;
  final VoidCallback onEditCaption;
  final VoidCallback onChangeThumbnail;
  final VoidCallback onToggleComments;
  final VoidCallback onToggleRemix;

  const _MoreOptionsSheet({
    required this.reel,
    required this.onEditCaption,
    required this.onChangeThumbnail,
    required this.onToggleComments,
    required this.onToggleRemix,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'More Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 24),

          // Options
          _MoreOption(
            icon: Icons.edit,
            label: 'Edit Caption',
            onTap: onEditCaption,
          ),
          const SizedBox(height: 12),
          _MoreOption(
            icon: Icons.image,
            label: 'Change Thumbnail',
            onTap: onChangeThumbnail,
          ),
          const SizedBox(height: 12),
          _MoreOption(
            icon: Icons.comment_outlined,
            label: 'Hide Likes & Comments',
            onTap: onToggleComments,
          ),
          const SizedBox(height: 12),
          _MoreOption(
            icon: Icons.repeat,
            label: 'Allow Remix',
            onTap: onToggleRemix,
          ),
        ],
      ),
    );
  }
}

class _MoreOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoreOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDark ? Colors.white : Colors.black),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
