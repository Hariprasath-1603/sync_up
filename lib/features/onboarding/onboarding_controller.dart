import 'package:flutter/material.dart';

class OnboardingController extends ChangeNotifier {
  final pageController = PageController();
  int currentIndex = 0;

  void onPageChanged(int i) {
    currentIndex = i;
    notifyListeners();
  }

  void next(int lastIndex) {
    if (currentIndex < lastIndex) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  void skipToEnd(int lastIndex) {
    pageController.animateToPage(
      lastIndex,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void disposeAll() {
    pageController.dispose();
  }
}
