import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/auth/sign_in_page.dart';
import '../features/auth/sign_up_page.dart';
import '../features/auth/forgot_password_page.dart';
import '../features/auth/reset_confirmation_page.dart';
// ## ADD THIS IMPORT TO FIX THE ERROR ##
import '../features/home/home_page.dart';

final appRouter = GoRouter(
  // You can change this to '/signin' or '/home' for testing
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/signin',
      builder: (_, __) => const SignInPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (_, __) => const SignUpPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (_, __) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/reset-email-sent',
      builder: (_, __) => const ResetConfirmationPage(),
    ),
    // This route will now work correctly
    GoRoute(
      path: '/home',
      builder: (_, __) => const HomePage(),
    ),
  ],
);