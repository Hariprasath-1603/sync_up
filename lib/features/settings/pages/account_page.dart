import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/preferences_service.dart';
import '../widgets/settings_base_page.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_section.dart';
import '../../profile/edit_profile_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  Future<void> _logout(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Clear Supabase session
      await Supabase.instance.client.auth.signOut();

      // Clear preferences
      await PreferencesService.clearUserSession();

      if (context.mounted) {
        // Navigate to sign in
        context.go('/signin');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsBasePage(
      title: 'Account',
      children: [
        SettingsSection(
          title: 'Profile',
          children: [
            SettingsTile(
              icon: Icons.edit_outlined,
              title: 'Edit Profile',
              subtitle: 'Change name, bio, website',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfilePage(),
                  ),
                );
              },
            ),
            SettingsTile(
              icon: Icons.lock_outline,
              title: 'Change Password',
              subtitle: 'Update your account password',
              onTap: () {
                // Navigate to change password
              },
            ),
            SettingsTile(
              icon: Icons.email_outlined,
              title: 'Email & Phone',
              subtitle: 'Manage contact information',
              onTap: () {
                // Navigate to email & phone
              },
            ),
          ],
        ),
        SettingsSection(
          title: 'Account Management',
          children: [
            SettingsTile(
              icon: Icons.business_outlined,
              title: 'Account Type',
              subtitle: 'Personal, Professional, or Creator',
              onTap: () {
                // Navigate to account type
              },
            ),
            SettingsTile(
              icon: Icons.verified_user_outlined,
              title: 'Account Verification',
              subtitle: 'Get verified badge',
              onTap: () {
                // Navigate to verification
              },
            ),
          ],
        ),
        SettingsSection(
          title: 'Security',
          children: [
            SettingsTile(
              icon: Icons.security_outlined,
              title: 'Two-Factor Authentication',
              subtitle: 'Enable 2FA for extra security',
              onTap: () {
                // Navigate to 2FA
              },
            ),
            SettingsTile(
              icon: Icons.devices_outlined,
              title: 'Login Activity',
              subtitle: 'See where you are logged in',
              onTap: () {
                // Navigate to login activity
              },
            ),
          ],
        ),
        SettingsSection(
          title: 'Danger Zone',
          children: [
            SettingsTile(
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Sign out of your account',
              iconColor: Colors.blue,
              onTap: () => _logout(context),
            ),
            SettingsTile(
              icon: Icons.pause_circle_outline,
              title: 'Deactivate Account',
              subtitle: 'Temporarily hide your profile',
              iconColor: Colors.orange,
              onTap: () {
                // Show deactivate dialog
              },
            ),
            SettingsTile(
              icon: Icons.delete_outline,
              title: 'Delete Account',
              subtitle: 'Permanently remove your account',
              iconColor: Colors.red,
              onTap: () {
                // Show delete dialog
              },
            ),
          ],
        ),
      ],
    );
  }
}
