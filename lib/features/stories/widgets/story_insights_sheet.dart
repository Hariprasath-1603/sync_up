import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme.dart';

/// Story viewer data model
class StoryViewerData {
  final String userId;
  final String username;
  final String? photoUrl;
  final DateTime viewedAt;
  final String? reaction; // Emoji reaction if sent

  StoryViewerData({
    required this.userId,
    required this.username,
    this.photoUrl,
    required this.viewedAt,
    this.reaction,
  });

  factory StoryViewerData.fromMap(Map<String, dynamic> map) {
    return StoryViewerData(
      userId: map['user_id'] ?? map['userId'] ?? '',
      username: map['username'] ?? 'Unknown',
      photoUrl: map['photo_url'] ?? map['photoUrl'],
      viewedAt: map['viewed_at'] != null
          ? DateTime.parse(map['viewed_at'])
          : map['viewedAt'] != null
          ? DateTime.parse(map['viewedAt'])
          : DateTime.now(),
      reaction: map['reaction'],
    );
  }
}

/// Story analytics data
class StoryAnalytics {
  final int totalViews;
  final int reactionsCount;
  final int repliesCount;
  final Map<String, int> topReactions; // Emoji → count
  final double averageWatchDuration; // in seconds

  StoryAnalytics({
    required this.totalViews,
    required this.reactionsCount,
    required this.repliesCount,
    required this.topReactions,
    required this.averageWatchDuration,
  });

  factory StoryAnalytics.empty() {
    return StoryAnalytics(
      totalViews: 0,
      reactionsCount: 0,
      repliesCount: 0,
      topReactions: {},
      averageWatchDuration: 0.0,
    );
  }
}

/// Instagram-style Story Insights Bottom Sheet
class StoryInsightsSheet extends StatefulWidget {
  final String storyId;
  final List<StoryViewerData> viewers;
  final StoryAnalytics? analytics;
  final VoidCallback? onRefresh;

  const StoryInsightsSheet({
    Key? key,
    required this.storyId,
    required this.viewers,
    this.analytics,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<StoryInsightsSheet> createState() => _StoryInsightsSheetState();
}

class _StoryInsightsSheetState extends State<StoryInsightsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final analytics = widget.analytics ?? StoryAnalytics.empty();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E).withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              // Draggable handle
              _buildHandle(isDark),

              // Header with analytics
              _buildHeader(isDark, analytics),

              // Viewer list
              Expanded(child: _buildViewerList(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[700] : Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(bool isDark, StoryAnalytics analytics) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Icon(Icons.visibility_rounded, color: kPrimary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Story Insights',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                  onPressed: widget.onRefresh,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Analytics cards
            Row(
              children: [
                _buildAnalyticsCard(
                  icon: Icons.visibility_rounded,
                  label: 'Views',
                  value: analytics.totalViews.toString(),
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _buildAnalyticsCard(
                  icon: Icons.favorite_rounded,
                  label: 'Reactions',
                  value: analytics.reactionsCount.toString(),
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _buildAnalyticsCard(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Replies',
                  value: analytics.repliesCount.toString(),
                  isDark: isDark,
                ),
              ],
            ),

            // Top reactions (if any)
            if (analytics.topReactions.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildTopReactions(analytics.topReactions, isDark),
            ],

            const SizedBox(height: 16),

            // Viewer count
            Text(
              'Viewed by ${widget.viewers.length} ${widget.viewers.length == 1 ? 'person' : 'people'}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: kPrimary, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopReactions(Map<String, int> reactions, bool isDark) {
    final sortedReactions = reactions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.whatshot_rounded, color: kPrimary, size: 18),
          const SizedBox(width: 8),
          Text(
            'Top Reactions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          ...sortedReactions.take(5).map((entry) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildViewerList(bool isDark) {
    if (widget.viewers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_off_rounded,
              size: 64,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No views yet',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: widget.viewers.length,
      itemBuilder: (context, index) {
        return _buildViewerTile(widget.viewers[index], isDark, index);
      },
    );
  }

  Widget _buildViewerTile(StoryViewerData viewer, bool isDark, int index) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 200 + (index * 50)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: InkWell(
          onTap: () {
            // Navigate to viewer's profile
            Navigator.pop(context);
            // TODO: Navigate to profile page
            // context.push('/profile/${viewer.userId}');
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.03)
                  : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: kPrimary.withOpacity(0.2),
                  backgroundImage: viewer.photoUrl != null
                      ? CachedNetworkImageProvider(viewer.photoUrl!)
                      : null,
                  child: viewer.photoUrl == null
                      ? Text(
                          viewer.username[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kPrimary,
                          ),
                        )
                      : null,
                ),

                const SizedBox(width: 12),

                // Username and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              viewer.username,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (viewer.reaction != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              viewer.reaction!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeago.format(viewer.viewedAt, locale: 'en_short'),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Chevron
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
