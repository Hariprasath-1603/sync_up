import 'package:flutter/material.dart';
import '../widgets/settings_base_page.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_section.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsBasePage(
      title: 'Notifications',
      children: [
        SettingsSection(
          title: 'Push Notifications',
          children: [
            SettingsTile(
              icon: Icons.favorite_outline,
              title: 'Likes & Comments',
              subtitle: 'When someone likes or comments',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.person_add_outlined,
              title: 'Followers',
              subtitle: 'New followers and requests',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.message_outlined,
              title: 'Direct Messages',
              subtitle: 'Message and call notifications',
              onTap: () {},
            ),
          ],
        ),
        SettingsSection(
          title: 'Other Notifications',
          children: [
            SettingsTile(
              icon: Icons.email_outlined,
              title: 'Email Notifications',
              subtitle: 'Weekly summaries and alerts',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.vibration_outlined,
              title: 'Sound & Vibration',
              subtitle: 'Notification sounds',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}
