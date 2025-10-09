import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'scaffold_with_nav_bar.dart';
import '../features/auth/forgot_password_page.dart';
import '../features/auth/reset_confirmation_page.dart';
import '../features/auth/sign_in_page.dart';
import '../features/auth/sign_up_page.dart';
import '../features/home/home_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/profile/profile_page.dart';
import '../features/explore/explore_page.dart';
final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  // ## THIS IS THE FIX ##
  // Change the initial location to the onboarding screen.
  initialLocation: '/onboarding',
  routes: [
    // Standalone routes (no nav bar)
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/signin',
      builder: (context, state) => const SignInPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/reset-email-sent',
      builder: (context, state) => const ResetConfirmationPage(),
    ),

    // ShellRoute for all pages that HAVE the navigation bar
    ShellRoute(
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const MyProfilePage(),
        ),
        GoRoute( // <-- ADD THIS ROUTE
          path: '/search', // Use '/search' as this is your new search/explore page
          builder: (context, state) => const ExplorePage(),
        ),
      ],
    ),
  ],
);