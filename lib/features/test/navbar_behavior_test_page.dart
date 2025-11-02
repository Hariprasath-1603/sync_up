import 'package:flutter/material.dart';
import '../../core/utils/bottom_sheet_utils.dart';

/// Test page to demonstrate and verify intelligent navbar behavior
class NavbarBehaviorTestPage extends StatelessWidget {
  const NavbarBehaviorTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B0E13)
          : const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Navbar Behavior Test'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader('Automatic Keyboard Detection'),
              const SizedBox(height: 12),
              _buildInfoCard(
                '✨ Type in the field below. The navbar will automatically hide when the keyboard appears and show when dismissed.',
                isDark,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Type something...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.keyboard),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionHeader('Bottom Sheet Tests'),
              const SizedBox(height: 12),
              _buildTestButton(
                context: context,
                label: '1. Simple Bottom Sheet',
                icon: Icons.view_agenda,
                onPressed: () => _showSimpleBottomSheet(context),
              ),
              const SizedBox(height: 12),
              _buildTestButton(
                context: context,
                label: '2. Premium Styled Sheet',
                icon: Icons.auto_awesome,
                onPressed: () => _showPremiumBottomSheet(context),
              ),
              const SizedBox(height: 12),
              _buildTestButton(
                context: context,
                label: '3. Sheet with Input',
                icon: Icons.edit,
                onPressed: () => _showInputBottomSheet(context),
              ),
              const SizedBox(height: 12),
              _buildTestButton(
                context: context,
                label: '4. Custom Modal',
                icon: Icons.stars,
                onPressed: () => _showCustomModal(context),
              ),
              const SizedBox(height: 32),

              _buildSectionHeader('Manual Controls'),
              const SizedBox(height: 12),
              _buildTestButton(
                context: context,
                label: 'Hide Navbar',
                icon: Icons.visibility_off,
                onPressed: () => context.hideNavBar(),
              ),
              const SizedBox(height: 12),
              _buildTestButton(
                context: context,
                label: 'Show Navbar',
                icon: Icons.visibility,
                onPressed: () => context.showNavBar(),
              ),
              const SizedBox(height: 12),
              _buildTestButton(
                context: context,
                label: 'Toggle Navbar',
                icon: Icons.swap_vert,
                onPressed: () => context.toggleNavBar(),
              ),
              const SizedBox(height: 32),

              _buildInfoCard(
                '💡 Current navbar state: ${context.isNavBarVisible ? 'Visible' : 'Hidden'}',
                isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoCard(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.blue.withOpacity(0.1)
            : Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.blue[200] : Colors.blue[900],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _showSimpleBottomSheet(BuildContext context) async {
    await BottomSheetUtils.showAdaptiveBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Simple Bottom Sheet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Notice how the navbar smoothly hides!'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPremiumBottomSheet(BuildContext context) async {
    await BottomSheetUtils.showAdaptiveBottomSheet(
      context: context,
      withBlur: true,
      builder: (context) => BottomSheetUtils.createPremiumBottomSheet(
        context: context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Premium Bottom Sheet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('With glassmorphic design and blur effect'),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.thumb_up),
                  label: const Text('Like'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInputBottomSheet(BuildContext context) async {
    final controller = TextEditingController();

    await BottomSheetUtils.showAdaptiveBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: BottomSheetUtils.createPremiumBottomSheet(
          context: context,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter Comment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Type your comment...',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final text = controller.text;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Posted: $text')));
                    },
                    child: const Text('Post'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCustomModal(BuildContext context) async {
    await BottomSheetUtils.showCustomModal(
      context: context,
      withBlur: true,
      withScaleTransition: true,
      withFadeTransition: true,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.rocket_launch, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Custom Modal!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('With scale and fade animations'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Awesome!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
