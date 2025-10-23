import 'package:flutter/material.dart';
import '../widgets/settings_base_page.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_section.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsBasePage(
      title: 'About & App Info',
      children: [
        SettingsSection(
          title: 'App Information',
          children: [
            SettingsTile(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: 'v1.0.0',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.code_outlined,
              title: 'Developer Info',
              subtitle: 'About the development team',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.description_outlined,
              title: 'Licenses',
              subtitle: 'Open source libraries',
              onTap: () {},
            ),
          ],
        ),
        SettingsSection(
          title: 'Legal',
          children: [
            SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'How we handle your data',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.article_outlined,
              title: 'Terms of Service',
              subtitle: 'Terms and conditions',
              onTap: () {},
            ),
          ],
        ),
        SettingsSection(
          title: 'Feedback',
          children: [
            SettingsTile(
              icon: Icons.star_outline,
              title: 'Rate Us',
              subtitle: 'Leave a review on the store',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}
