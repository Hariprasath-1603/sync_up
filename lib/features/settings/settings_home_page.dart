// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'pages/account_page.dart';
import 'pages/privacy_security_page.dart';
import 'pages/notifications_page.dart';
import 'pages/appearance_page.dart';
import 'pages/data_storage_page.dart';
import 'pages/chats_messaging_page.dart';
import 'pages/connected_apps_page.dart';
import 'pages/ai_personalization_page.dart';
import 'pages/help_support_page.dart';
import 'pages/about_app_page.dart';

class SettingsHomePage extends StatefulWidget {
  const SettingsHomePage({super.key});

  @override
  State<SettingsHomePage> createState() => _SettingsHomePageState();
}

class _SettingsHomePageState extends State<SettingsHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isSearchFocused = false;

  final List<String> _popularSearches = [
    'dark mode',
    'notifications',
    'password',
    'privacy',
    'storage',
    'blocked',
    'theme',
    'two factor',
  ];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _settingsOptions = [
    {
      'icon': Icons.person_outline,
      'title': 'Account',
      'subtitle': 'Edit profile, password, verification',
      'color': const Color(0xFF4CAF50),
      'page': const AccountPage(),
      'keywords': [
        'profile',
        'username',
        'bio',
        'password',
        'email',
        'phone',
        'verification',
        '2fa',
        'two factor',
        'security',
        'login',
        'delete account',
        'deactivate',
      ],
    },
    {
      'icon': Icons.shield_outlined,
      'title': 'Privacy & Security',
      'subtitle': 'Blocked accounts, activity status',
      'color': const Color(0xFF2196F3),
      'page': const PrivacySecurityPage(),
      'keywords': [
        'privacy',
        'blocked',
        'muted',
        'restricted',
        'activity status',
        'story privacy',
        'post visibility',
        'download data',
        'login alerts',
      ],
    },
    {
      'icon': Icons.notifications_outlined,
      'title': 'Notifications',
      'subtitle': 'Manage push, email, and sound alerts',
      'color': const Color(0xFFFF9800),
      'page': const NotificationsPage(),
      'keywords': [
        'notifications',
        'push',
        'alerts',
        'email',
        'sound',
        'vibration',
        'likes',
        'comments',
        'followers',
        'messages',
      ],
    },
    {
      'icon': Icons.palette_outlined,
      'title': 'Appearance & Display',
      'subtitle': 'Theme, colors, font, language',
      'color': const Color(0xFF9C27B0),
      'page': const AppearancePage(),
      'keywords': [
        'theme',
        'dark mode',
        'light mode',
        'colors',
        'accent',
        'font',
        'text size',
        'language',
        'animations',
        'auto-play',
      ],
    },
    {
      'icon': Icons.storage_outlined,
      'title': 'Data & Storage',
      'subtitle': 'Cache, downloads, network usage',
      'color': const Color(0xFF00BCD4),
      'page': const DataStoragePage(),
      'keywords': [
        'storage',
        'cache',
        'downloads',
        'data usage',
        'network',
        'wifi',
        'data saver',
        'clear cache',
      ],
    },
    {
      'icon': Icons.chat_bubble_outline,
      'title': 'Chats & Messaging',
      'subtitle': 'Message requests, read receipts',
      'color': const Color(0xFF3F51B5),
      'page': const ChatsMessagingPage(),
      'keywords': [
        'chat',
        'messaging',
        'messages',
        'read receipts',
        'typing',
        'auto-delete',
        'wallpaper',
        'archive',
      ],
    },
    {
      'icon': Icons.devices_outlined,
      'title': 'Connected Apps & Devices',
      'subtitle': 'Linked accounts, device management',
      'color': const Color(0xFF607D8B),
      'page': const ConnectedAppsPage(),
      'keywords': [
        'devices',
        'connected',
        'linked accounts',
        'facebook',
        'google',
        'apple',
        'third-party',
        'qr code',
      ],
    },
    {
      'icon': Icons.psychology_outlined,
      'title': 'AI & Personalization',
      'subtitle': 'Feed preferences, smart features',
      'color': const Color(0xFFE91E63),
      'page': const AIPersonalizationPage(),
      'keywords': [
        'ai',
        'personalization',
        'feed',
        'recommendations',
        'smart features',
        'captions',
        'algorithm',
        'ads',
        'interests',
      ],
    },
    {
      'icon': Icons.help_outline,
      'title': 'Help & Support',
      'subtitle': 'FAQs, tutorials, contact support',
      'color': const Color(0xFF795548),
      'page': const HelpSupportPage(),
      'keywords': [
        'help',
        'support',
        'faq',
        'tutorials',
        'contact',
        'report problem',
        'bug',
        'guidelines',
      ],
    },
    {
      'icon': Icons.info_outline,
      'title': 'About & App Info',
      'subtitle': 'Version, licenses, terms',
      'color': const Color(0xFF9E9E9E),
      'page': const AboutAppPage(),
      'keywords': [
        'about',
        'version',
        'developer',
        'licenses',
        'privacy policy',
        'terms',
        'rate',
        'review',
      ],
    },
  ];

  List<Map<String, dynamic>> get _filteredOptions {
    if (_searchQuery.isEmpty) {
      return _settingsOptions;
    }

    final query = _searchQuery.toLowerCase();

    return _settingsOptions.where((option) {
      // Search in title
      if (option['title'].toString().toLowerCase().contains(query)) {
        return true;
      }

      // Search in subtitle
      if (option['subtitle'].toString().toLowerCase().contains(query)) {
        return true;
      }

      // Search in keywords
      final keywords = option['keywords'] as List<String>?;
      if (keywords != null) {
        for (final keyword in keywords) {
          if (keyword.toLowerCase().contains(query)) {
            return true;
          }
        }
      }

      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kDarkBackground : kLightBackground,
      body: CustomScrollView(
        slivers: [
          // Sleek modern app bar with parallax effect
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final double expandRatio =
                    ((constraints.maxHeight - kToolbarHeight) /
                            (200 - kToolbarHeight))
                        .clamp(0.0, 1.0);

                return FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.fadeTitle,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Animated gradient background
                      ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [
                                        Colors.purple.withOpacity(0.2),
                                        Colors.blue.withOpacity(0.15),
                                        Colors.transparent,
                                      ]
                                    : [
                                        Colors.purple.withOpacity(0.1),
                                        Colors.blue.withOpacity(0.08),
                                        Colors.transparent,
                                      ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Animated circles decoration
                      Positioned(
                        top: -50 + (expandRatio * 30),
                        right: -30,
                        child: Opacity(
                          opacity: (expandRatio * 0.5).clamp(0.0, 1.0),
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  kPrimary.withOpacity(0.3),
                                  kPrimary.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: -40 + (expandRatio * 20),
                        left: -40,
                        child: Opacity(
                          opacity: (expandRatio * 0.4).clamp(0.0, 1.0),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.cyan.withOpacity(0.3),
                                  Colors.cyan.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Large animated title in center
                      Positioned.fill(
                        child: SafeArea(
                          child: Center(
                            child: Opacity(
                              opacity: expandRatio.clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: (0.8 + (expandRatio * 0.2)).clamp(
                                  0.8,
                                  1.0,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Settings icon with glow
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              kPrimary.withOpacity(0.8),
                                              kPrimary.withOpacity(0.4),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: kPrimary.withOpacity(0.4),
                                              blurRadius: 30,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.settings_rounded,
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Title
                                      Text(
                                        'Settings',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // Subtitle
                                      Text(
                                        'Customize your experience',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white60
                                              : Colors.black54,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Animated back button that hides on scroll
                      Positioned(
                        top: 0,
                        left: 0,
                        child: SafeArea(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: expandRatio > 0.3 ? 1.0 : 0.0,
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: expandRatio > 0.3 ? 1.0 : 0.0,
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.black.withOpacity(0.1),
                                  ),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.arrow_back_rounded,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _buildSearchBar(isDark),
            ),
          ),

          // Popular Searches (when search is focused and empty)
          if (_isSearchFocused && _searchQuery.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'POPULAR SEARCHES',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _popularSearches.map((search) {
                        return InkWell(
                          onTap: () {
                            _searchController.text = search;
                            setState(() {
                              _searchQuery = search;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  search,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

          // Search Results Info
          if (_searchQuery.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 16,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _filteredOptions.isEmpty
                          ? 'No results found for "$_searchQuery"'
                          : '${_filteredOptions.length} result${_filteredOptions.length == 1 ? '' : 's'} for "$_searchQuery"',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // No Results Message
          if (_searchQuery.isNotEmpty && _filteredOptions.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 100),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No settings found',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try searching for something else',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Settings Options
          if (_filteredOptions.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final option = _filteredOptions[index];
                  return AnimatedOpacity(
                    opacity: 1.0,
                    duration: Duration(milliseconds: 150 + (index * 50)),
                    child: _buildSettingsCard(
                      context,
                      isDark,
                      option['icon'],
                      option['title'],
                      option['subtitle'],
                      option['color'],
                      option['page'],
                    ),
                  );
                }, childCount: _filteredOptions.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.06),
                    ]
                  : [
                      Colors.white.withOpacity(0.85),
                      Colors.white.withOpacity(0.65),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.5),
              width: 1.2,
            ),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Search settings...',
              hintStyle: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        // Dismiss keyboard
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    bool isDark,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    Widget page,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.12),
                        Colors.white.withOpacity(0.06),
                      ]
                    : [
                        Colors.white.withOpacity(0.85),
                        Colors.white.withOpacity(0.65),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.5),
                width: 1.2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => page),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: isDark ? Colors.white38 : Colors.black38,
                        size: 18,
                      ),
                    ],
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
