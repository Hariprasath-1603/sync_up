import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../widgets/settings_base_page.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_section.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

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
                // Navigate to edit profile
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
