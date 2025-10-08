import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // SIGN IN METHOD (already exists)
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    // ... your existing sign-in code
  }

  // ## ADD THIS NEW METHOD ##
  // SEND PASSWORD RESET EMAIL
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // You can handle errors here, e.g., by re-throwing a custom exception
      print('Firebase Auth Exception on password reset: ${e.message}');
      throw e; // Re-throw the exception to be caught in the UI
    }
  }

// TODO: Add methods for Sign Up, Sign Out, etc. later
}