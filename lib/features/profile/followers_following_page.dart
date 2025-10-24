import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme.dart';

class FollowersFollowingPage extends StatefulWidget {
  final int initialTab; // 0 = Followers, 1 = Following

  const FollowersFollowingPage({super.key, this.initialTab = 0});

  @override
  State<FollowersFollowingPage> createState() => _FollowersFollowingPageState();
}

class _FollowersFollowingPageState extends State<FollowersFollowingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample followers data
  final List<Map<String, dynamic>> _followers = [
    {
      'name': 'Sarah Wilson',
      'username': '@sarahwilson',
      'avatarUrl': 'https://i.pravatar.cc/150?img=1',
      'isFollowing': true,
      'isVerified': true,
    },
    {
      'name': 'Mike Johnson',
      'username': '@mikej',
      'avatarUrl': 'https://i.pravatar.cc/150?img=2',
      'isFollowing': false,
      'isVerified': false,
    },
    {
      'name': 'Emma Davis',
      'username': '@emmad',
      'avatarUrl': 'https://i.pravatar.cc/150?img=3',
      'isFollowing': true,
      'isVerified': true,
    },
    {
      'name': 'John Smith',
      'username': '@johnsmith',
      'avatarUrl': 'https://i.pravatar.cc/150?img=4',
      'isFollowing': false,
      'isVerified': false,
    },
    {
      'name': 'Lisa Anderson',
      'username': '@lisaa',
      'avatarUrl': 'https://i.pravatar.cc/150?img=5',
      'isFollowing': true,
      'isVerified': false,
    },
    {
      'name': 'David Brown',
      'username': '@davidb',
      'avatarUrl': 'https://i.pravatar.cc/150?img=6',
      'isFollowing': true,
      'isVerified': true,
    },
    {
      'name': 'Sophie Martinez',
      'username': '@sophiem',
      'avatarUrl': 'https://i.pravatar.cc/150?img=7',
      'isFollowing': false,
      'isVerified': false,
    },
    {
      'name': 'Alex Taylor',
      'username': '@alextaylor',
      'avatarUrl': 'https://i.pravatar.cc/150?img=8',
      'isFollowing': true,
      'isVerified': true,
    },
  ];

  // Sample following data
  final List<Map<String, dynamic>> _following = [
    {
      'name': 'Emma Davis',
      'username': '@emmad',
      'avatarUrl': 'https://i.pravatar.cc/150?img=3',
      'isFollowing': true,
      'isVerified': true,
    },
    {
      'name': 'Sarah Wilson',
      'username': '@sarahwilson',
      'avatarUrl': 'https://i.pravatar.cc/150?img=1',
      'isFollowing': true,
      'isVerified': true,
    },
    {
      'name': 'Lisa Anderson',
      'username': '@lisaa',
      'avatarUrl': 'https://i.pravatar.cc/150?img=5',
      'isFollowing': true,
      'isVerified': false,
    },
    {
      'name': 'David Brown',
      'username': '@davidb',
      'avatarUrl': 'https://i.pravatar.cc/150?img=6',
      'isFollowing': true,
      'isVerified': true,
    },
    {
      'name': 'Alex Taylor',
      'username': '@alextaylor',
      'avatarUrl': 'https://i.pravatar.cc/150?img=8',
      'isFollowing': true,
      'isVerified': true,
    },
  ];

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

  void _toggleFollow(int index, bool isFollowersTab) {
    setState(() {
      if (isFollowersTab) {
        _followers[index]['isFollowing'] = !_followers[index]['isFollowing'];
      } else {
        _following[index]['isFollowing'] = !_following[index]['isFollowing'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0B0E13),
                    const Color(0xFF1A1F2E),
                    kPrimary.withOpacity(0.15),
                  ]
                : [
                    const Color(0xFFF6F7FB),
                    kPrimary.withOpacity(0.08),
                    const Color(0xFFE8ECFF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        final currentUser = auth.currentUser;
                        final name =
                            currentUser?.displayName ??
                            currentUser?.username ??
                            'Profile';
                        return Text(
                          name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Tab Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.08),
                                ]
                              : [
                                  Colors.white.withOpacity(0.9),
                                  Colors.white.withOpacity(0.7),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.white.withOpacity(0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            colors: [kPrimary, kPrimary.withOpacity(0.8)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimary.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: isDark
                            ? Colors.white70
                            : Colors.black54,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                        unselectedLabelStyle: const TextStyle(
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
              const SizedBox(height: 16),
              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUserList(_followers, true, isDark),
                    _buildUserList(_following, false, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(
    List<Map<String, dynamic>> users,
    bool isFollowersTab,
    bool isDark,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        100,
      ), // Added bottom padding for nav bar
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                          ]
                        : [
                            Colors.white.withOpacity(0.9),
                            Colors.white.withOpacity(0.7),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: kPrimary.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(user['avatarUrl']),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and username
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user['name'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (user['isVerified']) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.verified, size: 18, color: kPrimary),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user['username'],
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Follow/Following button
                    _buildFollowButton(
                      user['isFollowing'],
                      () => _toggleFollow(index, isFollowersTab),
                      isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFollowButton(bool isFollowing, VoidCallback onTap, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: isFollowing
                ? null
                : LinearGradient(colors: [kPrimary, kPrimary.withOpacity(0.8)]),
            color: isFollowing
                ? (isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200])
                : null,
            borderRadius: BorderRadius.circular(20),
            border: isFollowing
                ? Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey[400]!,
                    width: 1,
                  )
                : null,
          ),
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            style: TextStyle(
              color: isFollowing
                  ? (isDark ? Colors.white : Colors.black87)
                  : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
