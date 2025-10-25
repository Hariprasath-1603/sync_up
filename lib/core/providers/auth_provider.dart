import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

/// Provider for managing authentication state
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

  /// Initialize auth state
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
  bool isFollowing(String userId) {
    if (_currentUser == null) return false;
    return _currentUser!.following.contains(userId);
  }

  /// Follow a user
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
  Future<void> reloadUserData() async {
    if (_currentUser == null) return;

    final userData = await _databaseService.getUserByUid(_currentUser!.uid);
    _currentUser = userData;
    notifyListeners();
  }
}
