import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'core/theme.dart';
import 'core/app_router.dart';
import 'firebase_options.dart'; // Import the generated file

Future<void> main() async {
  // Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // We are not loading the .env file here anymore for this setup
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Syncup',
      theme: buildAppTheme(), // Make sure this function name is correct
      routerConfig: appRouter,
    );
  }
}

