import 'package:flutter/material.dart';
import '../widgets/settings_base_page.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_section.dart';

class AIPersonalizationPage extends StatelessWidget {
  const AIPersonalizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsBasePage(
      title: 'AI & Personalization',
      children: [
        SettingsSection(
          title: 'Feed Preferences',
          children: [
            SettingsTile(
              icon: Icons.interests_outlined,
              title: 'Interest Topics',
              subtitle: 'Choose what you want to see',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.recommend_outlined,
              title: 'Smart Recommendations',
              subtitle: 'AI-powered content suggestions',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.refresh_outlined,
              title: 'Reset Algorithm',
              subtitle: 'Start fresh with recommendations',
              onTap: () {},
            ),
          ],
        ),
        SettingsSection(
          title: 'Smart Features',
          children: [
            SettingsTile(
              icon: Icons.auto_awesome_outlined,
              title: 'Smart Captions',
              subtitle: 'AI-generated captions for media',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.smart_toy_outlined,
              title: 'AI Assistant',
              subtitle: 'Manage in-app assistant',
              onTap: () {},
            ),
          ],
        ),
        SettingsSection(
          title: 'Ad Personalization',
          children: [
            SettingsTile(
              icon: Icons.ad_units_outlined,
              title: 'Ad Preferences',
              subtitle: 'Manage ad personalization',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}
