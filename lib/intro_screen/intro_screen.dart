import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:sync_up/auth/auth.dart';
class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({super.key});

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    IntroComponent(
      title: "Welcome",
      description:
      "Your space to connect, share, and grow.\nJoin a vibrant community where every moment matters.",
      lottiePath: 'assets/lottie/welcome.json',
    ),
    IntroComponent(
      title: "Explore the World of Syncup",
      description: "Fresh content. New connections. Endless inspiration.",
      lottiePath: 'assets/lottie/explore.json',
    ),
    IntroComponent(
      title: "Stay Connected. Stay Inspired",
      description: "Your hub for the latest posts, people, and conversations.",
      lottiePath: 'assets/lottie/connect.json',
    ),
    IntroComponent(
      title: "Unlock Your Social Space",
      description: "Let’s get you connected — it all begins with a tap.",
      lottiePath: 'assets/lottie/start.json',
    ),
  ];

  void _skip() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _onNext() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _onFinish();
    }
  }

  void _onFinish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthScreen(), // ✅ Goes to your auth screen
      ),
    );
  }

  // void _onFinish() {
  //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Scaffold(
  //         body: Center(
  //           child: Text(
  //             "Home Screen",
  //             style: TextStyle(
  //               fontSize: 25,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) => _pages[index],
          ),
          if (_currentIndex != _pages.length - 1)
            Positioned(
              bottom: 40,
              left: 20,
              child: TextButton(
                onPressed: _skip,
                child: const Text(
                  "Skip",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 40,
            right: 20,
            child: TextButton(
              onPressed: _onNext,
              child: Text(
                _currentIndex == _pages.length - 1
                    ? "Get Started"
                    : "Next",
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _pages.length,
                effect: const WormEffect(
                  dotColor: Colors.grey,
                  activeDotColor: Colors.blue,
                  dotHeight: 10,
                  dotWidth: 12,
                  spacing: 10,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class IntroComponent extends StatelessWidget {
  final String title;
  final String description;
  final String lottiePath;

  const IntroComponent({
    super.key,
    required this.title,
    required this.description,
    required this.lottiePath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(lottiePath, height: 300),
        const SizedBox(height: 30),
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}
