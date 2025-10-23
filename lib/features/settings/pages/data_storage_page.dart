import 'package:flutter/material.dart';
import '../widgets/settings_base_page.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_section.dart';

class DataStoragePage extends StatelessWidget {
  const DataStoragePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsBasePage(
      title: 'Data & Storage',
      children: [
        SettingsSection(
          title: 'Storage',
          children: [
            SettingsTile(
              icon: Icons.storage_outlined,
              title: 'Storage Usage',
              subtitle: 'View app data and cache',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.cleaning_services_outlined,
              title: 'Clear Cache',
              subtitle: 'Free up storage space',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.download_outlined,
              title: 'Manage Downloads',
              subtitle: 'View and delete downloaded items',
              onTap: () {},
            ),
          ],
        ),
        SettingsSection(
          title: 'Network',
          children: [
            SettingsTile(
              icon: Icons.wifi_outlined,
              title: 'Network Preferences',
              subtitle: 'Wi-Fi and data usage',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.data_saver_off_outlined,
              title: 'Data Saver',
              subtitle: 'Reduce data usage',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}
