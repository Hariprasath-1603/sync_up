import 'package:flutter/material.dart';
import '../../../core/models/reel_model.dart';
import '../../../core/theme.dart';

/// Insights/Analytics sheet for creator's own reels
class CreatorInsightsSheet extends StatelessWidget {
  final ReelModel reel;

  const CreatorInsightsSheet({super.key, required this.reel});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.insights_outlined, color: kPrimary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Reel Insights',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: isDark ? Colors.grey[800] : Colors.grey[300]),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Stats
                  _SectionTitle('Overview'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.remove_red_eye_outlined,
                          label: 'Views',
                          value: _formatCount(reel.viewsCount),
                          color: Colors.blue,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.favorite_outline,
                          label: 'Likes',
                          value: _formatCount(reel.likesCount),
                          color: Colors.red,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.comment_outlined,
                          label: 'Comments',
                          value: _formatCount(reel.commentsCount),
                          color: Colors.green,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.share_outlined,
                          label: 'Shares',
                          value: _formatCount(reel.sharesCount),
                          color: Colors.orange,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Engagement Metrics
                  _SectionTitle('Engagement'),
                  const SizedBox(height: 16),
                  _MetricRow(
                    'Engagement Rate',
                    _calculateEngagementRate(),
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _MetricRow('Views to Likes', _calculateLikeRate(), isDark),
                  const SizedBox(height: 12),
                  _MetricRow(
                    'Comments per View',
                    _calculateCommentRate(),
                    isDark,
                  ),

                  const SizedBox(height: 32),

                  // Performance Indicators (Placeholder for future analytics)
                  _SectionTitle('Performance'),
                  const SizedBox(height: 16),
                  _InfoCard(
                    icon: Icons.trending_up,
                    title: 'Reach',
                    value: '${_formatCount(reel.viewsCount)} unique viewers',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.access_time,
                    title: 'Average Watch Time',
                    value: 'Coming soon',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.bar_chart,
                    title: 'Completion Rate',
                    value: 'Coming soon',
                    isDark: isDark,
                  ),

                  const SizedBox(height: 32),

                  // Posted Date
                  _SectionTitle('Details'),
                  const SizedBox(height: 16),
                  _DetailRow('Posted', _formatDate(reel.createdAt), isDark),
                  const SizedBox(height: 8),
                  _DetailRow(
                    'Duration',
                    _formatDuration(reel.duration ?? 0),
                    isDark,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow('Reel ID', reel.id.substring(0, 8), isDark),
                ],
              ),
            ),
          ),
        ],
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

  String _calculateEngagementRate() {
    if (reel.viewsCount == 0) return '0%';
    final engagement = reel.likesCount + reel.commentsCount + reel.sharesCount;
    final rate = (engagement / reel.viewsCount * 100);
    return '${rate.toStringAsFixed(1)}%';
  }

  String _calculateLikeRate() {
    if (reel.viewsCount == 0) return '0%';
    final rate = (reel.likesCount / reel.viewsCount * 100);
    return '${rate.toStringAsFixed(1)}%';
  }

  String _calculateCommentRate() {
    if (reel.viewsCount == 0) return '0%';
    final rate = (reel.commentsCount / reel.viewsCount * 100);
    return '${rate.toStringAsFixed(2)}%';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inMinutes} minutes ago';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _MetricRow(this.label, this.value, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isDark;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: kPrimary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow(this.label, this.value, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}
