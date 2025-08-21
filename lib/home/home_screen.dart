import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../auth/auth.dart'; // Import your consolidated auth file
import 'dart:async'; // For the auto-scrolling carousel
import 'dart:ui'; // For the BackdropFilter (glass effect)

// Data Models for the new UI
class Story {
  final String imageUrl;
  final String username;
  final bool isLive;

  Story({required this.imageUrl, required this.username, this.isLive = false});
}

class LiveSession {
  final String imageUrl;
  final String title;
  final String description;
  final String category;

  LiveSession({required this.imageUrl, required this.title, required this.description, required this.category});
}

class UserPost {
  final String imageUrl;
  final String name;
  final bool isLive;

  UserPost({required this.imageUrl, required this.name, required this.isLive});
}

class Reel {
  final String videoUrl;
  final String username;
  final String userImageUrl;
  final String caption;
  final String likes;
  final String comments;

  Reel({
    required this.videoUrl,
    required this.username,
    required this.userImageUrl,
    required this.caption,
    required this.likes,
    required this.comments,
  });
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _carouselController = PageController();
  Timer? _carouselTimer;
  int _selectedCategoryIndex = 0;

  // Mock Data inspired by the design
  final List<Story> _stories = [
    Story(imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=1974&auto=format&fit=crop', username: 'Your Story'),
    Story(imageUrl: 'https://images.unsplash.com/photo-1527980965255-d3b416303d12?q=80&w=1980&auto=format&fit=crop', username: 'Terry', isLive: true),
    Story(imageUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?q=80&w=1961&auto=format&fit=crop', username: 'Rose Kelly'),
    Story(imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=1976&auto=format&fit=crop', username: 'Alice Bree'),
    Story(imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=1974&auto=format&fit=crop', username: 'Terry'),
  ];

  final List<LiveSession> _liveSessions = [
    LiveSession(imageUrl: 'https://images.unsplash.com/photo-1522881193457-31ae74c30752?q=80&w=2070&auto=format&fit=crop', title: 'Dog lovers unite', description: 'Dog lovers unite to celebrate...', category: 'Animals'),
    LiveSession(imageUrl: 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?q=80&w=2070&auto=format&fit=crop', title: 'Gaming Session', description: 'Exclusive live gaming event...', category: 'Gaming'),
    LiveSession(imageUrl: 'https://images.unsplash.com/photo-1505238680356-667803448bb6?q=80&w=2070&auto=format&fit=crop', title: 'Travel Talk', description: 'Join our talk about travels...', category: 'Travel'),
  ];

  final List<UserPost> _userPosts = [
    UserPost(imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=1964&auto=format&fit=crop', name: 'Rose Kelly', isLive: true),
    UserPost(imageUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=1974&auto=format&fit=crop', name: 'Alice Bree', isLive: true),
    UserPost(imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=1974&auto=format&fit=crop', name: 'John Doe', isLive: false),
    UserPost(imageUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=2070&auto=format&fit=crop', name: 'Jane Smith', isLive: false),
  ];

  final List<Reel> _reels = [
    Reel(
      videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-woman-posing-for-a-photo-shoot-in-a-studio-32303-large.mp4',
      username: 'Fashionista',
      userImageUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?q=80&w=1961&auto=format&fit=crop',
      caption: 'New collection drop!',
      likes: '15.2k',
      comments: '1.1k',
    ),
    Reel(
      videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-a-man-in-a-suit-works-on-a-laptop-4230-large.mp4',
      username: 'Tech Guru',
      userImageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=1974&auto=format&fit=crop',
      caption: 'My new setup is finally complete!',
      likes: '22.8k',
      comments: '2.3k',
    ),
  ];

  final List<String> _categories = ['Popular', 'Tech', 'Health', 'Gym', 'Comics', 'Cartoon', 'Anime', 'Gaming', 'Music'];


  @override
  void initState() {
    super.initState();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_carouselController.hasClients) {
        int nextPage = _carouselController.page!.round() + 1;
        if (nextPage >= _liveSessions.length) {
          nextPage = 0;
        }
        _carouselController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? Colors.black : const Color(0xFFF4F4F4);
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(textColor),
      body: Stack(
        children: [
          _buildBody(textColor, secondaryTextColor, cardColor),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavigationBar(isDarkMode),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(Color iconColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.menu, color: iconColor, size: 30),
        onPressed: () {},
      ),
      title: Text(
        'SyncUp',
        style: TextStyle(
          color: iconColor,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: iconColor, size: 30),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(FirebaseAuth.instance.currentUser?.photoURL ?? 'https://picsum.photos/id/1005/100/100'),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(Color textColor, Color? secondaryTextColor, Color cardColor) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      children: [
        _buildStoriesSection(textColor),
        _buildSectionHeader('Live Now', textColor, secondaryTextColor),
        _buildHorizontalList(_liveSessions.map((session) => LiveSessionCard(session: session)).toList()),
        _buildSectionHeader('Popular Reels', textColor, secondaryTextColor),
        _buildHorizontalList(_reels.map((reel) => ReelCard(reel: reel)).toList()),
        _buildSectionHeader('Recent Posts', textColor, secondaryTextColor),
        _buildHorizontalList(_userPosts.map((post) => PostCard(post: post)).toList()),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color textColor, Color? secondaryTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
          Text('View All', style: TextStyle(color: secondaryTextColor, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildHorizontalList(List<Widget> items) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return items[index];
        },
      ),
    );
  }


  Widget _buildStoriesSection(Color textColor) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _stories.length,
        itemBuilder: (context, index) {
          final story = _stories[index];
          return _buildStoryAvatar(story, textColor);
        },
      ),
    );
  }

  Widget _buildStoryAvatar(Story story, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: story.isLive ? Colors.red : Colors.grey[300],
              ),
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(story.imageUrl),
              ),
              if (story.isLive)
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            story.username,
            style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(bool isDarkMode) {
    final navBarItems = [
      Icons.home_filled,
      Icons.explore_outlined,
      Icons.add,
      Icons.notifications_none,
      Icons.person_outline,
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / navBarItems.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      left: _selectedIndex * itemWidth,
                      top: 0,
                      height: 70,
                      width: itemWidth,
                      child: Center(
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Colors.blue, Colors.lightBlueAccent],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(navBarItems.length, (index) {
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _onItemTapped(index),
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: Icon(
                                navBarItems[index],
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Reusable Cards for different content types

class LiveSessionCard extends StatelessWidget {
  final LiveSession session;
  const LiveSessionCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(session.imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 15,
              right: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            Positioned(
              bottom: 15,
              left: 15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(session.description, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final UserPost post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(post.imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.center,
          ),
        ),
        child: Stack(
          children: [
            if (post.isLive)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ),
            Positioned(
              bottom: 10,
              left: 10,
              child: Text(post.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class ReelCard extends StatelessWidget {
  final Reel reel;
  const ReelCard({super.key, required this.reel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black,
        image: DecorationImage(
          image: NetworkImage(reel.userImageUrl), // Using user image as a placeholder background
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(reel.userImageUrl),
                ),
                const SizedBox(height: 8),
                Text(reel.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(reel.likes, style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
