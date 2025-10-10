import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'auth_service.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // ## HARDCODED LOGIN FOR TESTING ##
    // If the specific email and password are used, log in instantly.
    if (email == '1' && password == '1') {
      if (mounted) context.go('/home');
      return; // This bypasses the Firebase check
    }

    // --- Real Firebase Sign-In Logic ---
    // This will run for any other email and password.
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final user = await _authService.signInWithEmailAndPassword(email, password);

      setState(() {
        _isLoading = false;
      });

      if (user != null) {
        if (mounted) context.go('/home');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign-in failed. Please check your credentials.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Google Sign-In
  Future<void> _signInWithGoogle() async {
    if (_isLoading) return; // Prevent multiple clicks
    
    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting Google Sign-In...');
      final user = await _authService.signInWithGoogle();
      print('Sign-in completed. User: ${user?.email}');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });

      if (user != null) {
        print('User signed in successfully: ${user.email}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome ${user.displayName ?? user.email}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        // Navigate to home
        context.go('/home');
      } else {
        print('User is null - sign-in was canceled');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google sign-in was canceled'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error during Google Sign-In: $e');
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-in error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Microsoft Sign-In
  Future<void> _signInWithMicrosoft() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.signInWithMicrosoft();
      
      setState(() {
        _isLoading = false;
      });

      if (user != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome ${user.displayName ?? user.email}!'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microsoft sign-in failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Apple Sign-In
  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.signInWithApple();
      
      setState(() {
        _isLoading = false;
      });

      if (user != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome ${user.displayName ?? user.email}!'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Apple sign-in failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(prefixIcon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade200,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
    );
  }

  Widget _buildOAuthButton({
    required VoidCallback onPressed,
    required Widget child,
    Color? backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: backgroundColor == null
            ? Border.all(color: Colors.grey.shade300, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: child,
        iconSize: 48,
        onPressed: onPressed,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Lottie.asset('assets/lottie/login.json', height: 200),
                const SizedBox(height: 24),
                Text('Welcome Back!',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Log in to your account',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: _buildInputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icons.email_outlined,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your email';
                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: _buildInputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter your password' : null,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () => context.go('/forgot-password'), child: const Text('Forgot Password?')),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'Or continue with',
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google Sign-In Button
                    _buildOAuthButton(
                      onPressed: _signInWithGoogle,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4285F4), Color(0xFFDB4437), Color(0xFFF4B400), Color(0xFF0F9D58)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  foreground: Paint()
                                    ..shader = const LinearGradient(
                                      colors: [Color(0xFF4285F4), Color(0xFFDB4437), Color(0xFFF4B400), Color(0xFF0F9D58)],
                                    ).createShader(const Rect.fromLTWH(0, 0, 50, 50)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Microsoft Sign-In Button
                    _buildOAuthButton(
                      onPressed: _signInWithMicrosoft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 11,
                                height: 11,
                                color: const Color(0xFFF25022),
                              ),
                              const SizedBox(width: 2),
                              Container(
                                width: 11,
                                height: 11,
                                color: const Color(0xFF7FBA00),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 11,
                                height: 11,
                                color: const Color(0xFF00A4EF),
                              ),
                              const SizedBox(width: 2),
                              Container(
                                width: 11,
                                height: 11,
                                color: const Color(0xFFFFB900),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Apple Sign-In Button (iOS only)
                    if (Platform.isIOS) ...[
                      const SizedBox(width: 16),
                      _buildOAuthButton(
                        onPressed: _signInWithApple,
                        backgroundColor: Colors.black,
                        child: const Icon(Icons.apple, color: Colors.white, size: 28),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [ const Text("Don't have an account?"), TextButton(onPressed: () => context.go('/signup'), child: const Text('Sign Up'),)]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}