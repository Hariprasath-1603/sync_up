import 'package:flutter/material.dart';
import 'models/post_model.dart';
import 'models/story_model.dart';
import 'widgets/custom_header.dart';
import 'widgets/stories_section.dart';
import 'widgets/post_card.dart';
import 'widgets/custom_bottom_nav_bar.dart'; // Import the new floating bar

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTabIndex = 1;

  // ... (Your dummy data remains the same)
  final List<Story> _stories = [
    Story(
        imageUrl: 'https://picsum.photos/seed/1/300/400',
        userName: 'Guy Hawkins',
        userAvatarUrl: 'https://picsum.photos/seed/a/150',
        tag: 'Live',
        viewers: '20.5K'),
    Story(
        imageUrl: 'https://picsum.photos/seed/2/300/400',
        userName: 'Robert Fox',
        userAvatarUrl: 'https://picsum.photos/seed/b/150',
        tag: 'Premiere'),
    Story(
        imageUrl: 'https://picsum.photos/seed/3/300/400',
        userName: 'Bessie Cooper',
        userAvatarUrl: 'https://picsum.photos/seed/c/150',
        tag: 'Live',
        viewers: '34.6K'),
  ];

  final List<Post> _posts = [
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
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // The body is now a Stack to layer the content and the nav bar
      body: Stack(
        children: [
          // The main scrollable content
          SafeArea(
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
                StoriesSection(stories: _stories),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Trending', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                ..._posts.map((post) => PostCard(post: post)).toList(),
                // Add padding at the bottom so content doesn't hide behind the nav bar
                const SizedBox(height: 100),
              ],
            ),
          ),
          // The new floating navigation bar is placed here, on top of the ListView
          const FloatingNavBar(),
        ],
      ),
    );
  }
}