import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/services/preferences_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // SIGN IN WITH EMAIL AND PASSWORD
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.message}');
      return null;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // SIGN UP WITH EMAIL AND PASSWORD
  Future<User?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.message}');
      return null;
    } catch (e) {
      print('Error signing up: $e');
      return null;
    }
  }

  // SIGN IN WITH GOOGLE
  Future<User?> signInWithGoogle() async {
    try {
      print('AuthService: Starting Google Sign-In flow...');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('AuthService: GoogleSignInAccount received: ${googleUser?.email}');

      if (googleUser == null) {
        // User canceled the sign-in
        print('AuthService: User canceled Google Sign-In');
        return null;
      }

      // Obtain the auth details from the request
      print('AuthService: Getting authentication details...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print(
        'AuthService: Auth tokens received - accessToken: ${googleAuth.accessToken != null}, idToken: ${googleAuth.idToken != null}',
      );

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('AuthService: Credential created, signing in to Firebase...');

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      print(
        'AuthService: Firebase sign-in successful! User: ${userCredential.user?.email}',
      );

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print(
        'AuthService: Firebase Auth Exception - Code: ${e.code}, Message: ${e.message}',
      );
      rethrow; // Re-throw to show error in UI
    } catch (e) {
      print('AuthService: Error signing in with Google: $e');
      rethrow; // Re-throw to show error in UI
    }
  }

  // SIGN IN WITH MICROSOFT (Azure AD)
  // Note: Requires Microsoft Azure AD setup and configuration
  Future<User?> signInWithMicrosoft() async {
    try {
      final microsoftProvider = OAuthProvider('microsoft.com');

      // You can add custom parameters
      microsoftProvider.setCustomParameters({
        'tenant': 'common', // or your tenant ID
      });

      // Sign in with popup on web, or redirect on mobile
      final UserCredential userCredential = await _firebaseAuth
          .signInWithProvider(microsoftProvider);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.message}');
      return null;
    } catch (e) {
      print('Error signing in with Microsoft: $e');
      return null;
    }
  }

  // SIGN IN WITH APPLE
  // Note: iOS only, requires Apple Developer account and configuration
  Future<User?> signInWithApple() async {
    try {
      final appleProvider = OAuthProvider('apple.com');

      // Request specific scopes
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      final UserCredential userCredential = await _firebaseAuth
          .signInWithProvider(appleProvider);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.message}');
      return null;
    } catch (e) {
      print('Error signing in with Apple: $e');
      return null;
    }
  }

  // SEND PASSWORD RESET EMAIL
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception on password reset: ${e.message}');
      throw e;
    }
  }

  // SIGN OUT
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      // Sign out from Firebase
      await _firebaseAuth.signOut();

      // Clear local session data
      await PreferencesService.clearUserSession();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // DELETE ACCOUNT
  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.message}');
      throw e;
    }
  }
}
