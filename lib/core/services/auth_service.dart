import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Service for handling authentication and user data
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentFirebaseUser;
  UserModel? _currentUser;

  /// Get the current Firebase user
  User? get currentFirebaseUser => _currentFirebaseUser ?? _auth.currentUser;

  /// Get the current app user model
  UserModel? get currentUser => _currentUser;

  /// Get current user ID
  String? get currentUserId => currentFirebaseUser?.uid;

  /// Check if user is authenticated
  bool get isAuthenticated => currentFirebaseUser != null;

  /// Initialize and load current user data
  Future<void> initialize() async {
    _currentFirebaseUser = _auth.currentUser;
    if (_currentFirebaseUser != null) {
      await loadCurrentUserData();
    }
  }

  /// Load current user data from Firestore or cache
  Future<void> loadCurrentUserData() async {
    if (_currentFirebaseUser == null) return;

    try {
      // Load user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentFirebaseUser!.uid)
          .get();

      if (userDoc.exists) {
        // User document exists in Firestore, load it
        _currentUser = UserModel.fromMap(userDoc.data()!);
      } else {
        // Fallback: User document doesn't exist, create from Firebase Auth
        _currentUser = UserModel(
          uid: _currentFirebaseUser!.uid,
          username: _currentFirebaseUser!.displayName ?? 'User',
          email: _currentFirebaseUser!.email ?? '',
          displayName: _currentFirebaseUser!.displayName,
          photoURL: _currentFirebaseUser!.photoURL,
          bio: '',
          followersCount: 0,
          followingCount: 0,
          postsCount: 0,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );
      }
    } catch (e) {
      print('Error loading user data from Firestore: $e');
      // Fallback to Firebase Auth data on error
      _currentUser = UserModel(
        uid: _currentFirebaseUser!.uid,
        username: _currentFirebaseUser!.displayName ?? 'User',
        email: _currentFirebaseUser!.email ?? '',
        displayName: _currentFirebaseUser!.displayName,
        photoURL: _currentFirebaseUser!.photoURL,
        bio: '',
        followersCount: 0,
        followingCount: 0,
        postsCount: 0,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );
    }
  }

  /// Check if a post belongs to the current user
  bool isOwnPost(String postUserId) {
    return currentUserId != null && currentUserId == postUserId;
  }

  /// Check if current user is following another user
  bool isFollowing(String userId) {
    // TODO: Check from Firestore or cache
    return false;
  }

  /// Follow a user
  Future<bool> followUser(String userId) async {
    if (currentUserId == null) return false;

    try {
      // TODO: Implement Firestore follow logic
      // Example:
      // await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(currentUserId)
      //     .collection('following')
      //     .doc(userId)
      //     .set({'timestamp': FieldValue.serverTimestamp()});

      return true;
    } catch (e) {
      print('Error following user: $e');
      return false;
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser(String userId) async {
    if (currentUserId == null) return false;

    try {
      // TODO: Implement Firestore unfollow logic
      // Example:
      // await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(currentUserId)
      //     .collection('following')
      //     .doc(userId)
      //     .delete();

      return true;
    } catch (e) {
      print('Error unfollowing user: $e');
      return false;
    }
  }

  /// Sign up with email and password
  Future<User?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentFirebaseUser = credential.user;
      return credential.user;
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentFirebaseUser = credential.user;
      await loadCurrentUserData();
      return credential.user;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _currentFirebaseUser = null;
    _currentUser = null;
  }

  /// Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
