import 'package:flutter/material.dart';
import 'intro_screen/intro_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter',
      theme: ThemeData(
      brightness: Brightness.light,
    ),
    darkTheme: ThemeData(
    brightness: Brightness.dark,
    ),
    themeMode: ThemeMode.system,
    home: const IntroductionScreen(),
    );
  }
}
