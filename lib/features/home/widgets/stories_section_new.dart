import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../stories/storyverse_page.dart';

class StoriesSection extends StatelessWidget {
  const StoriesSection({
    super.key,
    required this.stories,
    this.hasMyStory = false,
    this.myStoryImageUrl,
    this.onStartCapture,
    this.onViewStory,
  });

  final List<StoryVerseStory> stories;
  final bool hasMyStory;
  final String? myStoryImageUrl;
  final ValueChanged<StoryVerseMode>? onStartCapture;
  final void Function(StoryVerseStory story)? onViewStory;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 160,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: stories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _MyStoryCard(
              isDark: isDark,
              hasMyStory: hasMyStory,
              imageUrl: myStoryImageUrl,
              onTap: () {
                if (hasMyStory) {
                  if (onViewStory != null && stories.isNotEmpty) {
                    onViewStory!(stories.first);
                    return;
                  }
                  if (stories.isNotEmpty) {
                    _openViewerFallback(context, stories.first);
                  }
                } else {
                  if (onStartCapture != null) {
                    onStartCapture!(StoryVerseMode.photo);
                    return;
                  }
                  _openCaptureFallback(context);
                }
              },
            );
          }

          final story = stories[index - 1];
          return _StoryPreviewCard(
            story: story,
            isDark: isDark,
            onTap: () {
              if (onViewStory != null) {
                onViewStory!(story);
                return;
              }
              _openViewerFallback(context, story);
            },
          );
        },
      ),
    );
  }

  void _openCaptureFallback(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => StoryVerseExperience(
          initialStage: StoryVerseStage.capture,
          feedStories: stories,
        ),
      ),
    );
  }

  void _openViewerFallback(BuildContext context, StoryVerseStory story) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => StoryVerseExperience(
          initialStage: StoryVerseStage.viewer,
          initialStory: story,
          feedStories: stories,
        ),
      ),
    );
  }
}

class _MyStoryCard extends StatelessWidget {
  const _MyStoryCard({
    required this.isDark,
    required this.hasMyStory,
    required this.onTap,
    this.imageUrl,
  });

  final bool isDark;
  final bool hasMyStory;
  final VoidCallback onTap;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 120,
        child: Column(
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasMyStory
                      ? kPrimary
                      : colorScheme.outline.withOpacity(isDark ? 0.28 : 0.16),
                  width: hasMyStory ? 2 : 1.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer.withOpacity(
                      isDark ? 0.32 : 0.22,
                    ),
                    colorScheme.primary.withOpacity(isDark ? 0.24 : 0.16),
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null)
                      Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _placeholder(theme, isDark),
                      )
                    else
                      _placeholder(theme, isDark),
                    if (!hasMyStory)
                      Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withOpacity(
                                  isDark ? 0.9 : 0.75,
                                ),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(
                                  isDark ? 0.3 : 0.45,
                                ),
                                blurRadius: 18,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add_to_photos_rounded,
                            color: colorScheme.onPrimary,
                            size: 26,
                          ),
                        ),
                      )
                    else
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Text(
                          'Your Story',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasMyStory ? 'My Story' : 'Add Story',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme, bool isDark) {
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceVariant.withOpacity(isDark ? 0.45 : 0.35),
            colorScheme.surface.withOpacity(isDark ? 0.38 : 0.22),
          ],
        ),
      ),
      child: Icon(
        Icons.person,
        size: 44,
        color: isDark
            ? Colors.white.withOpacity(0.45)
            : Colors.black.withOpacity(0.32),
      ),
    );
  }
}

class _StoryPreviewCard extends StatelessWidget {
  const _StoryPreviewCard({
    required this.story,
    required this.isDark,
    required this.onTap,
  });

  final StoryVerseStory story;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final previewClip = story.clips.isNotEmpty ? story.clips.first : null;
    final moodTag = story.mood.trim();

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: story.hasNewContent
                      ? kPrimary
                      : (isDark
                            ? Colors.white.withOpacity(0.18)
                            : Colors.black.withOpacity(0.08)),
                  width: story.hasNewContent ? 2.4 : 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (previewClip?.imageBytes != null)
                      Image.memory(previewClip!.imageBytes!, fit: BoxFit.cover)
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).colorScheme.surfaceVariant,
                              Theme.of(
                                context,
                              ).colorScheme.surfaceVariant.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.55),
                            Colors.transparent,
                            Colors.black.withOpacity(0.65),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            story.ownerAvatar,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (moodTag.isNotEmpty)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            moodTag,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              story.ownerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_timeAgo(story.timestamp)} • ${story.clips.length} clip${story.clips.length == 1 ? '' : 's'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _timeAgo(DateTime postedAt) {
    final difference = DateTime.now().difference(postedAt);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
