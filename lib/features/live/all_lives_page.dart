import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'live_viewer_page.dart';

class AllLivesPage extends StatefulWidget {
  const AllLivesPage({super.key});

  @override
  State<AllLivesPage> createState() => _AllLivesPageState();
}

class _AllLivesPageState extends State<AllLivesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<String> _filters = [
    'All',
    'Trending',
    'Music',
    'Gaming',
    'Sports',
    'Learning',
    'Wellness',
    'Tech',
  ];

  final List<LiveStreamData> _allLiveStreams = [
    LiveStreamData(
      hostName: 'Harper Ray',
      hostAvatarUrl:
          'https://images.unsplash.com/photo-1614289371518-722f2615943c?auto=format&fit=crop&w=200&q=80',
      coverImageUrl:
          'https://images.unsplash.com/photo-1525182008055-f88b95ff7980?auto=format&fit=crop&w=900&q=80',
      viewerCount: 3200,
      title: 'Weekly AMA + Behind the Scenes',
      category: 'Trending',
      tags: ['Q&A', 'Community'],
    ),
    LiveStreamData(
      hostName: 'Priya Sharma',
      hostAvatarUrl:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=80',
      coverImageUrl:
          'https://images.unsplash.com/photo-1515378791036-0648a3ef77b2?auto=format&fit=crop&w=900&q=80',
      viewerCount: 1850,
      title: 'Designing your first UI Kit',
      category: 'Learning',
      tags: ['Design', 'Tutorial'],
    ),
    LiveStreamData(
      hostName: 'Diego Luna',
      hostAvatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
      coverImageUrl:
          'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=900&q=80',
      viewerCount: 960,
      title: 'Sunset rooftop sessions',
      category: 'Music',
      tags: ['Music', 'Live set'],
    ),
    LiveStreamData(
      hostName: 'Maya Collins',
      hostAvatarUrl:
          'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?auto=format&fit=crop&w=200&q=80',
      coverImageUrl:
          'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=900&q=80',
      viewerCount: 1520,
      title: 'Morning yoga for focus',
      category: 'Wellness',
      tags: ['Wellness', 'Yoga'],
    ),
    LiveStreamData(
      hostName: 'Nova Tech',
      hostAvatarUrl:
          'https://images.unsplash.com/photo-1525132298875-2d716f84a3b3?auto=format&fit=crop&w=200&q=80',
      coverImageUrl:
          'https://images.unsplash.com/photo-1517430816045-df4b7de11d1d?auto=format&fit=crop&w=900&q=80',
      viewerCount: 2210,
      title: 'React Native best practices',
      category: 'Tech',
      tags: ['Coding', 'Mobile'],
    ),
    LiveStreamData(
      hostName: 'Ezra Bloom',
      hostAvatarUrl:
          'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?auto=format&fit=crop&w=200&q=80',
      coverImageUrl:
          'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=900&q=80',
      viewerCount: 1380,
      title: 'Color grading cinematic reels',
      category: 'Learning',
      tags: ['Editing', 'Tips'],
    ),
    LiveStreamData(
      hostName: 'Alex Storm',
      hostAvatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
      coverImageUrl:
          'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=900&q=80',
      viewerCount: 2890,
      title: 'Pro Gaming Tournament Live',
      category: 'Gaming',
      tags: ['Gaming', 'Esports'],
    ),
    LiveStreamData(
      hostName: 'Sophia Lee',
      hostAvatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
      coverImageUrl:
          'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?auto=format&fit=crop&w=900&q=80',
      viewerCount: 4120,
      title: 'NBA Finals Watch Party',
      category: 'Sports',
      tags: ['Sports', 'Basketball'],
    ),
    LiveStreamData(
      hostName: 'DJ Nexus',
      hostAvatarUrl:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=200&q=80',
      coverImageUrl:
          'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?auto=format&fit=crop&w=900&q=80',
      viewerCount: 5670,
      title: 'Electronic Music Festival',
      category: 'Music',
      tags: ['Music', 'EDM', 'Party'],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LiveStreamData> get _filteredStreams {
    var streams = _allLiveStreams;

    // Apply category filter
    if (_selectedFilter != 'All') {
      streams = streams
          .where((stream) => stream.category == _selectedFilter)
          .toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      streams = streams.where((stream) {
        final query = _searchQuery.toLowerCase();
        return stream.hostName.toLowerCase().contains(query) ||
            stream.title.toLowerCase().contains(query) ||
            stream.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // Sort by viewer count
    streams.sort((a, b) => b.viewerCount.compareTo(a.viewerCount));

    return streams;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0B0E13),
                    const Color(0xFF1A1D29),
                    const Color(0xFF0B0E13),
                  ]
                : [
                    const Color(0xFFF6F7FB),
                    const Color(0xFFE8ECFF),
                    const Color(0xFFF6F7FB),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with Back Button
              _buildHeader(isDark),

              // Search Bar
              _buildSearchBar(isDark),

              // Filter Chips
              _buildFilterChips(isDark),

              // Live Streams Grid
              Expanded(child: _buildLiveStreamsGrid(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.videocam_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'All Live Streams',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_filteredStreams.length} live now',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _searchQuery.isNotEmpty
                    ? kPrimary.withOpacity(0.5)
                    : (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search live streams...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey[400],
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _searchQuery.isNotEmpty ? kPrimary : Colors.grey,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [kPrimary, kPrimary.withOpacity(0.7)],
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? kPrimary
                      : (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black87),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveStreamsGrid(bool isDark) {
    final filteredStreams = _filteredStreams;

    if (filteredStreams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off_rounded,
              size: 64,
              color: isDark ? Colors.white30 : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No live streams found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredStreams.length,
      itemBuilder: (context, index) {
        return _LiveStreamCard(stream: filteredStreams[index], isDark: isDark);
      },
    );
  }
}

class _LiveStreamCard extends StatelessWidget {
  const _LiveStreamCard({required this.stream, required this.isDark});

  final LiveStreamData stream;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LiveViewerPage(
              hostName: stream.hostName,
              hostAvatarUrl: stream.hostAvatarUrl,
              streamTitle: stream.title,
              coverImageUrl: stream.coverImageUrl,
              initialViewerCount: stream.viewerCount,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover Image
              Image.network(stream.coverImageUrl, fit: BoxFit.cover),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LIVE Badge & Viewer Count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF6B6B),
                                    Color(0xFFFF5252),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.circle,
                                    color: Colors.white,
                                    size: 8,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.visibility,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _formatViewerCount(stream.viewerCount),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Host Info
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            image: DecorationImage(
                              image: NetworkImage(stream.hostAvatarUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                stream.hostName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                stream.title,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
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

  String _formatViewerCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class LiveStreamData {
  final String hostName;
  final String hostAvatarUrl;
  final String coverImageUrl;
  final int viewerCount;
  final String title;
  final String category;
  final List<String> tags;

  LiveStreamData({
    required this.hostName,
    required this.hostAvatarUrl,
    required this.coverImageUrl,
    required this.viewerCount,
    required this.title,
    required this.category,
    required this.tags,
  });
}
