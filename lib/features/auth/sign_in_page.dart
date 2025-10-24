import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/preferences_service.dart';
import '../../core/services/database_service.dart';
import 'auth_service.dart';

// Import OAuthProvider enum
import 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final emailOrUsername = _emailOrUsernameController.text.trim();
    final password = _passwordController.text.trim();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String? email;

      // Check if input is email or username
      if (emailOrUsername.contains('@')) {
        // It's an email
        email = emailOrUsername;
      } else {
        // It's a username - look up the email
        try {
          final userModel = await _databaseService.getUserByUsername(
            emailOrUsername,
          );
          if (userModel != null) {
            email = userModel.email;
          } else {
            // Username not found
            setState(() {
              _isLoading = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Username not found. Please check and try again.',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              );
            }
            return;
          }
        } catch (e) {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Error: ${e.toString()}')),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      }

      // Now sign in with the email
      final user = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );

      setState(() {
        _isLoading = false;
      });

      if (user != null) {
        // Check if user exists in Supabase (they must have signed up properly)
        try {
          final supabaseUser = await Supabase.instance.client
              .from('users')
              .select()
              .eq('uid', user.uid)
              .maybeSingle();

          if (supabaseUser == null) {
            // User exists in Firebase but not in Supabase - they used OAuth without signup
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Please sign up first with this email address before signing in.',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange[700],
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'Sign Up',
                    textColor: Colors.white,
                    onPressed: () {
                      context.go('/signup');
                    },
                  ),
                ),
              );
              await _authService.signOut();
            }
            return;
          }
        } catch (e) {
          print('ERROR checking Supabase user: $e');
          // Continue with login even if Supabase check fails
        }

        // Check if email is verified
        if (!user.emailVerified) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please verify your email before signing in. Check your inbox for the verification link.',
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange[700],
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Resend',
                  textColor: Colors.white,
                  onPressed: () async {
                    try {
                      await user.sendEmailVerification();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Verification email sent!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      print('Error resending email: $e');
                    }
                  },
                ),
              ),
            );

            // Sign out the user since email is not verified
            await _authService.signOut();
          }
          return;
        }

        // Email is verified, proceed with login
        await PreferencesService.saveUserSession(
          userId: user.uid,
          email: user.email ?? email,
          name: user.displayName,
        );
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

  // Google Sign-In with Supabase OAuth
  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting Supabase Google OAuth...');

      // Use Supabase OAuth for Google
      // Don't specify redirectTo for mobile apps - Supabase handles it automatically
      final response = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (!response) {
        throw Exception('Google sign-in was cancelled');
      }

      // The OAuth flow will redirect to browser and back
      // Listen for auth state changes to handle the callback
      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        if (session != null && mounted) {
          print('Google OAuth successful! User: ${session.user.email}');

          final user = session.user;

          // Check if user exists in databases, if not create them
          try {
            var supabaseUser = await Supabase.instance.client
                .from('users')
                .select()
                .eq('uid', user.id)
                .maybeSingle();

            if (supabaseUser == null) {
              // Create new user in both databases
              print('Creating new user from Google OAuth...');

              // Extract username from email
              String username =
                  user.email?.split('@')[0] ??
                  'user${DateTime.now().millisecondsSinceEpoch}';

              // Save to Supabase
              await Supabase.instance.client.from('users').insert({
                'uid': user.id,
                'username': username.toLowerCase(),
                'username_display': username,
                'email': user.email?.toLowerCase() ?? '',
                'display_name': user.userMetadata?['full_name'] ?? username,
                'photo_url': user.userMetadata?['avatar_url'],
                'bio': '',
                'followers_count': 0,
                'following_count': 0,
                'posts_count': 0,
                'followers': [],
                'following': [],
                'created_at': DateTime.now().toIso8601String(),
                'last_active': DateTime.now().toIso8601String(),
              });
            }
          } catch (e) {
            print('Error checking/creating user: $e');
          }

          setState(() {
            _isLoading = false;
          });

          // Save session
          await PreferencesService.saveUserSession(
            userId: user.id,
            email: user.email ?? '',
            name: user.userMetadata?['full_name'] ?? user.email,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Welcome ${user.userMetadata?['full_name'] ?? user.email}!',
                ),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/home');
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Google OAuth error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Microsoft Sign-In (Disabled - needs Azure OAuth setup)
  Future<void> _signInWithMicrosoft() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microsoft sign-in is not configured yet'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return;

    // TODO: Set up Azure OAuth in Supabase first
    /*
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
    */ // End of commented Microsoft OAuth code
  }

  // Apple Sign-In (Disabled - needs Apple Developer setup)
  Future<void> _signInWithApple() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apple sign-in is not configured yet'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return;

    // TODO: Set up Apple OAuth in Supabase first
    /*
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
    */ // End of commented Apple OAuth code
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        color: isDark ? Colors.grey[400] : Colors.grey[700],
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? const Color(0xFF1A1D24) : Colors.grey.shade200,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[800]! : Colors.grey.shade300,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildOAuthButton({
    required VoidCallback onPressed,
    required Widget child,
    Color? backgroundColor,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (isDark ? const Color(0xFF1A1D24) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: backgroundColor == null
            ? Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey.shade300,
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.15),
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
                Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in to your account',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailOrUsernameController,
                  decoration: _buildInputDecoration(
                    labelText: 'Email or Username',
                    prefixIcon: Icons.person_outline,
                    context: context,
                  ),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email or username';
                    }
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
                    context: context,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your password'
                      : null,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go('/forgot-password'),
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _isLoading ? null : _signIn,
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
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                      context: context,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF4285F4),
                              Color(0xFFDB4437),
                              Color(0xFFF4B400),
                              Color(0xFF0F9D58),
                            ],
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
                                    ..shader =
                                        const LinearGradient(
                                          colors: [
                                            Color(0xFF4285F4),
                                            Color(0xFFDB4437),
                                            Color(0xFFF4B400),
                                            Color(0xFF0F9D58),
                                          ],
                                        ).createShader(
                                          const Rect.fromLTWH(0, 0, 50, 50),
                                        ),
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
                      context: context,
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
                        context: context,
                        child: const Icon(
                          Icons.apple,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () => context.go('/signup'),
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
