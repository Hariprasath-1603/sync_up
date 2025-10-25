import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SetupBioPage extends StatefulWidget {
  const SetupBioPage({super.key});

  @override
  State<SetupBioPage> createState() => _SetupBioPageState();
}

class _SetupBioPageState extends State<SetupBioPage> {
  final _bioController = TextEditingController();
  bool _isSaving = false;
  final int _maxBioLength = 150;

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    final bio = _bioController.text.trim();

    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Update user record with bio (even if empty)
      await Supabase.instance.client
          .from('users')
          .update({
            'bio': bio.isNotEmpty ? bio : '',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('uid', user.id);

      print('✅ Bio updated: ${bio.isNotEmpty ? bio : "(empty)"}');

      if (mounted) {
        // Profile setup complete - go to home
        context.go('/home');
      }
    } catch (e) {
      print('❌ Error saving bio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving bio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final remainingChars = _maxBioLength - _bioController.text.length;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        'Tell us about yourself',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Write a short bio to let others know more about you',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 48),
                      TextField(
                        controller: _bioController,
                        maxLines: 5,
                        maxLength: _maxBioLength,
                        decoration: InputDecoration(
                          hintText:
                              'E.g. "Coffee lover ☕ | Travel enthusiast 🌍 | Dog parent 🐕"',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withOpacity(
                              0.6,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          counterText: '',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$remainingChars characters remaining',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: remainingChars < 20
                                  ? Colors.orange
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (_bioController.text.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _bioController.clear();
                                });
                              },
                              child: const Text('Clear'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your bio helps others get to know you better!',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  FilledButton(
                    onPressed: _isSaving ? null : _saveAndContinue,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _bioController.text.trim().isEmpty
                                ? 'Skip'
                                : 'Continue',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  if (_bioController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isSaving ? null : () => context.go('/home'),
                      child: const Text('Skip for now'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
