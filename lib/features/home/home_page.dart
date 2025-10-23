import 'package:flutter/material.dart';
import '../../core/scaffold_with_nav_bar.dart';
import '../../core/theme.dart';
import 'models/post_model.dart';
import 'widgets/custom_header.dart';
import 'widgets/stories_section_new.dart';
import 'widgets/live_section.dart';
import 'widgets/post_card.dart';
import '../stories/storyverse_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTabIndex = 1; // 0 = Following, 1 = For You
  bool _isStoryExperienceVisible = false;
  StoryVerseStage _storyExperienceStage = StoryVerseStage.capture;
  StoryVerseMode _storyCaptureMode = StoryVerseMode.photo;
  StoryVerseStory? _storyToView;
  ValueNotifier<bool>? _navVisibility;

  // Stories data for the StoryVerse experience
  final List<StoryVerseStory> _stories = [
    StoryVerseStory(
      id: 'story-guy',
      ownerName: 'Guy Hawkins',
      ownerAvatar: 'https://picsum.photos/seed/a/150',
      mood: 'Hyped',
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      hasNewContent: true,
      clips: [
        StoryVerseClip(
          id: 'clip-guy-1',
          mode: StoryVerseMode.video,
          duration: const Duration(seconds: 12),
          mood: 'Hyped',
        ),
      ],
      music: const StoryVerseMusicTrack(
        id: 'track-live',
        title: 'Midnight Crowd',
        artist: 'Analog Pulse',
        artworkUrl:
            'https://images.unsplash.com/photo-1506157786151-b8491531f063',
      ),
    ),
    StoryVerseStory(
      id: 'story-robert',
      ownerName: 'Robert Fox',
      ownerAvatar: 'https://picsum.photos/seed/b/150',
      mood: 'Premiere night',
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 20)),
      hasNewContent: true,
      clips: [
        StoryVerseClip(
          id: 'clip-robert-1',
          mode: StoryVerseMode.photo,
          duration: const Duration(seconds: 8),
          mood: 'Cinematic',
        ),
        StoryVerseClip(
          id: 'clip-robert-2',
          mode: StoryVerseMode.photo,
          duration: const Duration(seconds: 7),
          mood: 'Backstage',
        ),
      ],
    ),
    StoryVerseStory(
      id: 'story-bessie',
      ownerName: 'Bessie Cooper',
      ownerAvatar: 'https://picsum.photos/seed/c/150',
      mood: 'Travel vibes',
      timestamp: DateTime.now().subtract(const Duration(hours: 5, minutes: 15)),
      hasNewContent: false,
      clips: [
        StoryVerseClip(
          id: 'clip-bessie-1',
          mode: StoryVerseMode.photo,
          duration: const Duration(seconds: 6),
          mood: 'Golden hour',
        ),
      ],
    ),
    StoryVerseStory(
      id: 'story-jenny',
      ownerName: 'Jenny Wilson',
      ownerAvatar: 'https://picsum.photos/seed/j/150',
      mood: 'New drop',
      timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      hasNewContent: true,
      clips: [
        StoryVerseClip(
          id: 'clip-jenny-1',
          mode: StoryVerseMode.text,
          duration: const Duration(seconds: 7),
          caption: 'Swipe up for the latest collection',
          mood: 'Bold',
        ),
      ],
    ),
    StoryVerseStory(
      id: 'story-kristin',
      ownerName: 'Kristin Watson',
      ownerAvatar: 'https://picsum.photos/seed/k/150',
      mood: 'Wellness',
      timestamp: DateTime.now().subtract(const Duration(hours: 13)),
      hasNewContent: false,
      clips: [
        StoryVerseClip(
          id: 'clip-kristin-1',
          mode: StoryVerseMode.layout,
          duration: const Duration(seconds: 9),
          mood: 'Calm',
        ),
      ],
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

  void _openStoryCapture(StoryVerseMode mode) {
    setState(() {
      _storyCaptureMode = mode;
      _storyExperienceStage = StoryVerseStage.capture;
      _storyToView = null;
      _isStoryExperienceVisible = true;
    });
    _updateNavVisibility();
  }

  void _openStoryViewer(StoryVerseStory story) {
    setState(() {
      _storyExperienceStage = StoryVerseStage.viewer;
      _storyToView = story;
      _isStoryExperienceVisible = true;
    });
    _updateNavVisibility();
  }

  void _closeStoryExperience() {
    setState(() {
      _isStoryExperienceVisible = false;
      _storyExperienceStage = StoryVerseStage.capture;
      _storyToView = null;
    });
    _updateNavVisibility();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = NavBarVisibilityScope.maybeOf(context);
    if (_navVisibility == notifier) return;
    _navVisibility = notifier;
    _updateNavVisibility();
  }

  void _updateNavVisibility() {
    _navVisibility?.value = !_isStoryExperienceVisible;
  }

  @override
  void dispose() {
    _navVisibility?.value = true;
    super.dispose();
  }

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
      child: Stack(
        children: [
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
                if (_selectedTabIndex == 1)
                  StoriesSection(
                    stories: _stories,
                    hasMyStory:
                        false, // Change to true when user has active story
                    myStoryImageUrl:
                        null, // Set to user's story image when active
                    onStartCapture: _openStoryCapture,
                    onViewStory: _openStoryViewer,
                  ),
                if (_selectedTabIndex == 1) const LiveSection(),
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
                ...currentPosts.map((post) => PostCard(post: post)),
                const SizedBox(height: 100),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isStoryExperienceVisible,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: _isStoryExperienceVisible
                    ? StoryVerseExperience(
                        key: ValueKey(
                          _storyExperienceStage == StoryVerseStage.viewer
                              ? 'viewer-${_storyToView?.id ?? 'none'}'
                              : 'capture-${_storyCaptureMode.name}',
                        ),
                        initialStage: _storyExperienceStage,
                        initialStory:
                            _storyExperienceStage == StoryVerseStage.viewer
                            ? _storyToView
                            : null,
                        feedStories: _stories,
                        showEntryStage: false,
                        initialMode: _storyCaptureMode,
                        onClose: _closeStoryExperience,
                        showInsightsButton:
                            false, // Hide insights for others' stories
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
