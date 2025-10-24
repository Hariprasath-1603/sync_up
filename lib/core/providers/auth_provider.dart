import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

/// Provider for managing authentication state
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

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

  /// Initialize auth state
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.initialize();
      _currentUser = _authService.currentUser;

      // Listen to auth state changes
      _authService.authStateChanges.listen((User? user) {
        if (user == null) {
          _currentUser = null;
        } else {
          _authService.loadCurrentUserData().then((_) {
            _currentUser = _authService.currentUser;
            notifyListeners();
          });
        }
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if a post belongs to the current user
  bool isOwnPost(String postUserId) {
    return _authService.isOwnPost(postUserId);
  }

  /// Check if current user is following another user
  bool isFollowing(String userId) {
    if (_currentUser == null) return false;
    return _currentUser!.following.contains(userId);
  }

  /// Follow a user
  Future<bool> followUser(String userId) async {
    final success = await _authService.followUser(userId);
    if (success && _currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        following: [..._currentUser!.following, userId],
        followingCount: _currentUser!.followingCount + 1,
      );
      notifyListeners();
    }
    return success;
  }

  /// Unfollow a user
  Future<bool> unfollowUser(String userId) async {
    final success = await _authService.unfollowUser(userId);
    if (success && _currentUser != null) {
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
  }

  /// Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Reload user data
  Future<void> reloadUserData() async {
    await _authService.loadCurrentUserData();
    _currentUser = _authService.currentUser;
    notifyListeners();
  }
}
