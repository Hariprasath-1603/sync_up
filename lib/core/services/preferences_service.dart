import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyOnboardingSeen = 'onboarding_seen';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';

  static SharedPreferences? _prefs;

  // Initialize shared preferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Get SharedPreferences instance
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('PreferencesService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Onboarding
  static Future<void> setOnboardingSeen(bool seen) async {
    await prefs.setBool(_keyOnboardingSeen, seen);
  }

  static bool hasSeenOnboarding() {
    return prefs.getBool(_keyOnboardingSeen) ?? false;
  }

  // Login state
  static Future<void> setLoggedIn(bool loggedIn) async {
    await prefs.setBool(_keyIsLoggedIn, loggedIn);
  }

  static bool isLoggedIn() {
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // User data
  static Future<void> setUserId(String userId) async {
    await prefs.setString(_keyUserId, userId);
  }

  static String? getUserId() {
    return prefs.getString(_keyUserId);
  }

  static Future<void> setUserEmail(String email) async {
    await prefs.setString(_keyUserEmail, email);
  }

  static String? getUserEmail() {
    return prefs.getString(_keyUserEmail);
  }

  static Future<void> setUserName(String name) async {
    await prefs.setString(_keyUserName, name);
  }

  static String? getUserName() {
    return prefs.getString(_keyUserName);
  }

  // Save complete user session
  static Future<void> saveUserSession({
    required String userId,
    required String email,
    String? name,
  }) async {
    await Future.wait([
      setLoggedIn(true),
      setUserId(userId),
      setUserEmail(email),
      if (name != null) setUserName(name),
    ]);
  }

  // Clear user session (logout)
  static Future<void> clearUserSession() async {
    await Future.wait([
      setLoggedIn(false),
      prefs.remove(_keyUserId),
      prefs.remove(_keyUserEmail),
      prefs.remove(_keyUserName),
    ]);
  }

  // Clear all data (for debugging or reset)
  static Future<void> clearAll() async {
    await prefs.clear();
  }
}
