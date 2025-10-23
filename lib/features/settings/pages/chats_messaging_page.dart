import 'package:flutter/material.dart';
import '../widgets/settings_base_page.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_section.dart';

class ChatsMessagingPage extends StatelessWidget {
  const ChatsMessagingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsBasePage(
      title: 'Chats & Messaging',
      children: [
        SettingsSection(
          title: 'Message Settings',
          children: [
            SettingsTile(
              icon: Icons.mail_outline,
              title: 'Message Requests',
              subtitle: 'Control who can message you',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.done_all_outlined,
              title: 'Read Receipts',
              subtitle: 'Show when you read messages',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.keyboard_outlined,
              title: 'Typing Indicators',
              subtitle: 'Show when you are typing',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.timer_outlined,
              title: 'Auto-Delete Messages',
              subtitle: 'Automatically delete old messages',
              onTap: () {},
            ),
          ],
        ),
        SettingsSection(
          title: 'Customization',
          children: [
            SettingsTile(
              icon: Icons.wallpaper_outlined,
              title: 'Chat Wallpaper',
              subtitle: 'Choose background for chats',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.archive_outlined,
              title: 'Archive & Blocked',
              subtitle: 'Manage archived and blocked chats',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}
