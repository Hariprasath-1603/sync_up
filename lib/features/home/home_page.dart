import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/providers/post_provider.dart';
import 'models/post_model.dart';
import 'widgets/custom_header.dart';
import 'widgets/live_section.dart';
import 'widgets/post_card.dart';
import '../stories/widgets/dynamic_story_row.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTabIndex = 1; // 0 = Following, 1 = For You

  @override
  void initState() {
    super.initState();
    // Load posts when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final postProvider = context.read<PostProvider>();
      postProvider.loadForYouPosts();
      postProvider.loadFollowingPosts();
    });
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final postProvider = context.watch<PostProvider>();

    // Get current posts based on selected tab
    final currentPosts = _selectedTabIndex == 0
        ? postProvider.followingPosts
        : postProvider.forYouPosts;

    final isLoading = _selectedTabIndex == 0
        ? postProvider.isLoadingFollowing
        : postProvider.isLoadingForYou;

    final sectionTitle = _selectedTabIndex == 0
        ? 'Latest from Following'
        : 'Trending';

    // Use real posts from database only
    final postsToDisplay = _convertToHomePosts(currentPosts);

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
            child: RefreshIndicator(
              onRefresh: () async {
                if (_selectedTabIndex == 0) {
                  postProvider.loadFollowingPosts();
                } else {
                  postProvider.loadForYouPosts();
                }
                // Wait a bit for the stream to update
                await Future.delayed(const Duration(milliseconds: 500));
              },
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
                  // Stories Section with heading
                  if (_selectedTabIndex == 1) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Stories',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const DynamicStoryRow(),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sectionTitle,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isLoading && currentPosts.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (postsToDisplay.isEmpty)
                    _buildEmptyState(isDark)
                  else
                    ...postsToDisplay.asMap().entries.map((entry) {
                      final index = entry.key;
                      final post = entry.value;

                      // Insert Live Section after 2nd post
                      if (index == 1) {
                        return Column(
                          children: [
                            PostCard(post: post),
                            const LiveSection(),
                          ],
                        );
                      }

                      return PostCard(post: post);
                    }),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedTabIndex == 0
                  ? 'No posts from people you follow yet.\nStart following users to see their posts!'
                  : 'No posts available yet.\nCreate your first post!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to create post
                // You can implement this navigation
              },
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Create Post'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Post> _convertToHomePosts(List<dynamic> dynamicPosts) {
    return dynamicPosts.map((dynamicPost) {
      return Post(
        id: dynamicPost.id,
        userId: dynamicPost.userId,
        imageUrl: dynamicPost.thumbnailUrl,
        userName: dynamicPost.username,
        userHandle: '@${dynamicPost.username.toLowerCase()}',
        userAvatarUrl: dynamicPost.userAvatar,
        likes: _formatCount(dynamicPost.likes),
        comments: _formatCount(dynamicPost.comments),
        shares: _formatCount(dynamicPost.shares),
      );
    }).toList();
  }
}
