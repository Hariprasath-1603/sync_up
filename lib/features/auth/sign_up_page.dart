import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:country_picker/country_picker.dart';
import 'package:intl/intl.dart';

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
  final _locationController = TextEditingController();

  String? _selectedGender;
  String _countryCode = '91';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
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

  void _onSignUp() {
    if (_page2FormKey.currentState!.validate()) {
      print('Signing up with:');
      print('Username: ${_usernameController.text}');
      print('Email: ${_emailController.text}');
      print('DOB: ${_dobController.text}');
      print('Gender: $_selectedGender');
      print('Phone: +$_countryCode ${_phoneController.text}');
      print('Location: ${_locationController.text}');
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
      backgroundColor: colorScheme.background,
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
      color: theme.colorScheme.onBackground,
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
              decoration: _buildInputDecoration(
                hintText: 'Username',
                prefixIcon: Icons.person_outline,
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter a username' : null,
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
      color: theme.colorScheme.onBackground,
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
            Row(
              children: [
                InkWell(
                  onTap: () {
                    showCountryPicker(
                      context: context,
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
                    decoration: _buildInputDecoration(hintText: 'Phone Number'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a phone number';
                      }
                      // This is the new validation logic
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
            FilledButton(onPressed: _onSignUp, child: const Text('Sign Up')),
          ],
        ),
      ),
    );
  }
}
