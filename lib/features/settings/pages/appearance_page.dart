import 'package:flutter/material.dart';
import '../widgets/settings_base_page.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_section.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsBasePage(
      title: 'Appearance & Display',
      children: [
        SettingsSection(
          title: 'Theme',
          children: [
            SettingsTile(
              icon: Icons.dark_mode_outlined,
              title: 'App Theme',
              subtitle: 'Light, Dark, or System default',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.color_lens_outlined,
              title: 'Accent Color',
              subtitle: 'Choose app accent color',
              onTap: () {},
            ),
          ],
        ),
        SettingsSection(
          title: 'Display',
          children: [
            SettingsTile(
              icon: Icons.text_fields_outlined,
              title: 'Font & Layout',
              subtitle: 'Text size and layout preferences',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.language_outlined,
              title: 'Language',
              subtitle: 'Choose app language',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.auto_awesome_outlined,
              title: 'Auto-Play & Animations',
              subtitle: 'Control video and animation behavior',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}
