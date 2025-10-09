import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({Key? key}) : super(key: key);

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _posts = List.generate(
    8,
        (index) => 'https://picsum.photos/seed/post$index/400/600',
  );
  final List<String> _media = List.generate(
    6,
        (index) => 'https://picsum.photos/seed/media$index/600/400',
  );

  final List<Map<String, String?>> _stories = [
    {'title': 'Add', 'url': null},
    {'title': 'Travel', 'url': 'https://picsum.photos/seed/s1/200'},
    {'title': 'Food', 'url': 'https://picsum.photos/seed/s2/200'},
    {'title': 'Friends', 'url': 'https://picsum.photos/seed/s3/200'},
    {'title': 'Hangout', 'url': 'https://picsum.photos/seed/s4/200'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coverHeight = MediaQuery.of(context).size.height * 0.22;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: coverHeight + 56,
                pinned: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                // The 'leading' property (back button) has been removed.
                actions: [_iconCircle(Icons.more_horiz, isDark, () {})],
                flexibleSpace: _buildHeader(context, coverHeight, isDark),
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.only(top: 56),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      _buildStatsAndBio(context),
                      const SizedBox(height: 20),
                      _buildStories(context),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: isDark ? Colors.white : Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).primaryColor,
                    indicatorWeight: 3,
                    tabs: const [Tab(text: 'Posts'), Tab(text: 'Media')],
                  ),
                ),
                pinned: true,
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPostGrid(_posts),
                    _buildPostGrid(_media),
                  ],
                ),
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double coverHeight, bool isDark) {
    const coverUrl = 'https://picsum.photos/seed/cover/1200/400';
    const avatarUrl = 'https://i.pravatar.cc/300?img=13';

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: coverHeight,
            decoration: const BoxDecoration(
              image: DecorationImage(fit: BoxFit.cover, image: NetworkImage(coverUrl)),
            ),
          ),
        ),
        // The Positioned widget for the back button has been removed.
        Positioned(
          top: coverHeight - 50,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(radius: 46, backgroundImage: NetworkImage(avatarUrl)),
          ),
        ),
      ],
    );
  }

  Widget _iconCircle(IconData icon, bool isDark, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        backgroundColor: isDark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.9),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: isDark ? Colors.white : Colors.black87, size: 20),
        ),
      ),
    );
  }

  Widget _buildStatsAndBio(BuildContext context) {
    return Column(
      children: [
        const Text('Jane Cooper', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Apple CEO, Auburn buke, National parks', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 8),
        Text('bio.link.io/j.copr', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14)),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text('Edit Profile', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('103', 'Posts'),
            _buildStatItem('870', 'Following'),
            _buildStatItem('120k', 'Followers'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStories(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Stories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () {}, child: const Text('View all')),
            ],
          ),
        ),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _stories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final s = _stories[index];
              return Column(
                children: [
                  s['url'] == null
                      ? Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Center(child: Icon(Icons.add)),
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(s['url']!, width: 64, height: 64, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 6),
                  Text(s['title']!, style: const TextStyle(fontSize: 12)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPostGrid(List<String> images) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(images[index], fit: BoxFit.cover),
        );
      },
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }
  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32.5),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 65,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.35),
                borderRadius: BorderRadius.circular(32.5),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(icon: const Icon(Icons.home_outlined, color: Colors.grey), onPressed: () => context.go('/home')),
                  IconButton(icon: const Icon(Icons.blur_circular_outlined, color: Colors.grey), onPressed: () {}),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      height: 50, width: 50,
                      decoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey), onPressed: () {}),
                  // This icon is now active
                  IconButton(icon: Icon(Icons.person, color: theme.primaryColor), onPressed: () => context.go('/profile')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}