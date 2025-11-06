import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'scaffold_with_nav_bar.dart';
import '../features/auth/forgot_password_page.dart';
import '../features/auth/reset_confirmation_page.dart';
import '../features/auth/sign_in_page.dart';
import '../features/auth/sign_up_page.dart';
import '../features/auth/email_verification_page.dart';
import '../features/auth/phone_verification_page.dart';
import '../features/auth/otp_verification_page.dart';
import '../features/auth/setup_profile_picture_page.dart';
import '../features/auth/setup_bio_page.dart';
import '../features/home/home_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/profile/profile_page.dart';
import '../features/profile/edit_profile_page.dart';
import '../features/profile/change_username_page.dart';
import '../features/explore/explore_page.dart';
import '../features/reels/reels_page_new.dart';
import '../features/chat/chat_page.dart';
import '../features/splash/splash_screen.dart';
import '../features/settings/back_navigation_settings_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // Splash Screen - Always show first
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(path: '/signin', builder: (context, state) => const SignInPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
    GoRoute(
      path: '/email-verification',
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return EmailVerificationPage(email: email);
      },
    ),
    GoRoute(
      path: '/otp-verification',
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        final phone = state.uri.queryParameters['phone'] ?? '';

        // userData will be fetched from Supabase auth user in the verification page
        Map<String, dynamic> userData = {};

        return OtpVerificationPage(
          email: email,
          phone: phone,
          userData: userData,
        );
      },
    ),
    GoRoute(
      path: '/phone-verification',
      builder: (context, state) {
        // Phone verification temporarily disabled
        return const PhoneVerificationPage();
      },
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/reset-email-sent',
      builder: (context, state) => const ResetConfirmationPage(),
    ),
    GoRoute(
      path: '/setup-profile-picture',
      builder: (context, state) => const SetupProfilePicturePage(),
    ),
    GoRoute(
      path: '/setup-bio',
      builder: (context, state) => const SetupBioPage(),
    ),
    // Chat page (standalone, no nav bar)
    GoRoute(path: '/chat', builder: (context, state) => const ChatPage()),

    // Profile management pages (standalone, no nav bar)
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfilePage(),
    ),
    GoRoute(
      path: '/change-username',
      builder: (context, state) => const ChangeUsernamePage(),
    ),

    // Settings pages (standalone, no nav bar)
    GoRoute(
      path: '/back-navigation-settings',
      builder: (context, state) => const BackNavigationSettingsPage(),
    ),

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
          builder: (context, state) => ReelsPageNew(key: reelsPageKey),
        ),
      ],
    ),
  ],
);
