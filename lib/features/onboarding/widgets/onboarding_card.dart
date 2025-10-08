import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OnboardingCard extends StatelessWidget {
  final String lottieAsset;
  final String title;
  final String subtitle;
  const OnboardingCard({
    super.key,
    required this.lottieAsset,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        // This is the main change to center your content vertically
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie Animation
          Lottie.asset(
            lottieAsset,
            height: MediaQuery.of(context).size.height * 0.32,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 30),

          // Title Text
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle Text
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}