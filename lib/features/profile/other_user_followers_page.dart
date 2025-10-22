import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class OtherUserFollowersPage extends StatefulWidget {
  final String username;
  final String userId;
  final int initialTab; // 0 = Followers, 1 = Following

  const OtherUserFollowersPage({
    super.key,
    required this.username,
    required this.userId,
    this.initialTab = 0,
  });

  @override
  State<OtherUserFollowersPage> createState() => _OtherUserFollowersPageState();
}

class _OtherUserFollowersPageState extends State<OtherUserFollowersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data for followers
  final List<Map<String, dynamic>> _followers = List.generate(
    25,
    (index) => {
      'name': 'Follower ${index + 1}',
      'username': '@follower${index + 1}',
      'avatar': 'https://i.pravatar.cc/150?img=${index + 1}',
      'isFollowing': index % 3 == 0,
    },
  );

  // Mock data for following
  final List<Map<String, dynamic>> _following = List.generate(
    15,
    (index) => {
      'name': 'User ${index + 1}',
      'username': '@user${index + 1}',
      'avatar': 'https://i.pravatar.cc/150?img=${index + 20}',
      'isFollowing': true,
    },
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kDarkBackground : kLightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? kDarkBackground : kLightBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.username,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(
                    0.05,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(
                      0.1,
                    ),
                    width: 1.5,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: kPrimary,
                  unselectedLabelColor: isDark ? Colors.white60 : Colors.grey,
                  indicatorColor: kPrimary,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  tabs: [
                    Tab(text: '${_followers.length} Followers'),
                    Tab(text: '${_following.length} Following'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(_followers, isDark),
          _buildUserList(_following, isDark),
        ],
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserItem(user, isDark);
      },
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        kPrimary.withOpacity(0.8),
                        kPrimary.withOpacity(0.4),
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(user['avatar']),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'],
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        user['username'],
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildFollowButton(user, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFollowButton(Map<String, dynamic> user, bool isDark) {
    final isFollowing = user['isFollowing'] as bool;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: isFollowing
                ? null
                : LinearGradient(colors: [kPrimary.withOpacity(0.8), kPrimary]),
            color: isFollowing
                ? (isDark ? Colors.white : Colors.black).withOpacity(0.1)
                : null,
            borderRadius: BorderRadius.circular(12),
            border: isFollowing
                ? Border.all(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(
                      0.2,
                    ),
                    width: 1.5,
                  )
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  user['isFollowing'] = !isFollowing;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    color: isFollowing
                        ? (isDark ? Colors.white : Colors.black87)
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
