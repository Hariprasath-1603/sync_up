import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme.dart';
import '../../../core/services/story_service.dart';
import 'archived_story_viewer_page.dart';
import 'story_archive_settings_page.dart';

/// Story Archive Page - View all expired/archived stories
class StoryArchivePage extends StatefulWidget {
  const StoryArchivePage({Key? key}) : super(key: key);

  @override
  State<StoryArchivePage> createState() => _StoryArchivePageState();
}

class _StoryArchivePageState extends State<StoryArchivePage>
    with SingleTickerProviderStateMixin {
  final StoryService _storyService = StoryService();

  List<Map<String, dynamic>> _archivedStories = [];
  Map<String, int> _stats = {};
  bool _isLoading = true;
  String _selectedFilter = 'all';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onFilterChanged(_getFilterForIndex(_tabController.index));
      }
    });
    _loadArchivedStories();
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getFilterForIndex(int index) {
    switch (index) {
      case 0:
        return 'all';
      case 1:
        return 'image';
      case 2:
        return 'video';
      default:
        return 'all';
    }
  }

  Future<void> _loadArchivedStories() async {
    setState(() => _isLoading = true);
    try {
      final archives = await _storyService.getArchivedStories(
        filterType: _selectedFilter,
      );
      setState(() {
        _archivedStories = archives;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading archived stories: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _storyService.getArchiveStats();
      setState(() => _stats = stats);
    } catch (e) {
      print('Error loading archive stats: $e');
    }
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    _loadArchivedStories();
  }

  Future<void> _onRefresh() async {
    await Future.wait([_loadArchivedStories(), _loadStats()]);
  }

  Future<void> _handleClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Archives'),
        content: Text(
          'Delete all ${_stats['total'] ?? 0} archived stories? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _storyService.clearAllArchivedStories();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All archives cleared')));
        _onRefresh();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kDarkBackground : kLightBackground,
      appBar: _buildAppBar(isDark),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: kPrimary,
        child: CustomScrollView(
          slivers: [
            // Stats header
            if (_stats.isNotEmpty) _buildStatsHeader(isDark),

            // Filter tabs
            _buildFilterTabs(isDark),

            // Archive grid
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_archivedStories.isEmpty)
              _buildEmptyState(isDark)
            else
              _buildArchiveGrid(isDark),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? kDarkBackground : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: isDark ? Colors.white : Colors.black,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Story Archive',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (_archivedStories.isNotEmpty)
          IconButton(
            icon: Icon(Icons.delete_sweep_rounded, color: Colors.red[400]),
            onPressed: _handleClearAll,
            tooltip: 'Clear all archives',
          ),
        IconButton(
          icon: Icon(
            Icons.settings,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () {
            // Navigate to archive settings
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StoryArchiveSettingsPage(),
              ),
            ).then((_) => _onRefresh());
          },
        ),
      ],
    );
  }

  Widget _buildStatsHeader(bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.collections_rounded,
              label: 'Total',
              value: _stats['total'].toString(),
              isDark: isDark,
            ),
            _buildStatItem(
              icon: Icons.image_rounded,
              label: 'Images',
              value: _stats['images'].toString(),
              isDark: isDark,
            ),
            _buildStatItem(
              icon: Icons.videocam_rounded,
              label: 'Videos',
              value: _stats['videos'].toString(),
              isDark: isDark,
            ),
            _buildStatItem(
              icon: Icons.restore_rounded,
              label: 'Restored',
              value: _stats['restored'].toString(),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(icon, color: kPrimary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs(bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: kPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Images'),
            Tab(text: 'Videos'),
          ],
        ),
      ),
    );
  }

  Widget _buildArchiveGrid(bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          return _buildArchiveThumbnail(_archivedStories[index], isDark);
        }, childCount: _archivedStories.length),
      ),
    );
  }

  Widget _buildArchiveThumbnail(Map<String, dynamic> archive, bool isDark) {
    final thumbnailUrl = archive['thumbnail_url'] ?? archive['media_url'];
    final viewsCount = archive['views_count'] ?? 0;
    final reactionsCount = (archive['reactions'] as List?)?.length ?? 0;
    final createdAt = DateTime.parse(archive['created_at']);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArchivedStoryViewerPage(
              archiveId: archive['id'],
              archive: archive,
            ),
          ),
        ).then((_) => _onRefresh());
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail image
              CachedNetworkImage(
                imageUrl: thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: isDark ? Colors.grey[900] : Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDark ? Colors.grey[900] : Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              ),

              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
              ),

              // "Archived" badge
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.archive_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                      SizedBox(width: 2),
                      Text(
                        'Archived',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Stats overlay (bottom)
              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // View/reaction counts
                    Row(
                      children: [
                        if (viewsCount > 0) ...[
                          Icon(
                            Icons.visibility_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$viewsCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (reactionsCount > 0) ...[
                          Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$reactionsCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Date
                    Text(
                      timeago.format(createdAt, locale: 'en_short'),
                      style: const TextStyle(color: Colors.white, fontSize: 9),
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

  Widget _buildEmptyState(bool isDark) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.archive_outlined,
              size: 80,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No Archived Stories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stories older than 24 hours\nwill appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
