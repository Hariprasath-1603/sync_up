import 'package:flutter/material.dart';

class StorySummary {
  final String userId;
  final String username;
  final String? avatarUrl;
  final bool isVerified;
  final String? thumbnailUrl;
  final bool hasNewStory;
  final int storyCount;
  final DateTime? latestStoryTime;

  StorySummary({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.isVerified = false,
    this.thumbnailUrl,
    this.hasNewStory = true,
    this.storyCount = 0,
    this.latestStoryTime,
  });
}

class StoryBar extends StatelessWidget {
  final String currentUserId;
  final String currentUsername;
  final String? currentUserAvatar;
  final bool hasYourStory;
  final List<StorySummary> friendStories;
  final VoidCallback onAddStory;
  final Function(String userId) onViewStory;

  const StoryBar({
    super.key,
    required this.currentUserId,
    required this.currentUsername,
    this.currentUserAvatar,
    this.hasYourStory = false,
    required this.friendStories,
    required this.onAddStory,
    required this.onViewStory,
  });

  Color _getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0F1419)
        : const Color(0xFFF8F9FA);
  }

  Color _getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1D24)
        : Colors.white;
  }

  Color _getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: _getBackgroundColor(context),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        itemCount: 1 + friendStories.length, // Your story + friends
        itemBuilder: (context, index) {
          if (index == 0) {
            // Your Story tile
            return _buildYourStoryTile(context);
          } else {
            // Friends' stories
            final story = friendStories[index - 1];
            return _buildStoryTile(
              context,
              story: story,
              onTap: () => onViewStory(story.userId),
            );
          }
        },
      ),
    );
  }

  Widget _buildYourStoryTile(BuildContext context) {
    return GestureDetector(
      onTap: hasYourStory
          ? () => onViewStory(currentUserId)
          : onAddStory,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Stack(
              children: [
                // Avatar with ring
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasYourStory
                        ? const LinearGradient(
                            colors: [
                              Color(0xFF4A6CF7),
                              Color(0xFF9D50BB),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: !hasYourStory
                        ? Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            width: 2,
                          )
                        : null,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getCardColor(context),
                      border: Border.all(
                        color: _getCardColor(context),
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: currentUserAvatar != null
                          ? Image.network(
                              currentUserAvatar!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildAvatarPlaceholder(context);
                              },
                            )
                          : _buildAvatarPlaceholder(context),
                    ),
                  ),
                ),
                // Plus icon for "Add Story"
                if (!hasYourStory)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A6CF7),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getCardColor(context),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              hasYourStory ? 'Your Story' : 'Add Story',
              style: TextStyle(
                color: _getTextColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryTile(
    BuildContext context, {
    required StorySummary story,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Stack(
              children: [
                // Avatar with gradient ring
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: story.hasNewStory
                        ? const LinearGradient(
                            colors: [
                              Color(0xFF4A6CF7),
                              Color(0xFF9D50BB),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              Colors.grey.withOpacity(0.3),
                              Colors.grey.withOpacity(0.3),
                            ],
                          ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getCardColor(context),
                      border: Border.all(
                        color: _getCardColor(context),
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: story.thumbnailUrl != null
                          ? Image.network(
                              story.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildNameAvatar(context, story.username);
                              },
                            )
                          : story.avatarUrl != null
                              ? Image.network(
                                  story.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildNameAvatar(context, story.username);
                                  },
                                )
                              : _buildNameAvatar(context, story.username),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    story.username,
                    style: TextStyle(
                      color: _getTextColor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (story.isVerified) ...[
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.verified,
                    color: Color(0xFF4A6CF7),
                    size: 12,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildNameAvatar(BuildContext context, String name) {
    return Container(
      color: const Color(0xFF4A6CF7),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
