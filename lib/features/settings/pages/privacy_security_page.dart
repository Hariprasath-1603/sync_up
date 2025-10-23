import 'package:flutter/material.dart';
import '../widgets/settings_base_page.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_section.dart';

class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsBasePage(
      title: 'Privacy & Security',
      children: [
        SettingsSection(
          title: 'Privacy Controls',
          children: [
            SettingsTile(
              icon: Icons.lock_outline,
              title: 'Profile Privacy',
              subtitle: 'Public or Private account',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.block_outlined,
              title: 'Blocked Accounts',
              subtitle: 'Manage blocked users',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.visibility_off_outlined,
              title: 'Muted / Restricted',
              subtitle: 'Manage muted and restricted accounts',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.circle_outlined,
              title: 'Activity Status',
              subtitle: 'Show when active',
              onTap: () {},
            ),
          ],
        ),
        SettingsSection(
          title: 'Content Privacy',
          children: [
            SettingsTile(
              icon: Icons.auto_stories_outlined,
              title: 'Story Privacy',
              subtitle: 'Control who can see your stories',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.image_outlined,
              title: 'Post Visibility',
              subtitle: 'Comments, tags, mentions',
              onTap: () {},
            ),
          ],
        ),
        SettingsSection(
          title: 'Data & Security',
          children: [
            SettingsTile(
              icon: Icons.download_outlined,
              title: 'Download Data',
              subtitle: 'Request a copy of your data',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.notification_important_outlined,
              title: 'Login Alerts',
              subtitle: 'Get notified of new logins',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}
