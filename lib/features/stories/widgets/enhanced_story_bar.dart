import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme.dart';
import '../models/story_model.dart';

/// Enhanced Stories Bar with gradient rings and smooth animations
/// Follows app theme and design system
class EnhancedStoryBar extends StatelessWidget {
  const EnhancedStoryBar({
    super.key,
    required this.stories,
    required this.currentUserId,
    this.currentUserPhotoUrl,
    this.currentUsername,
    this.hasMyStory = false,
    this.onAddStory,
    this.onViewStory,
    this.onViewMyStory,
  });

  final List<StoryItem> stories;
  final String currentUserId;
  final String? currentUserPhotoUrl;
  final String? currentUsername;
  final bool hasMyStory;
  final VoidCallback? onAddStory;
  final Function(StoryItem story)? onViewStory;
  final VoidCallback? onViewMyStory;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 105,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: stories.length + 1, // +1 for "Add Story" button
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          // First item is always the "Add Story" button
          if (index == 0) {
            return _AddStoryButton(
              isDark: isDark,
              photoUrl: currentUserPhotoUrl,
              username: currentUsername ?? 'Your Story',
              hasStory: hasMyStory,
              onTap: hasMyStory ? onViewMyStory : onAddStory,
            );
          }

          // Other items are friends' stories
          final story = stories[index - 1];
          return _StoryAvatar(
            story: story,
            isDark: isDark,
            onTap: () => onViewStory?.call(story),
          );
        },
      ),
    );
  }
}

/// Add Story Button (first item in stories bar)
class _AddStoryButton extends StatelessWidget {
  const _AddStoryButton({
    required this.isDark,
    required this.photoUrl,
    required this.username,
    required this.hasStory,
    this.onTap,
  });

  final bool isDark;
  final String? photoUrl;
  final String username;
  final bool hasStory;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Avatar with gradient border if has story
              Container(
                width: 70,
                height: 70,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasStory
                      ? LinearGradient(
                          colors: [kPrimary, kPrimary.withOpacity(0.6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: hasStory
                      ? null
                      : (isDark ? Colors.grey[800] : Colors.grey[300]),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? kDarkBackground : kLightBackground,
                  ),
                  child: ClipOval(
                    child: photoUrl != null && photoUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: photoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: isDark
                                  ? Colors.grey[850]
                                  : Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    kPrimary,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: isDark
                                  ? Colors.grey[850]
                                  : Colors.grey[200],
                              child: Icon(
                                Icons.person,
                                size: 32,
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey[400],
                              ),
                            ),
                          )
                        : Container(
                            color: isDark ? Colors.grey[850] : Colors.grey[200],
                            child: Icon(
                              Icons.person,
                              size: 32,
                              color: isDark ? Colors.white24 : Colors.grey[400],
                            ),
                          ),
                  ),
                ),
              ),
              // Plus icon badge (only if no story)
              if (!hasStory)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: kPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? kDarkBackground : kLightBackground,
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              hasStory ? 'Your Story' : 'Add Story',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Story Avatar (for other users' stories)
class _StoryAvatar extends StatelessWidget {
  const _StoryAvatar({
    required this.story,
    required this.isDark,
    required this.onTap,
  });

  final StoryItem story;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar with gradient border
          Container(
            width: 70,
            height: 70,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: story.isViewed
                  ? null
                  : LinearGradient(
                      colors: [kPrimary, kPrimary.withOpacity(0.5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: story.isViewed
                  ? (isDark ? Colors.grey[800] : Colors.grey[300])
                  : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? kDarkBackground : kLightBackground,
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: story.userPhotoUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDark ? Colors.grey[850] : Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isDark ? Colors.grey[850] : Colors.grey[200],
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: isDark ? Colors.white24 : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              story.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
