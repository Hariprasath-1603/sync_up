import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/follow_service.dart';
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
  final FollowService _followService = FollowService();

  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _following = [];
  bool _isLoadingFollowers = false;
  bool _isLoadingFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUserId;

    if (currentUserId == null) return;

    setState(() {
      _isLoadingFollowers = true;
      _isLoadingFollowing = true;
    });

    // Load followers and following concurrently
    final results = await Future.wait([
      _followService.getFollowers(currentUserId),
      _followService.getFollowing(currentUserId),
    ]);

    if (mounted) {
      setState(() {
        _followers = results[0];
        _following = results[1];
        _isLoadingFollowers = false;
        _isLoadingFollowing = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleFollow(
    String targetUserId,
    bool isCurrentlyFollowing,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUserId;

    if (currentUserId == null) return;

    if (isCurrentlyFollowing) {
      await _followService.unfollowUser(currentUserId, targetUserId);
    } else {
      await _followService.followUser(currentUserId, targetUserId);
    }

    // Reload data to reflect changes
    _loadData();
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
                    _isLoadingFollowers
                        ? const Center(child: CircularProgressIndicator())
                        : _buildUserList(_followers, true, isDark),
                    _isLoadingFollowing
                        ? const Center(child: CircularProgressIndicator())
                        : _buildUserList(_following, false, isDark),
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
                    _buildFollowButton(user['isFollowing'] ?? false, () {
                      final userId = user['uid'] as String?;
                      if (userId != null) {
                        _toggleFollow(userId, user['isFollowing'] ?? false);
                      }
                    }, isDark),
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
