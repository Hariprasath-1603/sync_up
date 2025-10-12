import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'scaffold_with_nav_bar.dart';
import 'services/preferences_service.dart';
import '../features/auth/forgot_password_page.dart';
import '../features/auth/reset_confirmation_page.dart';
import '../features/auth/sign_in_page.dart';
import '../features/auth/sign_up_page.dart';
import '../features/home/home_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/profile/profile_page.dart';
import '../features/explore/explore_page.dart';
import '../features/reels/reels_page_new.dart';
import '../features/chat/chat_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

// Determine initial location based on user state
String _getInitialLocation() {
  // Check if user is logged in
  if (PreferencesService.isLoggedIn()) {
    return '/home';
  }

  // Check if user has seen onboarding
  if (PreferencesService.hasSeenOnboarding()) {
    return '/signin';
  }

  // Show onboarding for first-time users
  return '/onboarding';
}

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: _getInitialLocation(),
  routes: [
    // Standalone routes (no nav bar)
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(path: '/signin', builder: (context, state) => const SignInPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/reset-email-sent',
      builder: (context, state) => const ResetConfirmationPage(),
    ),
    // Chat page (standalone, no nav bar)
    GoRoute(path: '/chat', builder: (context, state) => const ChatPage()),

    // ShellRoute for all pages that HAVE the navigation bar
    ShellRoute(
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const MyProfilePage(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const ExplorePage(),
        ),
        GoRoute(
          path: '/reels',
          builder: (context, state) => const ReelsPageNew(),
        ),
      ],
    ),
  ],
);
