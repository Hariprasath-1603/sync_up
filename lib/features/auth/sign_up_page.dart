import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:country_picker/country_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/database_service.dart';
import '../../core/models/user_model.dart';
import 'auth_service.dart';
import 'dart:async';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final PageController _pageController = PageController();
  final _page1FormKey = GlobalKey<FormState>();
  final _page2FormKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _locationController = TextEditingController();

  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  String? _selectedGender;
  String _countryCode = '91';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // Phone verification states
  bool _isOtpSent = false;
  bool _isPhoneVerified = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  String? _phoneError;

  // Username validation states
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _usernameError;
  Timer? _usernameDebounce;

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _locationController.dispose();
    _usernameDebounce?.cancel();
    super.dispose();
  }

  // Check username availability with debounce
  void _checkUsernameAvailability(String username) {
    // Cancel previous timer
    _usernameDebounce?.cancel();

    // Validate format first
    final formatError = _databaseService.validateUsernameFormat(username);
    if (formatError != null) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = false;
        _usernameError = formatError;
      });
      return;
    }

    // Start checking availability after 500ms delay
    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      final isAvailable = await _databaseService.isUsernameAvailable(username);

      if (!mounted) return;

      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = isAvailable;
        _usernameError = isAvailable ? null : 'Username is already taken';
      });
    });
  }

  void _goToNextPage() {
    if (_page1FormKey.currentState!.validate()) {
      // Check if phone is verified before moving to next page
      if (_phoneController.text.isNotEmpty && !_isPhoneVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify your phone number before continuing'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _goToPreviousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // Send OTP via Twilio through Supabase Edge Function
  Future<void> _sendOTP() async {
    if (_phoneController.text.isEmpty) {
      setState(() {
        _phoneError = 'Please enter a phone number';
      });
      return;
    }

    if (_phoneController.text.length < 7) {
      setState(() {
        _phoneError = 'Please enter a valid phone number';
      });
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _phoneError = null;
    });

    try {
      final phoneNumber = '+$_countryCode${_phoneController.text.trim()}';

      // Call Supabase Edge Function to send OTP via Twilio
      final response = await Supabase.instance.client.functions.invoke(
        'send-otp',
        body: {'phone': phoneNumber},
      );

      if (response.status == 200) {
        setState(() {
          _isOtpSent = true;
          _isSendingOtp = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent successfully! Check your phone.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to send OTP');
      }
    } catch (e) {
      print('Error sending OTP: $e');
      setState(() {
        _isSendingOtp = false;
        _phoneError = 'Failed to send OTP. Please try again.';
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

  // Verify OTP via Twilio through Supabase Edge Function
  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the OTP code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      final phoneNumber = '+$_countryCode${_phoneController.text.trim()}';

      // Call Supabase Edge Function to verify OTP via Twilio
      final response = await Supabase.instance.client.functions.invoke(
        'verify-otp',
        body: {'phone': phoneNumber, 'code': _otpController.text.trim()},
      );

      if (response.status == 200) {
        setState(() {
          _isPhoneVerified = true;
          _isVerifyingOtp = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone verified successfully! ✓'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Invalid OTP code');
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      setState(() {
        _isVerifyingOtp = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onSignUp() async {
    if (_page2FormKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        print('DEBUG: Starting signup process...');
        print('DEBUG: Email: ${_emailController.text.trim()}');
        print('DEBUG: Username: ${_usernameController.text.trim()}');

        // Create Firebase Auth account
        print('DEBUG: Creating Firebase Auth account...');
        final firebaseUser = await _authService.signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (firebaseUser == null) {
          print('ERROR: Firebase Auth returned null user');
          throw Exception(
            'Failed to create Firebase account. Please try again.',
          );
        }

        print('DEBUG: Firebase user created with UID: ${firebaseUser.uid}');

        // Send email verification
        print('DEBUG: Sending verification email...');
        try {
          await firebaseUser.sendEmailVerification();
          print('SUCCESS: Verification email sent to: ${firebaseUser.email}');
        } catch (emailError) {
          print('WARNING: Email verification send failed: $emailError');
          // Continue even if email fails - user can resend later
        }

        // Create user model
        print('DEBUG: Creating user model...');
        final userModel = UserModel.fromFirebaseUser(
          uid: firebaseUser.uid,
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          displayName: _usernameController.text.trim(),
          dateOfBirth: _dobController.text,
          gender: _selectedGender,
          phone: _phoneController.text.isNotEmpty
              ? '+$_countryCode${_phoneController.text.trim()}'
              : null,
          location: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : null,
        );

        print('DEBUG: User model created, saving to databases...');

        // Save user to Firestore
        final success = await _databaseService.createUser(userModel);

        if (!success) {
          print('ERROR: Failed to save user to Firestore');
          // Delete Firebase Auth account if Firestore save fails
          print(
            'DEBUG: Deleting Firebase Auth account due to Firestore failure...',
          );
          await firebaseUser.delete();
          throw Exception(
            'Username is already taken or database error. Please try a different username.',
          );
        }

        print('SUCCESS: User document saved to Firestore');

        // Also save to Supabase database
        print('DEBUG: Saving user to Supabase...');
        try {
          await Supabase.instance.client.from('users').insert({
            'uid': firebaseUser.uid,
            'username': _usernameController.text.trim().toLowerCase(),
            'username_display': _usernameController.text.trim(),
            'email': _emailController.text.trim().toLowerCase(),
            'display_name': _usernameController.text.trim(),
            'bio': '',
            'date_of_birth': _dobController.text.isNotEmpty
                ? _dobController.text
                : null,
            'gender': _selectedGender,
            'phone': _phoneController.text.isNotEmpty
                ? '+$_countryCode${_phoneController.text.trim()}'
                : null,
            'phone_verified':
                _isPhoneVerified, // Save phone verification status
            'location': _locationController.text.trim().isNotEmpty
                ? _locationController.text.trim()
                : null,
            'photo_url': null,
            'followers_count': 0,
            'following_count': 0,
            'posts_count': 0,
            'followers': [],
            'following': [],
            'created_at': DateTime.now().toIso8601String(),
            'last_active': DateTime.now().toIso8601String(),
          });
          print('SUCCESS: User saved to Supabase database');
        } catch (supabaseError) {
          print('ERROR: Supabase save failed: $supabaseError');
          // Don't fail signup if Supabase fails, just log it
        }

        print('SUCCESS: User document saved to databases');

        if (!mounted) return;

        print('DEBUG: Navigating to email verification page...');
        // Navigate to email verification page
        context.go(
          '/email-verification?email=${Uri.encodeComponent(_emailController.text.trim())}',
        );
      } on FirebaseAuthException catch (e) {
        print(
          'ERROR: FirebaseAuthException - Code: ${e.code}, Message: ${e.message}',
        );
        if (!mounted) return;

        String errorMessage = 'An error occurred during signup.';

        // Handle specific Firebase Auth errors
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage =
                'This email is already registered. Please sign in instead.';
            break;
          case 'weak-password':
            errorMessage =
                'Password is too weak. Please use at least 6 characters.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address. Please check and try again.';
            break;
          case 'operation-not-allowed':
            errorMessage =
                'Email/password accounts are not enabled. Please contact support.';
            break;
          case 'network-request-failed':
            errorMessage =
                'Network error. Please check your internet connection.';
            break;
          default:
            errorMessage =
                e.message ?? 'Failed to create account. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Help',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Signup Error'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(errorMessage),
                          const SizedBox(height: 16),
                          Text(
                            'Error Code: ${e.code}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Common Solutions:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('• Try a different email address'),
                          const Text(
                            '• Use a stronger password (6+ characters)',
                          ),
                          const Text('• Check your internet connection'),
                          const Text('• Make sure Firebase Auth is enabled'),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      } on Exception catch (e) {
        print('ERROR: Exception during signup: $e');
        if (!mounted) return;

        String errorMessage = e.toString().replaceAll('Exception: ', '');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      } catch (e) {
        print('ERROR: Unknown error during signup: $e');
        if (!mounted) return;

        String errorMessage =
            'An error occurred during signup. Please try again.';

        // Check for common Firebase errors
        if (e.toString().contains('email-already-in-use')) {
          errorMessage =
              'This email is already registered. Please sign in instead.';
        } else if (e.toString().contains('weak-password')) {
          errorMessage =
              'Password is too weak. Please use a stronger password.';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Invalid email address. Please check and try again.';
        } else if (e.toString().contains('network')) {
          errorMessage =
              'Network error. Please check your internet connection.';
        } else if (e.toString().contains('permission-denied') ||
            e.toString().contains('PERMISSION_DENIED')) {
          errorMessage =
              'Database not configured. Please enable Firestore in Firebase Console.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Help',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Signup Error'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(errorMessage),
                          const SizedBox(height: 16),
                          const Text(
                            'Common Solutions:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('• Enable Firestore in Firebase Console'),
                          const Text('• Check your internet connection'),
                          const Text('• Try a different username'),
                          const Text(
                            '• Verify all fields are filled correctly',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Technical details: $e',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  double _calculatePasswordStrength(String password) {
    double strength = 0;
    if (password.isEmpty) return 0;
    if (password.length >= 6) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[!@#\$&*~]').hasMatch(password)) strength += 0.25;
    return strength.clamp(0, 1);
  }

  Color _getStrengthColor(double strength) {
    if (strength < 0.3) return Colors.red;
    if (strength < 0.7) return Colors.orange;
    return Colors.green;
  }

  String _getStrengthLabel(double strength) {
    if (strength < 0.3) return 'Weak';
    if (strength < 0.7) return 'Medium';
    return 'Strong';
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isDark = colorScheme.brightness == Brightness.dark;
    final Color baseSurface = colorScheme.surface;
    final Color fillColor = Color.alphaBlend(
      colorScheme.onSurface.withOpacity(isDark ? 0.08 : 0.04),
      baseSurface,
    );
    final Color iconColor = colorScheme.onSurfaceVariant;

    return InputDecoration(
      hintText: hintText,
      hintStyle: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface.withOpacity(0.6),
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: iconColor)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () {
            if (_pageController.hasClients && _pageController.page == 1.0) {
              _goToPreviousPage();
            } else {
              context.go('/signin');
            }
          },
        ),
        title: Text(
          'Create Account',
          style: theme.textTheme.titleMedium?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [_buildAccountDetailsPage(), _buildPersonalDetailsPage()],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final neutralColor = theme.colorScheme.onSurface.withOpacity(0.14);
    double strength = _calculatePasswordStrength(_passwordController.text);
    Color strengthColor = _getStrengthColor(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: strength > 0 ? strengthColor : neutralColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: strength >= 0.5 ? strengthColor : neutralColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: strength >= 0.75 ? strengthColor : neutralColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _getStrengthLabel(strength),
          style: TextStyle(
            fontSize: 12,
            color: strengthColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountDetailsPage() {
    final theme = Theme.of(context);
    final headingStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _page1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Lottie.asset('assets/lottie/login.json', height: 150),
            const SizedBox(height: 24),
            Text(
              'Account Details (1/2)',
              textAlign: TextAlign.center,
              style: headingStyle,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _usernameController,
              decoration:
                  _buildInputDecoration(
                    hintText: 'Username',
                    prefixIcon: Icons.person_outline,
                  ).copyWith(
                    suffixIcon: _isCheckingUsername
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _isUsernameAvailable == true
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : _isUsernameAvailable == false
                        ? const Icon(Icons.cancel, color: Colors.red)
                        : null,
                    helperText: _isUsernameAvailable == true
                        ? 'Username is available'
                        : null,
                    helperStyle: const TextStyle(color: Colors.green),
                    errorText: _usernameError,
                  ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _checkUsernameAvailability(value);
                } else {
                  setState(() {
                    _isUsernameAvailable = null;
                    _usernameError = null;
                    _isCheckingUsername = false;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a username';
                }
                if (_usernameError != null) {
                  return _usernameError;
                }
                if (_isUsernameAvailable == false) {
                  return 'Username is already taken';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: _buildInputDecoration(
                hintText: 'Email',
                prefixIcon: Icons.email_outlined,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value!.isEmpty) return 'Please enter an email';
                if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: _buildInputDecoration(
                hintText: 'Password',
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              onChanged: (value) => setState(() {}),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter a password' : null,
            ),
            const SizedBox(height: 8),
            if (_passwordController.text.isNotEmpty)
              _buildPasswordStrengthIndicator(context),
            const SizedBox(height: 20),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              decoration: _buildInputDecoration(
                hintText: 'Confirm Password',
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(
                    () =>
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                  ),
                ),
              ),
              validator: (value) {
                if (value!.isEmpty) return 'Please confirm your password';
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            FilledButton(onPressed: _goToNextPage, child: const Text('Next')),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDetailsPage() {
    final theme = Theme.of(context);
    final headingStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
    );
    final borderColor = theme.colorScheme.outline.withOpacity(0.5);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _page2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Lottie.asset('assets/lottie/login.json', height: 150),
            const SizedBox(height: 24),
            Text(
              'Personal Details (2/2)',
              textAlign: TextAlign.center,
              style: headingStyle,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _dobController,
              readOnly: true,
              decoration: _buildInputDecoration(
                hintText: 'Date of Birth',
                prefixIcon: Icons.cake_outlined,
              ),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  _dobController.text = DateFormat(
                    'yyyy-MM-dd',
                  ).format(pickedDate);
                }
              },
              validator: (value) =>
                  value!.isEmpty ? 'Please select your date of birth' : null,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              decoration: _buildInputDecoration(
                hintText: 'Gender',
                prefixIcon: Icons.person_search_outlined,
              ),
              items: ['Male', 'Female', 'Other']
                  .map(
                    (gender) =>
                        DropdownMenuItem(value: gender, child: Text(gender)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedGender = value),
              validator: (value) =>
                  value == null ? 'Please select a gender' : null,
            ),
            const SizedBox(height: 20),

            // Phone Number with OTP Verification
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    showCountryPicker(
                      context: context,
                      showPhoneCode: true,
                      onSelect: (Country country) {
                        setState(() {
                          _countryCode = country.phoneCode;
                        });
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+$_countryCode',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    enabled: !_isPhoneVerified, // Disable after verification
                    decoration: _buildInputDecoration(hintText: 'Phone Number')
                        .copyWith(
                          suffixIcon: _isPhoneVerified
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : null,
                          errorText: _phoneError,
                        ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a phone number';
                      }
                      if (value.length < 7 || value.length > 15) {
                        return 'Please enter a valid phone number';
                      }
                      if (!_isPhoneVerified) {
                        return 'Please verify your phone number';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      // Reset verification when phone changes
                      if (_isPhoneVerified || _isOtpSent) {
                        setState(() {
                          _isPhoneVerified = false;
                          _isOtpSent = false;
                          _otpController.clear();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Get OTP Button
                if (!_isPhoneVerified)
                  ElevatedButton(
                    onPressed: _isSendingOtp || _isOtpSent ? null : _sendOTP,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSendingOtp
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isOtpSent ? 'Sent' : 'Get OTP'),
                  ),
              ],
            ),

            // OTP Input Field (shown after OTP is sent)
            if (_isOtpSent && !_isPhoneVerified) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: _buildInputDecoration(
                        hintText: 'Enter OTP Code',
                        prefixIcon: Icons.lock_outline,
                      ).copyWith(counterText: ''),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isVerifyingOtp ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isVerifyingOtp
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Verify',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isSendingOtp ? null : _sendOTP,
                child: const Text('Resend OTP'),
              ),
            ],

            const SizedBox(height: 20),

            // Reverted Location Field
            TextFormField(
              controller: _locationController,
              decoration: _buildInputDecoration(
                hintText: 'Location',
                prefixIcon: Icons.location_on_outlined,
              ),
            ),

            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isLoading ? null : _onSignUp,
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
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
