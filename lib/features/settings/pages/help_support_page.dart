import 'package:flutter/material.dart';
import '../widgets/settings_base_page.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_section.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsBasePage(
      title: 'Help & Support',
      children: [
        SettingsSection(
          title: 'Get Help',
          children: [
            SettingsTile(
              icon: Icons.report_problem_outlined,
              title: 'Report a Problem',
              subtitle: 'Report bugs or issues',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.help_outline,
              title: 'FAQs',
              subtitle: 'Frequently asked questions',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.school_outlined,
              title: 'Tutorials',
              subtitle: 'Learn how to use the app',
              onTap: () {},
            ),
          ],
        ),
        SettingsSection(
          title: 'Contact',
          children: [
            SettingsTile(
              icon: Icons.support_agent_outlined,
              title: 'Contact Support',
              subtitle: 'Chat with our support team',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.gavel_outlined,
              title: 'Community Guidelines',
              subtitle: 'Rules and policies',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}
