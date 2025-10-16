import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/scaffold_with_nav_bar.dart';
import '../stories/storyverse_page.dart';

class StoriesArchivePage extends StatefulWidget {
  final Map<String, List<StoryVerseStory>> storyCollections;

  const StoriesArchivePage({super.key, required this.storyCollections});

  @override
  State<StoriesArchivePage> createState() => _StoriesArchivePageState();
}

class _StoriesArchivePageState extends State<StoriesArchivePage> {
  DateTime? _selectedDate;
  DateTimeRange? _selectedDateRange;

  // Flatten all stories from collections into a single list
  List<StoryVerseStory> _getAllStories() {
    final allStories = <StoryVerseStory>[];
    widget.storyCollections.forEach((category, stories) {
      allStories.addAll(stories);
    });
    // Sort by date, newest first
    allStories.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allStories;
  }

  List<StoryVerseStory> _getFilteredStories() {
    final allStories = _getAllStories();

    if (_selectedDate != null) {
      // Filter by specific date
      return allStories.where((story) {
        return story.timestamp.year == _selectedDate!.year &&
            story.timestamp.month == _selectedDate!.month &&
            story.timestamp.day == _selectedDate!.day;
      }).toList();
    } else if (_selectedDateRange != null) {
      // Filter by date range
      return allStories.where((story) {
        return story.timestamp.isAfter(_selectedDateRange!.start) &&
            story.timestamp.isBefore(
              _selectedDateRange!.end.add(const Duration(days: 1)),
            );
      }).toList();
    }

    return allStories;
  }

  // Group stories by date for display
  Map<String, List<StoryVerseStory>> _getStoriesGroupedByDate() {
    final filtered = _getFilteredStories();
    final grouped = <String, List<StoryVerseStory>>{};

    for (final story in filtered) {
      final dateKey = _formatDateKey(story.timestamp);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(story);
    }

    return grouped;
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final storyDate = DateTime(date.year, date.month, date.day);

    if (storyDate == today) {
      return 'Today';
    } else if (storyDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(storyDate).inDays < 7) {
      return _getDayName(date.weekday);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  void _openStoryViewer(
    StoryVerseStory story,
    List<StoryVerseStory> allStories,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryVerseExperience(
          initialStage: StoryVerseStage.viewer,
          initialStory: story,
          feedStories: allStories,
          showEntryStage: false,
          showInsightsButton: true,
        ),
      ),
    );
  }

  Future<void> _showCalendarPicker() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navVisibility = NavBarVisibilityScope.maybeOf(context);
    navVisibility?.value = false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Filter Stories',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Single Date Picker
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: kPrimary,
                                onPrimary: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                          _selectedDateRange = null;
                        });
                      }
                      navVisibility?.value = true;
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Select Single Date'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Date Range Picker
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: kPrimary,
                                onPrimary: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (range != null) {
                        setState(() {
                          _selectedDateRange = range;
                          _selectedDate = null;
                        });
                      }
                      navVisibility?.value = true;
                    },
                    icon: const Icon(Icons.date_range),
                    label: const Text('Select Date Range'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Clear Filter
                  if (_selectedDate != null || _selectedDateRange != null)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedDate = null;
                          _selectedDateRange = null;
                        });
                        navVisibility?.value = true;
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Filter'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() => navVisibility?.value = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storiesGroupedByDate = _getStoriesGroupedByDate();
    final allStories = _getFilteredStories();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Your Stories Archive',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_month_rounded,
              color: (_selectedDate != null || _selectedDateRange != null)
                  ? kPrimary
                  : (isDark ? Colors.white : Colors.black87),
            ),
            onPressed: _showCalendarPicker,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0B0E13),
                    const Color(0xFF1A1F2E),
                    kPrimary.withOpacity(0.15),
                  ]
                : [
                    const Color(0xFFF6F7FB),
                    kPrimary.withOpacity(0.08),
                    const Color(0xFFE8ECFF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Filter Info
              if (_selectedDate != null || _selectedDateRange != null)
                _buildFilterInfo(isDark),
              const SizedBox(height: 8),
              // Stories List
              Expanded(
                child: allStories.isEmpty
                    ? _buildEmptyState(isDark)
                    : _buildStoriesListByDate(
                        storiesGroupedByDate,
                        allStories,
                        isDark,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterInfo(bool isDark) {
    String filterText = '';
    if (_selectedDate != null) {
      filterText =
          'Showing stories from ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
    } else if (_selectedDateRange != null) {
      filterText =
          'Showing stories from ${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} to ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimary.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_rounded, color: kPrimary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              filterText,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: kPrimary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _selectedDate = null;
                _selectedDateRange = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesListByDate(
    Map<String, List<StoryVerseStory>> groupedStories,
    List<StoryVerseStory> allStories,
    bool isDark,
  ) {
    final sortedKeys = groupedStories.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final stories = groupedStories[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kPrimary.withOpacity(0.8),
                          kPrimary.withOpacity(0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      dateKey,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${stories.length} ${stories.length == 1 ? 'story' : 'stories'}',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Stories Grid for this date
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.75,
              ),
              itemCount: stories.length,
              itemBuilder: (context, storyIndex) {
                final story = stories[storyIndex];
                return _buildStoryCard(story, allStories, isDark);
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildStoryCard(
    StoryVerseStory story,
    List<StoryVerseStory> allStories,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => _openStoryViewer(story, allStories),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kPrimary.withOpacity(0.4),
                    kPrimary.withOpacity(0.2),
                  ],
                ),
              ),
            ),
            // Placeholder content
            Container(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
              child: Icon(
                Icons.photo_library_rounded,
                size: 40,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                ),
              ),
            ),
            // Time stamp
            Positioned(
              left: 6,
              right: 6,
              bottom: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (story.mood.isNotEmpty)
                    Text(
                      story.mood,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  Text(
                    _getTimeAgo(story.timestamp),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            // Clip count badge
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${story.clips.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 80,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'No stories found',
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different time period',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
