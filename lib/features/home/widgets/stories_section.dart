import 'package:flutter/material.dart';
import '../models/story_model.dart';

class StoriesSection extends StatelessWidget {
  final List<Story> stories;
  const StoriesSection({super.key, required this.stories});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Stories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              return _StoryCard(story: stories[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _StoryCard extends StatelessWidget {
  final Story story;
  const _StoryCard({required this.story});

  @override
  Widget build(BuildContext context) {
    final bool isLive = story.tag == 'Live';
    // Get the app's theme
    final theme = Theme.of(context);

    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(story.imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Dark overlay for better text readability
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          // Top Left Tag
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                // Use the theme's primary color instead of Colors.amber
                color: isLive ? Colors.black : theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                story.tag,
                style: TextStyle(
                  color: isLive ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          // Top Right Viewers (only for Live)
          if (isLive)
            Positioned(
              top: 8,
              right: 8,
              child: Text(
                story.viewers!,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          // Bottom Left User Info
          Positioned(
            bottom: 8,
            left: 8,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(story.userAvatarUrl),
                ),
                const SizedBox(width: 8),
                Text(
                  story.userName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}