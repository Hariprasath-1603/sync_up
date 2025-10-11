import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'models/post_model.dart';
import 'models/story_model.dart';
import 'widgets/custom_header.dart';
import 'widgets/stories_section_new.dart';
import 'widgets/post_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTabIndex = 1; // 0 = Following, 1 = For You

  // Stories data
  final List<Story> _stories = [
    Story(
      imageUrl: 'https://picsum.photos/seed/1/300/300',
      userName: 'Guy Hawkins',
      userAvatarUrl: 'https://picsum.photos/seed/a/150',
      tag: 'Live',
      viewers: '20.5K',
    ),
    Story(
      imageUrl: 'https://picsum.photos/seed/2/300/300',
      userName: 'Robert Fox',
      userAvatarUrl: 'https://picsum.photos/seed/b/150',
      tag: 'Premiere',
    ),
    Story(
      imageUrl: 'https://picsum.photos/seed/3/300/300',
      userName: 'Bessie Cooper',
      userAvatarUrl: 'https://picsum.photos/seed/c/150',
      tag: 'Live',
      viewers: '34.6K',
    ),
    Story(
      imageUrl: 'https://picsum.photos/seed/10/300/300',
      userName: 'Jenny Wilson',
      userAvatarUrl: 'https://picsum.photos/seed/j/150',
      tag: 'New',
    ),
    Story(
      imageUrl: 'https://picsum.photos/seed/11/300/300',
      userName: 'Kristin Watson',
      userAvatarUrl: 'https://picsum.photos/seed/k/150',
      tag: 'New',
    ),
  ];

  // For You posts (trending/recommended)
  final List<Post> _forYouPosts = [
    Post(
      imageUrl: 'https://picsum.photos/seed/4/600/800',
      userName: 'Savannah Nguyen',
      userHandle: '@savannah',
      userAvatarUrl: 'https://picsum.photos/seed/d/150',
      likes: '120K',
      comments: '96K',
      shares: '36K',
    ),
    Post(
      imageUrl: 'https://picsum.photos/seed/5/600/800',
      userName: 'Brooklyn Simmons',
      userHandle: '@brooklyn.sim007',
      userAvatarUrl: 'https://picsum.photos/seed/e/150',
      likes: '110K',
      comments: '88K',
      shares: '21K',
    ),
    Post(
      imageUrl: 'https://picsum.photos/seed/6/600/800',
      userName: 'Wade Warren',
      userHandle: '@wade_w',
      userAvatarUrl: 'https://picsum.photos/seed/f/150',
      likes: '95K',
      comments: '72K',
      shares: '18K',
    ),
    Post(
      imageUrl: 'https://picsum.photos/seed/7/600/800',
      userName: 'Eleanor Pena',
      userHandle: '@eleanor.p',
      userAvatarUrl: 'https://picsum.photos/seed/g/150',
      likes: '88K',
      comments: '65K',
      shares: '15K',
    ),
    Post(
      imageUrl: 'https://picsum.photos/seed/8/600/800',
      userName: 'Cameron Williamson',
      userHandle: '@cam_will',
      userAvatarUrl: 'https://picsum.photos/seed/h/150',
      likes: '156K',
      comments: '120K',
      shares: '45K',
    ),
  ];

  // Following posts (people you follow)
  final List<Post> _followingPosts = [
    Post(
      imageUrl: 'https://picsum.photos/seed/follow1/600/800',
      userName: 'John Doe',
      userHandle: '@johndoe',
      userAvatarUrl: 'https://picsum.photos/seed/user1/150',
      likes: '45K',
      comments: '32K',
      shares: '12K',
    ),
    Post(
      imageUrl: 'https://picsum.photos/seed/follow2/600/800',
      userName: 'Jane Smith',
      userHandle: '@janesmith',
      userAvatarUrl: 'https://picsum.photos/seed/user2/150',
      likes: '67K',
      comments: '48K',
      shares: '19K',
    ),
    Post(
      imageUrl: 'https://picsum.photos/seed/follow3/600/800',
      userName: 'Mike Johnson',
      userHandle: '@mikej',
      userAvatarUrl: 'https://picsum.photos/seed/user3/150',
      likes: '52K',
      comments: '38K',
      shares: '15K',
    ),
    Post(
      imageUrl: 'https://picsum.photos/seed/follow4/600/800',
      userName: 'Sarah Williams',
      userHandle: '@sarah_w',
      userAvatarUrl: 'https://picsum.photos/seed/user4/150',
      likes: '78K',
      comments: '56K',
      shares: '23K',
    ),
    Post(
      imageUrl: 'https://picsum.photos/seed/follow5/600/800',
      userName: 'David Brown',
      userHandle: '@david.brown',
      userAvatarUrl: 'https://picsum.photos/seed/user5/150',
      likes: '91K',
      comments: '68K',
      shares: '28K',
    ),
    Post(
      imageUrl: 'https://picsum.photos/seed/follow6/600/800',
      userName: 'Emily Davis',
      userHandle: '@emily_d',
      userAvatarUrl: 'https://picsum.photos/seed/user6/150',
      likes: '63K',
      comments: '45K',
      shares: '17K',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get current posts based on selected tab
    final currentPosts = _selectedTabIndex == 0
        ? _followingPosts
        : _forYouPosts;
    final sectionTitle = _selectedTabIndex == 0
        ? 'Latest from Following'
        : 'Trending';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF0B0E13),
                  const Color(0xFF1A1F2E),
                  kPrimary.withOpacity(0.1),
                ]
              : [
                  const Color(0xFFF6F7FB),
                  const Color(0xFFFFFFFF),
                  kPrimary.withOpacity(0.05),
                ],
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CustomHeader(
              selectedIndex: _selectedTabIndex,
              onTabSelected: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
            ),
            // Stories section - show only on For You tab with "My Story" feature
            if (_selectedTabIndex == 1)
              StoriesSection(
                stories: _stories,
                hasMyStory: false, // Change to true when user has active story
                myStoryImageUrl: null, // Set to user's story image when active
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                sectionTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            ...currentPosts.map((post) => PostCard(post: post)).toList(),
            const SizedBox(height: 100), // Space for floating nav bar
          ],
        ),
      ),
    );
  }
}
