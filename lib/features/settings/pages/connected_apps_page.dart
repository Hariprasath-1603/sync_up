import 'package:flutter/material.dart';
import '../widgets/settings_base_page.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_section.dart';

class ConnectedAppsPage extends StatelessWidget {
  const ConnectedAppsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsBasePage(
      title: 'Connected Apps & Devices',
      children: [
        SettingsSection(
          title: 'Connected Accounts',
          children: [
            SettingsTile(
              icon: Icons.link_outlined,
              title: 'Linked Accounts',
              subtitle: 'Facebook, Google, Apple, X',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.apps_outlined,
              title: 'Third-Party Access',
              subtitle: 'Apps with permission to your account',
              onTap: () {},
            ),
          ],
        ),
        SettingsSection(
          title: 'Devices',
          children: [
            SettingsTile(
              icon: Icons.devices_outlined,
              title: 'Connected Devices',
              subtitle: 'Manage logged in devices',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.qr_code_outlined,
              title: 'QR Code Login',
              subtitle: 'Scan to login on web',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}
