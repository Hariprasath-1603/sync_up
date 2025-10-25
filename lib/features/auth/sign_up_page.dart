import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:country_picker/country_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedGender;
  String _countryCode = '91';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // Username validation states
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _usernameError;
  Timer? _usernameDebounce;

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _usernameDebounce?.cancel();
    super.dispose();
  }

  // Check username availability with debounce
  // Helper method to validate username format
  String? _validateUsernameFormat(String username) {
    if (username.isEmpty) {
      return 'Username cannot be empty';
    }
    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (username.length > 30) {
      return 'Username must be less than 30 characters';
    }
    // Only allow alphanumeric, underscore, and period
    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(username)) {
      return 'Username can only contain letters, numbers, dots, and underscores';
    }
    // Must start with a letter or number
    if (!RegExp(r'^[a-zA-Z0-9]').hasMatch(username)) {
      return 'Username must start with a letter or number';
    }
    // Cannot end with a period or underscore
    if (username.endsWith('.') || username.endsWith('_')) {
      return 'Username cannot end with a dot or underscore';
    }
    // Cannot have consecutive periods or underscores
    if (username.contains('..') || username.contains('__')) {
      return 'Username cannot have consecutive dots or underscores';
    }
    return null;
  }

  // Helper method to check username availability in Supabase
  Future<bool> _checkUsernameInDatabase(String username) async {
    try {
      final normalizedUsername = username.toLowerCase().trim();
      final result = await Supabase.instance.client
          .from('users')
          .select('username')
          .eq('username', normalizedUsername)
          .maybeSingle();

      return result == null;
    } catch (e) {
      print('Error checking username availability: $e');
      return false;
    }
  }

  void _checkUsernameAvailability(String username) {
    // Cancel previous timer
    _usernameDebounce?.cancel();

    // Validate format first
    final formatError = _validateUsernameFormat(username);
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
      final isAvailable = await _checkUsernameInDatabase(username);

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

  Future<void> _onSignUp() async {
    if (_page2FormKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        print('DEBUG: Starting Supabase signup process...');
        print('DEBUG: Email: ${_emailController.text.trim()}');
        print('DEBUG: Username: ${_usernameController.text.trim()}');

        // Check if username is already taken
        print('DEBUG: Checking username availability...');
        final existingUsers = await Supabase.instance.client
            .from('users')
            .select('username')
            .eq('username', _usernameController.text.trim().toLowerCase())
            .maybeSingle();

        if (existingUsers != null) {
          throw Exception(
            'Username "${_usernameController.text.trim()}" is already taken. Please choose another.',
          );
        }

        final phoneNumber = '+$_countryCode${_phoneController.text.trim()}';

        // Store user metadata for OTP verification page
        final userMetadata = {
          'full_name': _fullNameController.text.trim(),
          'username': _usernameController.text.trim().toLowerCase(),
          'username_display': _usernameController.text.trim(),
          'display_name': _fullNameController.text
              .trim(), // Use full name as display name
          'date_of_birth': _dobController.text.isNotEmpty
              ? _dobController.text
              : null,
          'gender': _selectedGender,
          'phone': phoneNumber,
          'location': _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : null,
        };

        // Create user account with email and password, and send email OTP for verification
        print('DEBUG: Creating user account with email and password...');
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          data: userMetadata, // Attach user metadata
          emailRedirectTo: null,
        );

        if (authResponse.user == null) {
          throw Exception('Failed to create user account');
        }

        print(
          'SUCCESS: User account created. Email OTP sent to: ${_emailController.text.trim()}',
        );

        // Send Phone OTP via Twilio - will be sent when user switches to phone tab
        print('DEBUG: Phone OTP will be sent from OTP verification page');

        if (!mounted) return;

        print('DEBUG: Navigating to OTP verification page...');
        // Navigate to unified OTP verification page
        // User metadata is stored in Supabase auth and will be used by OTP page
        context.go(
          '/otp-verification?email=${Uri.encodeComponent(_emailController.text.trim())}&phone=${Uri.encodeComponent(phoneNumber)}',
        );
      } on AuthException catch (e) {
        print(
          'ERROR: AuthException - Code: ${e.statusCode}, Message: ${e.message}',
        );
        if (!mounted) return;

        String errorMessage = 'An error occurred during signup.';

        // Handle specific Supabase Auth errors
        if (e.message.contains('already registered') ||
            e.message.contains('already exists')) {
          errorMessage =
              'This email is already registered. Please sign in instead.';
        } else if (e.message.contains('Password')) {
          errorMessage =
              'Password is too weak. Please use at least 6 characters.';
        } else if (e.message.contains('email')) {
          errorMessage = 'Invalid email address. Please check and try again.';
        } else if (e.message.contains('network') ||
            e.message.contains('timeout')) {
          errorMessage =
              'Network error. Please check your internet connection.';
        } else {
          errorMessage = e.message;
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
                            'Status Code: ${e.statusCode}',
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
                          const Text('• Try again in a few moments'),
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
      } on PostgrestException catch (e) {
        print(
          'ERROR: PostgrestException - Code: ${e.code}, Message: ${e.message}',
        );
        if (!mounted) return;

        String errorMessage = e.message;

        // Handle database errors
        if (e.message.contains('duplicate') || e.message.contains('unique')) {
          errorMessage =
              'Username is already taken. Please try a different username.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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

        // Check for common errors
        if (e.toString().contains('already')) {
          errorMessage =
              'This email or username is already registered. Please sign in instead.';
        } else if (e.toString().contains('password')) {
          errorMessage =
              'Password is too weak. Please use a stronger password.';
        } else if (e.toString().contains('email')) {
          errorMessage = 'Invalid email address. Please check and try again.';
        } else if (e.toString().contains('network') ||
            e.toString().contains('timeout')) {
          errorMessage =
              'Network error. Please check your internet connection.';
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
                          const Text('• Try a different email or username'),
                          const Text('• Check your internet connection'),
                          const Text('• Use a stronger password'),
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
              controller: _fullNameController,
              decoration: _buildInputDecoration(
                hintText: 'Full Name',
                prefixIcon: Icons.badge_outlined,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
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

            // Phone Number (No inline verification)
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
                    decoration: _buildInputDecoration(
                      hintText: 'Phone Number',
                      prefixIcon: Icons.phone_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a phone number';
                      }
                      if (value.length < 7 || value.length > 15) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

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
