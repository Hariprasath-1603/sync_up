import 'package:shared_preferences/shared_preferences.dart';

/// Local Storage Service using SharedPreferences
/// 
/// Provides a simple key-value storage solution for persisting data locally.
/// Used for storing user preferences, session data, and application state.
/// 
/// Key Features:
/// - Persistent storage across app sessions
/// - Synchronous read operations after initialization
/// - Type-safe getters and setters
/// - Singleton pattern for global access
/// 
/// Storage Categories:
/// 1. **Onboarding State** - Track if user has seen intro screens
/// 2. **Authentication State** - Login status and user identifiers
/// 3. **User Data** - Basic user information for quick access
/// 
/// Initialization:
/// Must call `PreferencesService.init()` before use (typically in main.dart)
/// This loads the SharedPreferences instance asynchronously.
/// 
/// Usage Example:
/// ```dart
/// // In main.dart
/// await PreferencesService.init();
/// 
/// // Anywhere in app
/// await PreferencesService.setOnboardingSeen(true);
/// bool seen = PreferencesService.hasSeenOnboarding();
/// ```
class PreferencesService {
  // ==================== PREFERENCE KEYS ====================
  // All keys are prefixed and namespaced to avoid conflicts
  
  /// Key for tracking whether user has completed onboarding flow
  static const String _keyOnboardingSeen = 'onboarding_seen';
  
  /// Key for storing user's login state (separate from Supabase session)
  static const String _keyIsLoggedIn = 'is_logged_in';
  
  /// Key for storing authenticated user's unique identifier
  static const String _keyUserId = 'user_id';
  
  /// Key for storing user's email address
  static const String _keyUserEmail = 'user_email';
  
  /// Key for storing user's display name
  static const String _keyUserName = 'user_name';

  /// Internal SharedPreferences instance (null until initialized)
  static SharedPreferences? _prefs;

  /// Initialize the PreferencesService
  /// 
  /// MUST be called before any other PreferencesService methods.
  /// Typically called in main() before runApp().
  /// 
  /// This asynchronously loads the SharedPreferences instance from platform storage.
  /// Once initialized, all read/write operations are synchronous.
  /// 
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await PreferencesService.init();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get the initialized SharedPreferences instance
  /// 
  /// Throws an exception if [init()] has not been called yet.
  /// This ensures all methods fail fast with clear error messages
  /// rather than returning null or causing unclear errors.
  /// 
  /// Returns: The singleton SharedPreferences instance
  /// Throws: Exception if not initialized
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('PreferencesService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ==================== ONBOARDING STATE ====================
  
  /// Mark onboarding as seen/completed
  /// 
  /// Call this after user completes the onboarding flow to prevent
  /// showing it again on subsequent app launches.
  /// 
  /// Parameters:
  ///   [seen] - true if onboarding completed, false to reset
  /// 
  /// Example:
  /// ```dart
  /// // After last onboarding screen
  /// await PreferencesService.setOnboardingSeen(true);
  /// Navigator.pushReplacement(context, LoginPage());
  /// ```
  static Future<void> setOnboardingSeen(bool seen) async {
    await prefs.setBool(_keyOnboardingSeen, seen);
  }

  /// Check if user has completed onboarding
  /// 
  /// Returns true if user has seen onboarding, false otherwise.
  /// Defaults to false for first-time users.
  /// 
  /// Used in splash screen to determine initial navigation route:
  /// - If false: Navigate to onboarding
  /// - If true: Navigate to auth or home based on login state
  /// 
  /// Returns: true if onboarding completed, false if not
  static bool hasSeenOnboarding() {
    return prefs.getBool(_keyOnboardingSeen) ?? false;
  }

  // ==================== LOGIN STATE ====================
  
  /// Update user's login state
  /// 
  /// This is separate from Supabase session management and provides
  /// a quick, synchronous way to check login status without async calls.
  /// 
  /// Should be set to:
  /// - true: After successful login/signup
  /// - false: After logout or session expiration
  /// 
  /// Parameters:
  ///   [loggedIn] - true if user is logged in, false otherwise
  static Future<void> setLoggedIn(bool loggedIn) async {
    await prefs.setBool(_keyIsLoggedIn, loggedIn);
  }

  /// Check if user is currently logged in
  /// 
  /// This is a quick local check and may not reflect actual Supabase
  /// session state. Always verify with Supabase auth for critical operations.
  /// 
  /// Use cases:
  /// - Quick checks in splash screen for initial routing
  /// - UI state decisions (show login vs home)
  /// - Offline capability indicators
  /// 
  /// Returns: true if logged in, false otherwise (defaults to false)
  static bool isLoggedIn() {
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // ==================== USER DATA CACHE ====================
  // Stores basic user information for quick access without database queries
  // This is a local cache only - source of truth is in Supabase database
  
  /// Store the authenticated user's unique identifier
  /// 
  /// The user ID is the primary key from Supabase auth (UUID format).
  /// This is stored locally for quick access and offline reference.
  /// 
  /// Should be set:
  /// - After successful authentication
  /// - When user data is refreshed
  /// 
  /// Should be cleared:
  /// - On logout
  /// - On account deletion
  /// 
  /// Parameters:
  ///   [userId] - The Supabase user UUID
  static Future<void> setUserId(String userId) async {
    await prefs.setString(_keyUserId, userId);
  }

  /// Retrieve the stored user ID
  /// 
  /// Returns the cached user ID or null if not set.
  /// This is useful for quick user identification without async database calls.
  /// 
  /// Note: This is cached data - may be stale if user was deleted externally.
  /// Always validate against Supabase for security-critical operations.
  /// 
  /// Returns: User UUID string or null if not logged in
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
