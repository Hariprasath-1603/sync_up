import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingBottomBar extends StatelessWidget {
  final PageController controller;
  final int currentIndex;
  final int lastIndex;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback onGetStarted;

  const OnboardingBottomBar({
    super.key,
    required this.controller,
    required this.currentIndex,
    required this.lastIndex,
    required this.onSkip,
    required this.onNext,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = currentIndex == lastIndex;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        // 👇 This is the main change
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // We use a SizedBox to ensure the TextButton takes up space
          // even when the text is empty, preventing layout jumps.
          SizedBox(
            width: 70, // Adjust width as needed
            child: TextButton(
              onPressed: () => isLast ? onGetStarted() : onSkip(),
              child: Text(
                isLast ? '' : 'Skip', // Hide text instead of making it empty
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // const Spacer(), // 👈 REMOVED
          SmoothPageIndicator(
            controller: controller,
            count: lastIndex + 1,
            effect: ExpandingDotsEffect(
              dotHeight: 8,
              dotWidth: 8,
              expansionFactor: 3,
              spacing: 8,
              dotColor: theme.colorScheme.surfaceContainerHighest,
              activeDotColor: theme.colorScheme.primary,
            ),
          ),
          // const Spacer(), // 👈 REMOVED
          SizedBox(
            width: 120, // Adjust width as needed for "Get Started"
            child: FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () => isLast ? onGetStarted() : onNext(),
              child: Text(
                isLast ? 'Get Started' : 'Next',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}