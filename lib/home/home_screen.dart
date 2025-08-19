import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth.dart'; // Import your consolidated auth file

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SyncUp Home'),
        actions: [
          // This button will log the user out and return them to the login screen.
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Sign the user out of Firebase Authentication.
              await FirebaseAuth.instance.signOut();

              // Navigate back to the login screen and remove all previous routes.
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthScreen()),
                    (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome to SyncUp!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}