import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

/// Authentication State Management Provider
/// 
/// Manages all authentication-related state and operations throughout the app.
/// This provider is used app-wide via Provider package in main.dart.
/// 
/// Key Responsibilities:
/// - Tracks current authenticated user and their data
/// - Listens to Supabase auth state changes (login/logout)
/// - Provides user profile information to all widgets
/// - Manages follow/unfollow operations
/// - Handles user data refresh and updates
/// 
/// State Properties:
/// - [currentUser] - Currently logged in user's data from database
/// - [isLoading] - Whether auth operations are in progress
/// - [isAuthenticated] - Quick check if user is logged in
/// - [error] - Last error message from auth operations
/// 
/// Usage:
/// ```dart
/// final authProvider = Provider.of<AuthProvider>(context);
/// if (authProvider.isAuthenticated) {
///   Text('Welcome ${authProvider.currentUser!.username}');
/// }
/// ```
class AuthProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  String? get currentUserId => _currentUser?.uid;

  AuthProvider() {
    _initialize();
  }

  /// Initialize authentication state and listeners
  /// 
  /// This method is called automatically when AuthProvider is created.
  /// It sets up the entire authentication flow:
  /// 
  /// 1. Sets up a real-time listener for Supabase auth state changes
  ///    - Automatically detects login/logout events
  ///    - Fetches user data from database when user logs in
  ///    - Clears user data when user logs out
  /// 
  /// 2. Checks if a user is already logged in (persisted session)
  ///    - Supabase stores session in device storage
  ///    - If session exists, loads user data immediately
  /// 
  /// This ensures the app always has the latest auth state without
  /// requiring manual refresh or state management.
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Listen to Supabase auth state changes
      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        final user = data.session?.user;
        if (user == null) {
          _currentUser = null;
        } else {
          // Load user data from database
          final userData = await _databaseService.getUserByUid(user.id);
          _currentUser = userData;
        }
        notifyListeners();
      });

      // Load current user if logged in
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        _currentUser = await _databaseService.getUserByUid(currentUser.id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if a post belongs to the current user
  bool isOwnPost(String postUserId) {
    return _currentUser?.uid == postUserId;
  }

  /// Check if current user is following another user
  /// 
  /// Used throughout the app to show correct follow/unfollow button state.
  /// Checks the local cached following list for instant UI updates.
  /// 
  /// Returns false if:
  /// - No user is logged in
  /// - The userId is not in the following list
  bool isFollowing(String userId) {
    if (_currentUser == null) return false;
    return _currentUser!.following.contains(userId);
  }

  /// Follow a user and update local state
  /// 
  /// Performs a two-step operation:
  /// 1. Updates the database (adds relationship in Supabase)
  /// 2. Updates local cached state for instant UI feedback
  /// 
  /// This optimistic update pattern ensures the UI feels responsive
  /// while the network request completes in the background.
  /// 
  /// Returns true if the operation succeeded, false otherwise.
  Future<bool> followUser(String userId) async {
    if (_currentUser == null) return false;

    try {
      final success = await _databaseService.followUser(
        _currentUser!.uid,
        userId,
      );

      if (success) {
        _currentUser = _currentUser!.copyWith(
          following: [..._currentUser!.following, userId],
          followingCount: _currentUser!.followingCount + 1,
        );
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error following user: $e');
      return false;
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser(String userId) async {
    if (_currentUser == null) return false;

    try {
      final success = await _databaseService.unfollowUser(
        _currentUser!.uid,
        userId,
      );

      if (success) {
        final updatedFollowing = _currentUser!.following
            .where((id) => id != userId)
            .toList();
        _currentUser = _currentUser!.copyWith(
          following: updatedFollowing,
          followingCount: _currentUser!.followingCount - 1,
        );
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error unfollowing user: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Reload user data
  /// Set [showLoading] to false to reload data silently without showing loading state
  Future<void> reloadUserData({bool showLoading = false}) async {
    if (_currentUser == null) return;

    try {
      if (showLoading) {
        _isLoading = true;
        notifyListeners();
      }

      final userData = await _databaseService.getUserByUid(_currentUser!.uid);
      _currentUser = userData;

      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    } catch (e) {
      print('Error reloading user data: $e');
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  void applyLocalProfilePhoto(String? url) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      photoURL: url != null && url.isNotEmpty ? url : null,
    );
    notifyListeners();
  }

  void applyLocalCoverPhoto(String? url) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      coverPhotoUrl: url != null && url.isNotEmpty ? url : null,
    );
    notifyListeners();
  }

  /// Update user's cover photo URL in database
  Future<bool> updateCoverPhoto(String coverPhotoUrl) async {
    if (_currentUser == null) return false;

    try {
      final success = await _databaseService.updateUserCoverPhoto(
        _currentUser!.uid,
        coverPhotoUrl,
      );

      if (success) {
        // Reload user data to get updated cover photo
        await reloadUserData(showLoading: false);
      }

      return success;
    } catch (e) {
      print('Error updating cover photo: $e');
      return false;
    }
  }

  /// Remove user's cover photo
  Future<bool> removeCoverPhoto() async {
    if (_currentUser == null) return false;

    try {
      final success = await _databaseService.updateUserCoverPhoto(
        _currentUser!.uid,
        null, // Set to null to remove cover photo
      );

      if (success) {
        await reloadUserData(showLoading: false);
      }

      return success;
    } catch (e) {
      print('Error removing cover photo: $e');
      return false;
    }
  }
}
