import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing back navigation settings
class BackNavigationSettingsService {
  static const String _keyDoubleTapExit = 'double_tap_exit_enabled';
  static const String _keyVibrateOnBack = 'vibrate_on_back_enabled';
  static const String _keyAutoReturnHome = 'auto_return_home_enabled';
  static const String _keyShowToast = 'show_toast_enabled';

  static BackNavigationSettingsService? _instance;
  SharedPreferences? _prefs;

  // Settings cache
  bool _doubleTapExitEnabled = true;
  bool _vibrateOnBackEnabled = true;
  bool _autoReturnHomeEnabled = true;
  bool _showToastEnabled = true;

  BackNavigationSettingsService._();

  /// Get singleton instance
  static BackNavigationSettingsService get instance {
    _instance ??= BackNavigationSettingsService._();
    return _instance!;
  }

  /// Initialize the service (call this on app startup)
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  /// Load all settings from SharedPreferences
  Future<void> _loadSettings() async {
    _doubleTapExitEnabled = _prefs?.getBool(_keyDoubleTapExit) ?? true;
    _vibrateOnBackEnabled = _prefs?.getBool(_keyVibrateOnBack) ?? true;
    _autoReturnHomeEnabled = _prefs?.getBool(_keyAutoReturnHome) ?? true;
    _showToastEnabled = _prefs?.getBool(_keyShowToast) ?? true;
  }

  /// Double-tap to exit enabled
  bool get doubleTapExitEnabled => _doubleTapExitEnabled;

  Future<void> setDoubleTapExitEnabled(bool value) async {
    _doubleTapExitEnabled = value;
    await _prefs?.setBool(_keyDoubleTapExit, value);
  }

  /// Vibrate on back press enabled
  bool get vibrateOnBackEnabled => _vibrateOnBackEnabled;

  Future<void> setVibrateOnBackEnabled(bool value) async {
    _vibrateOnBackEnabled = value;
    await _prefs?.setBool(_keyVibrateOnBack, value);
  }

  /// Auto return to home on back press
  bool get autoReturnHomeEnabled => _autoReturnHomeEnabled;

  Future<void> setAutoReturnHomeEnabled(bool value) async {
    _autoReturnHomeEnabled = value;
    await _prefs?.setBool(_keyAutoReturnHome, value);
  }

  /// Show toast messages
  bool get showToastEnabled => _showToastEnabled;

  Future<void> setShowToastEnabled(bool value) async {
    _showToastEnabled = value;
    await _prefs?.setBool(_keyShowToast, value);
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await setDoubleTapExitEnabled(true);
    await setVibrateOnBackEnabled(true);
    await setAutoReturnHomeEnabled(true);
    await setShowToastEnabled(true);
  }
}
