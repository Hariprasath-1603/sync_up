import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/preferences_service.dart';
import 'onboarding_controller.dart';
import 'widgets/onboarding_card.dart';
import 'widgets/onboarding_bottom_bar.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final OnboardingController ctrl;

  final items = const [
    (
      'assets/lottie/welcome.json',
      '',
      'Your space to connect, share, and grow. Join a vibrant community where every moment matters.',
    ),
    (
      'assets/lottie/search.json',
      'Explore the World of Syncup',
      'Fresh content. New connections. Endless inspiration.',
    ),
    (
      'assets/lottie/connect.json',
      'Stay Connected. Stay Inspired',
      'Your hub for the latest posts, people, and conversations.',
    ),
    (
      'assets/lottie/launch.json',
      'Unlock Your Social Space',
      'Let’s get you connected — it all begins with a tap.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    ctrl = OnboardingController();
  }

  @override
  void dispose() {
    ctrl.disposeAll();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    // Save that user has seen onboarding
    await PreferencesService.setOnboardingSeen(true);
    if (mounted) {
      context.go('/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastIndex = items.length - 1;

    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: ctrl.pageController,
                  onPageChanged: ctrl.onPageChanged,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final it = items[i];
                    return OnboardingCard(
                      lottieAsset: it.$1,
                      title: it.$2,
                      subtitle: it.$3,
                    );
                  },
                ),
              ),
              OnboardingBottomBar(
                controller: ctrl.pageController,
                currentIndex: ctrl.currentIndex,
                lastIndex: lastIndex,
                onSkip: () => ctrl.skipToEnd(lastIndex),
                onNext: () => ctrl.next(lastIndex),
                onGetStarted: _completeOnboarding,
              ),
            ],
          ),
        );
      },
    );
  }
}
