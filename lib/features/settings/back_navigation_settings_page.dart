import 'package:flutter/material.dart';
import '../../core/services/back_navigation_settings_service.dart';

class BackNavigationSettingsPage extends StatefulWidget {
  const BackNavigationSettingsPage({super.key});

  @override
  State<BackNavigationSettingsPage> createState() =>
      _BackNavigationSettingsPageState();
}

class _BackNavigationSettingsPageState
    extends State<BackNavigationSettingsPage> {
  final _settingsService = BackNavigationSettingsService.instance;

  late bool _doubleTapExit;
  late bool _vibrateOnBack;
  late bool _autoReturnHome;
  late bool _showToast;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _doubleTapExit = _settingsService.doubleTapExitEnabled;
      _vibrateOnBack = _settingsService.vibrateOnBackEnabled;
      _autoReturnHome = _settingsService.autoReturnHomeEnabled;
      _showToast = _settingsService.showToastEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Back Navigation Settings'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              await _settingsService.resetToDefaults();
              _loadSettings();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings reset to defaults'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Customize your back button behavior',
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ),

          // Double-tap to exit
          _buildSettingCard(
            icon: Icons.touch_app_rounded,
            title: 'Double-tap to Exit',
            subtitle: 'Require two taps on Home to exit the app',
            value: _doubleTapExit,
            onChanged: (value) async {
              await _settingsService.setDoubleTapExitEnabled(value);
              setState(() => _doubleTapExit = value);
            },
            theme: theme,
            isDark: isDark,
          ),

          const SizedBox(height: 12),

          // Vibrate on back press
          _buildSettingCard(
            icon: Icons.vibration_rounded,
            title: 'Haptic Feedback',
            subtitle: 'Vibrate when pressing back button',
            value: _vibrateOnBack,
            onChanged: (value) async {
              await _settingsService.setVibrateOnBackEnabled(value);
              setState(() => _vibrateOnBack = value);
            },
            theme: theme,
            isDark: isDark,
          ),

          const SizedBox(height: 12),

          // Auto return to home
          _buildSettingCard(
            icon: Icons.home_rounded,
            title: 'Auto Return to Home',
            subtitle: 'Navigate to Home before exiting app',
            value: _autoReturnHome,
            onChanged: (value) async {
              await _settingsService.setAutoReturnHomeEnabled(value);
              setState(() => _autoReturnHome = value);
            },
            theme: theme,
            isDark: isDark,
          ),

          const SizedBox(height: 12),

          // Show toast messages
          _buildSettingCard(
            icon: Icons.message_rounded,
            title: 'Toast Messages',
            subtitle: 'Show "Press again to exit" messages',
            value: _showToast,
            onChanged: (value) async {
              await _settingsService.setShowToastEnabled(value);
              setState(() => _showToast = value);
            },
            theme: theme,
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          // Info section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.blue.shade900.withOpacity(0.2)
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.blue.shade700.withOpacity(0.3)
                    : Colors.blue.shade200,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How it works',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isDark
                              ? Colors.blue.shade300
                              : Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• From main pages (Explore, Reels, Profile): back takes you to Home\n'
                        '• From Home: press back twice within 2 seconds to exit\n'
                        '• From subpages: back works normally',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? Colors.blue.shade200
                              : Colors.blue.shade900,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
