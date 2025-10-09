import 'package:flutter/material.dart';
import 'package:sync_up/features/home/widgets/animated_nav_bar.dart'; // Import the new bar

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.child,
    Key? key,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body is now a Stack to allow the nav bar to float on top
      body: Stack(
        children: [
          // The page content is the first item in the stack
          child,
          // The navigation bar is positioned at the bottom
          const Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedNavBar(),
          ),
        ],
      ),
    );
  }
}