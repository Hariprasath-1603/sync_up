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
      height: 200,
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
    // If user has a story, show it with the same style as live button
    if (hasMyStory && imageUrl != null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 130,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kPrimary, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: isDark ? Colors.grey[850] : Colors.grey[200],
                    child: Icon(
                      Icons.person,
                      size: 48,
                      color: isDark
                          ? Colors.white.withOpacity(0.45)
                          : Colors.black.withOpacity(0.32),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Your Story',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If no story, show add button with same style as live + button
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kPrimary, kPrimary.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 12),
            const Text(
              'Add Story',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
      child: Container(
        width: 130,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(18),
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
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                        Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(0.8),
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
                bottom: 12,
                left: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
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
                    const SizedBox(height: 6),
                    Text(
                      story.ownerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                  ],
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
    );
  }
}
