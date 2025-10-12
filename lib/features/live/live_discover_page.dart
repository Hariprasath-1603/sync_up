import 'package:flutter/material.dart';

import 'live_viewer_page.dart';

class LiveDiscoverPage extends StatelessWidget {
  LiveDiscoverPage({super.key});

  final List<_LiveSession> _sessions = const [
    _LiveSession(
      hostName: 'Harper Ray',
      title: 'Weekly AMA + Behind the Scenes',
      viewerCount: 3200,
      avatarUrl:
          'https://images.unsplash.com/photo-1614289371518-722f2615943c?auto=format&fit=crop&w=200&q=80',
      coverImageUrl:
          'https://images.unsplash.com/photo-1525182008055-f88b95ff7980?auto=format&fit=crop&w=900&q=80',
      tags: ['Q&A', 'Community'],
    ),
    _LiveSession(
      hostName: 'Priya Sharma',
      title: 'Designing your first UI Kit',
      viewerCount: 1850,
      avatarUrl:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=80',
      coverImageUrl:
          'https://images.unsplash.com/photo-1515378791036-0648a3ef77b2?auto=format&fit=crop&w=900&q=80',
      tags: ['Design', 'Tutorial'],
    ),
    _LiveSession(
      hostName: 'Diego Luna',
      title: 'Sunset rooftop sessions',
      viewerCount: 960,
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
      coverImageUrl:
          'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=900&q=80',
      tags: ['Music', 'Live set'],
    ),
    _LiveSession(
      hostName: 'Maya Collins',
      title: 'Morning yoga for focus',
      viewerCount: 1520,
      avatarUrl:
          'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?auto=format&fit=crop&w=200&q=80',
      coverImageUrl:
          'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=900&q=80',
      tags: ['Wellness', 'Yoga'],
    ),
    _LiveSession(
      hostName: 'Nova Tech',
      title: 'React Native best practices',
      viewerCount: 2210,
      avatarUrl:
          'https://images.unsplash.com/photo-1525132298875-2d716f84a3b3?auto=format&fit=crop&w=200&q=80',
      coverImageUrl:
          'https://images.unsplash.com/photo-1517430816045-df4b7de11d1d?auto=format&fit=crop&w=900&q=80',
      tags: ['Coding', 'Mobile'],
    ),
    _LiveSession(
      hostName: 'Ezra Bloom',
      title: 'Color grading cinematic reels',
      viewerCount: 1380,
      avatarUrl:
          'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?auto=format&fit=crop&w=200&q=80',
      coverImageUrl:
          'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=900&q=80',
      tags: ['Editing', 'Tips'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF0E1118) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live now'),
        backgroundColor: surfaceColor,
        elevation: 0,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.78,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          return _LiveSessionCard(
            session: session,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => LiveViewerPage(
                    hostName: session.hostName,
                    hostAvatarUrl: session.avatarUrl,
                    streamTitle: session.title,
                    coverImageUrl: session.coverImageUrl,
                    initialViewerCount: session.viewerCount,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _LiveSessionCard extends StatelessWidget {
  const _LiveSessionCard({required this.session, required this.onTap});

  final _LiveSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                session.coverImageUrl,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.18),
                colorBlendMode: BlendMode.darken,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x33000000), Color(0xCC000000)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: _LiveBadge(isDark: isDark),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: _ViewerChip(count: session.viewerCount),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(session.avatarUrl),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          session.hostName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    session.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: session.tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveSession {
  const _LiveSession({
    required this.hostName,
    required this.title,
    required this.viewerCount,
    required this.avatarUrl,
    required this.coverImageUrl,
    this.tags = const [],
  });

  final String hostName;
  final String title;
  final int viewerCount;
  final String avatarUrl;
  final String coverImageUrl;
  final List<String> tags;
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55FF416C),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.flash_on, color: Colors.white, size: 14),
          SizedBox(width: 6),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerChip extends StatelessWidget {
  const _ViewerChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            _formatCount(count),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }
}
