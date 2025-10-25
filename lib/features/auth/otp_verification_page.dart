import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../core/services/preferences_service.dart';

/// Unified OTP verification page for both email and phone verification
/// Users must verify both before completing signup
class OtpVerificationPage extends StatefulWidget {
  final String email;
  final String phone;
  final Map<String, dynamic> userData;

  const OtpVerificationPage({
    super.key,
    required this.email,
    required this.phone,
    required this.userData,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage>
    with SingleTickerProviderStateMixin {
  final _emailOtpController = TextEditingController();
  final _phoneOtpController = TextEditingController();

  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;
  bool _isVerifyingEmail = false;
  bool _isVerifyingPhone = false;
  bool _isResendingEmail = false;
  bool _isResendingPhone = false;
  bool _isCompletingSignup = false;

  int _emailCooldown = 0;
  int _phoneCooldown = 0;
  Timer? _emailTimer;
  Timer? _phoneTimer;

  late TabController _tabController;
  bool _phoneOtpSent = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen to tab changes to send phone OTP when user switches to phone tab
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_phoneOtpSent && !_isPhoneVerified) {
        _sendPhoneOtpOnTabSwitch();
      }
    });
  }

  // Automatically send phone OTP when user switches to phone tab
  Future<void> _sendPhoneOtpOnTabSwitch() async {
    if (_phoneOtpSent) return; // Already sent

    setState(() => _phoneOtpSent = true);

    try {
      print('DEBUG: Auto-sending Phone OTP on tab switch...');
      final response = await Supabase.instance.client.functions.invoke(
        'send-otp',
        body: {'phone': widget.phone},
      );

      if (response.status == 200) {
        print('SUCCESS: Phone OTP sent automatically');
        _showSnackBar('Phone OTP sent! Check your SMS.', Colors.green);
      } else {
        print('WARNING: Failed to auto-send phone OTP');
        setState(() => _phoneOtpSent = false); // Allow retry
      }
    } catch (e) {
      print('ERROR: Auto-sending phone OTP failed: $e');
      setState(() => _phoneOtpSent = false); // Allow retry
    }
  }

  @override
  void dispose() {
    _emailOtpController.dispose();
    _phoneOtpController.dispose();
    _emailTimer?.cancel();
    _phoneTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // Verify Email OTP using Supabase
  Future<void> _verifyEmailOtp() async {
    if (_emailOtpController.text.isEmpty ||
        _emailOtpController.text.length != 6) {
      _showSnackBar('Please enter a valid 6-digit OTP', Colors.orange);
      return;
    }

    setState(() => _isVerifyingEmail = true);

    try {
      // Verify email OTP with Supabase
      final response = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.signup,
        token: _emailOtpController.text.trim(),
        email: widget.email,
      );

      if (response.user != null) {
        setState(() {
          _isEmailVerified = true;
          _isVerifyingEmail = false;
        });

        _showSnackBar('Email verified successfully! ✓', Colors.green);

        // Update verification status in database
        await _updateVerificationStatus();

        // Auto-switch to phone tab if not verified yet
        if (!_isPhoneVerified) {
          await Future.delayed(const Duration(milliseconds: 500));
          _tabController.animateTo(1);
        }
      } else {
        throw Exception('Email verification failed');
      }
    } on AuthException catch (e) {
      setState(() => _isVerifyingEmail = false);
      String errorMessage = 'Invalid or expired OTP';
      if (e.message.contains('expired')) {
        errorMessage = 'OTP has expired. Please request a new one.';
      } else if (e.message.contains('invalid')) {
        errorMessage = 'Invalid OTP code. Please check and try again.';
      }
      _showSnackBar(errorMessage, Colors.red);
    } catch (e) {
      setState(() => _isVerifyingEmail = false);
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    }
  }

  // Verify Phone OTP via Twilio (Supabase Edge Function)
  Future<void> _verifyPhoneOtp() async {
    if (_phoneOtpController.text.isEmpty ||
        _phoneOtpController.text.length != 6) {
      _showSnackBar('Please enter a valid 6-digit OTP', Colors.orange);
      return;
    }

    setState(() => _isVerifyingPhone = true);

    try {
      // Call Supabase Edge Function to verify phone OTP
      final response = await Supabase.instance.client.functions.invoke(
        'verify-otp',
        body: {'phone': widget.phone, 'code': _phoneOtpController.text.trim()},
      );

      if (response.status == 200) {
        setState(() {
          _isPhoneVerified = true;
          _isVerifyingPhone = false;
        });

        _showSnackBar('Phone verified successfully! ✓', Colors.green);

        // Update verification status in database
        await _updateVerificationStatus();
      } else {
        throw Exception('Phone verification failed');
      }
    } catch (e) {
      setState(() => _isVerifyingPhone = false);
      _showSnackBar('Invalid or expired OTP. Please try again.', Colors.red);
    }
  }

  // Resend Email OTP
  Future<void> _resendEmailOtp() async {
    if (_emailCooldown > 0) return;

    setState(() => _isResendingEmail = true);

    try {
      print('📧 Resending email OTP to: ${widget.email}');

      // Resend OTP for the existing signup
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );

      print('✅ Email OTP resent successfully');

      setState(() {
        _isResendingEmail = false;
        _emailCooldown = 60;
      });

      _emailTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _emailCooldown--;
          if (_emailCooldown <= 0) {
            timer.cancel();
          }
        });
      });

      _showSnackBar(
        'Email OTP sent successfully! Check your inbox.',
        Colors.green,
      );
    } catch (e) {
      print('❌ Failed to resend email OTP: $e');
      setState(() => _isResendingEmail = false);
      _showSnackBar('Failed to send OTP. Please try again.', Colors.red);
    }
  }

  // Resend Phone OTP
  Future<void> _resendPhoneOtp() async {
    if (_phoneCooldown > 0) return;

    setState(() => _isResendingPhone = true);

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'send-otp',
        body: {'phone': widget.phone},
      );

      if (response.status == 200) {
        setState(() {
          _isResendingPhone = false;
          _phoneCooldown = 60;
        });

        _phoneTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _phoneCooldown--;
            if (_phoneCooldown <= 0) {
              timer.cancel();
            }
          });
        });

        _showSnackBar('Phone OTP sent successfully!', Colors.green);
      } else {
        throw Exception('Failed to send phone OTP');
      }
    } catch (e) {
      setState(() => _isResendingPhone = false);
      _showSnackBar('Failed to send OTP. Please try again.', Colors.red);
    }
  }

  // Helper method to update individual verification status in database
  Future<void> _updateVerificationStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Update verification status in users table
      await Supabase.instance.client
          .from('users')
          .update({
            'is_email_verified': _isEmailVerified,
            'is_phone_verified': _isPhoneVerified,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('uid', user.id);

      print('✅ Verification status updated in database');
    } catch (e) {
      print('⚠️ Failed to update verification status: $e');
      // Don't throw - this is a non-critical update
    }
  }

  // Complete Signup after both verifications
  Future<void> _completeSignup() async {
    if (!_isEmailVerified || !_isPhoneVerified) {
      _showSnackBar(
        'Please verify both email and phone to continue',
        Colors.orange,
      );
      return;
    }

    setState(() => _isCompletingSignup = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User session not found');

      // Get user metadata from auth
      final userMetadata = user.userMetadata ?? {};

      print('✅ User already has password set during signup');

      // Build complete user data for database with verification status
      final completeUserData = {
        'uid': user.id,
        'full_name': userMetadata['full_name'] ?? '',
        'username': userMetadata['username'] ?? '',
        'username_display':
            userMetadata['username_display'] ?? userMetadata['username'] ?? '',
        'email': user.email ?? widget.email,
        'display_name':
            userMetadata['display_name'] ??
            userMetadata['full_name'] ??
            userMetadata['username_display'] ??
            '',
        'bio': '',
        'date_of_birth': userMetadata['date_of_birth'],
        'gender': userMetadata['gender'],
        'phone': widget.phone,
        'location': userMetadata['location'],
        'photo_url': null,
        'username_last_changed': DateTime.now().toIso8601String(),
        'is_private': false,
        'show_activity_status': true,
        'allow_messages_from_everyone': false,
        'is_email_verified':
            _isEmailVerified, // Dynamically set based on verification
        'is_phone_verified':
            _isPhoneVerified, // Dynamically set based on verification
        'followers_count': 0,
        'following_count': 0,
        'posts_count': 0,
        'followers': [],
        'following': [],
        'created_at': DateTime.now().toIso8601String(),
        'last_active': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Insert or update user record in database
      await Supabase.instance.client
          .from('users')
          .upsert(completeUserData, onConflict: 'uid');

      // Save user session to preferences (for persistent login)
      await PreferencesService.saveUserSession(
        userId: user.id,
        email: user.email ?? widget.email,
        name: completeUserData['display_name'] as String?,
      );

      print('✅ User session saved - user will stay logged in');

      if (!mounted) return;

      _showSnackBar('Account created successfully! 🎉', Colors.green);

      // Navigate to profile setup flow
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        context.go('/setup-profile-picture');
      }
    } catch (e) {
      print('ERROR completing signup: $e');
      setState(() => _isCompletingSignup = false);
      _showSnackBar('Error completing signup: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool bothVerified = _isEmailVerified && _isPhoneVerified;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Verify Your Account'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: _isEmailVerified
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.email_outlined),
              text: 'Email',
            ),
            Tab(
              icon: _isPhoneVerified
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.phone_outlined),
              text: 'Phone',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEmailVerificationTab(theme, colorScheme),
          _buildPhoneVerificationTab(theme, colorScheme),
        ],
      ),
      bottomNavigationBar: bothVerified
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FilledButton(
                  onPressed: _isCompletingSignup ? null : _completeSignup,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                  ),
                  child: _isCompletingSignup
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Complete Signup & Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmailVerificationTab(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Lottie.asset('assets/lottie/search.json', height: 180),
          const SizedBox(height: 24),
          Text(
            'Verify Your Email',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.email,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'We\'ve sent a 6-digit verification code to your email. Please enter it below.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _emailOtpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              hintText: '000000',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
            enabled: !_isEmailVerified,
          ),
          const SizedBox(height: 24),
          if (!_isEmailVerified)
            FilledButton(
              onPressed: _isVerifyingEmail ? null : _verifyEmailOtp,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isVerifyingEmail
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      'Verify Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          if (_isEmailVerified)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Email Verified Successfully!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _emailCooldown > 0 || _isResendingEmail
                ? null
                : _resendEmailOtp,
            child: _isResendingEmail
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _emailCooldown > 0
                        ? 'Resend OTP in $_emailCooldown seconds'
                        : 'Resend OTP',
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneVerificationTab(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Lottie.asset('assets/lottie/connect.json', height: 180),
          const SizedBox(height: 24),
          Text(
            'Verify Your Phone',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  widget.phone,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'We\'ve sent a 6-digit verification code to your phone via SMS. Please enter it below.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _phoneOtpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              hintText: '000000',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
            enabled: !_isPhoneVerified,
          ),
          const SizedBox(height: 24),
          if (!_isPhoneVerified)
            FilledButton(
              onPressed: _isVerifyingPhone ? null : _verifyPhoneOtp,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isVerifyingPhone
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      'Verify Phone',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          if (_isPhoneVerified)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Phone Verified Successfully!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _phoneCooldown > 0 || _isResendingPhone
                ? null
                : _resendPhoneOtp,
            child: _isResendingPhone
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _phoneCooldown > 0
                        ? 'Resend OTP in $_phoneCooldown seconds'
                        : 'Resend OTP',
                  ),
          ),
        ],
      ),
    );
  }
}
