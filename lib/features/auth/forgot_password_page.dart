import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _useEmail = true; // Toggle between email and username

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Use the new method that supports both email and username
        final error = await _authService.sendPasswordResetByIdentifier(
          _identifierController.text.trim(),
        );

        if (!mounted) return;

        if (error == null) {
          // Success - show success dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              icon: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
              title: const Text('Email Sent!'),
              content: Text(
                'A password reset link has been sent to your email address.\n\nPlease check your inbox and follow the instructions.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    context.go('/signin');
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Lottie.asset('assets/lottie/search.json', height: 200),
              const SizedBox(height: 24),
              Text(
                'Forgot Your Password?',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enter your email or username below and we will send you a link to reset your password.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Toggle buttons for Email/Username
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Email'),
                    icon: Icon(Icons.email_outlined),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Username'),
                    icon: Icon(Icons.person_outline),
                  ),
                ],
                selected: {_useEmail},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _useEmail = newSelection.first;
                    _identifierController.clear();
                  });
                },
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _identifierController,
                decoration: InputDecoration(
                  labelText: _useEmail ? 'Email' : 'Username',
                  prefixIcon: Icon(
                    _useEmail ? Icons.email_outlined : Icons.person_outline,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withOpacity(
                    0.3,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                keyboardType: _useEmail
                    ? TextInputType.emailAddress
                    : TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return _useEmail
                        ? 'Please enter your email'
                        : 'Please enter your username';
                  }
                  if (_useEmail && !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              FilledButton(
                onPressed: _isLoading ? null : _sendResetLink,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'Send Reset Link',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => context.go('/signin'),
                child: const Text('Back to Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
