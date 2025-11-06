import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme.dart';
import '../../../core/services/story_service.dart';
import '../widgets/story_insights_sheet.dart';

/// Archived Story Viewer - View past stories (read-only mode)
class ArchivedStoryViewerPage extends StatefulWidget {
  final String archiveId;
  final Map<String, dynamic> archive;

  const ArchivedStoryViewerPage({
    Key? key,
    required this.archiveId,
    required this.archive,
  }) : super(key: key);

  @override
  State<ArchivedStoryViewerPage> createState() =>
      _ArchivedStoryViewerPageState();
}

class _ArchivedStoryViewerPageState extends State<ArchivedStoryViewerPage> {
  final StoryService _storyService = StoryService();
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    if (widget.archive['media_type'] == 'video') {
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.archive['media_url']),
      );
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.play();
      setState(() => _isVideoInitialized = true);
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  Future<void> _handleRestore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Story'),
        content: const Text(
          'This story will be restored and visible for another 24 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _storyService.restoreStory(widget.archiveId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Story restored successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Archived Story'),
        content: const Text(
          'This will permanently delete this story. This action cannot be undone.',
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
        await _storyService.deleteArchivedStory(widget.archiveId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Archived story deleted')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _showInsights() {
    // Convert archived viewers to StoryViewerData format
    final viewersData =
        (widget.archive['viewers'] as List?)?.map((v) {
          final viewerMap = v is Map<String, dynamic>
              ? v
              : Map<String, dynamic>.from(v as Map);
          return StoryViewerData.fromMap(viewerMap);
        }).toList() ??
        [];

    // Calculate analytics from archived data
    final reactionsData = (widget.archive['reactions'] as List?) ?? [];
    final topReactions = <String, int>{};
    for (final reaction in reactionsData) {
      if (reaction is Map) {
        final emoji = reaction['emoji'] as String?;
        if (emoji != null) {
          topReactions[emoji] = (topReactions[emoji] ?? 0) + 1;
        }
      }
    }

    final analytics = StoryAnalytics(
      totalViews: widget.archive['views_count'] ?? 0,
      reactionsCount: reactionsData.length,
      repliesCount: 0, // Not tracked in archive
      topReactions: topReactions,
      averageWatchDuration: 0.0, // Not tracked in archive
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoryInsightsSheet(
        storyId: widget.archive['original_story_id'],
        viewers: viewersData,
        analytics: analytics,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaType = widget.archive['media_type'];
    final caption = widget.archive['caption'] ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Media content
            Center(
              child: mediaType == 'video'
                  ? _buildVideoPlayer()
                  : _buildImageViewer(),
            ),

            // Top gradient overlay
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom gradient overlay (for caption)
            if (_showControls && caption.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    caption,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),

            // ARCHIVED label
            if (_showControls)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.archive_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'ARCHIVED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Close button
            if (_showControls)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

            // Control buttons (bottom)
            if (_showControls)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 0,
                right: 0,
                child: _buildControlButtons(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: VideoPlayer(_videoController!),
    );
  }

  Widget _buildImageViewer() {
    return CachedNetworkImage(
      imageUrl: widget.archive['media_url'],
      fit: BoxFit.contain,
      placeholder: (context, url) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.broken_image, color: Colors.white, size: 60),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.insights_rounded,
            label: 'Insights',
            onTap: _showInsights,
          ),
          _buildControlButton(
            icon: Icons.restore_rounded,
            label: 'Restore',
            onTap: _handleRestore,
            color: kPrimary,
          ),
          _buildControlButton(
            icon: Icons.add_box_rounded,
            label: 'Highlight',
            onTap: () {
              // TODO: Implement highlights in future phase
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Highlights coming soon')),
              );
            },
          ),
          _buildControlButton(
            icon: Icons.delete_rounded,
            label: 'Delete',
            onTap: _handleDelete,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (color ?? Colors.white).withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
