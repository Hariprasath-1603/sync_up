import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../core/providers/auth_provider.dart';

class ChangeUsernamePage extends StatefulWidget {
  const ChangeUsernamePage({super.key});

  @override
  State<ChangeUsernamePage> createState() => _ChangeUsernamePageState();
}

class _ChangeUsernamePageState extends State<ChangeUsernamePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  bool _isChecking = false;
  bool _isAvailable = false;
  bool _hasChecked = false;
  String? _errorMessage;
  DateTime? _lastChangedDate;
  bool _canChangeUsername = true;
  int _daysRemaining = 0;

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _checkLastUsernameChange();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLastUsernameChange() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUserId;

    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('username_last_changed')
          .eq('uid', userId)
          .single();

      if (response['username_last_changed'] != null) {
        _lastChangedDate = DateTime.parse(response['username_last_changed']);
        final daysSinceChange = DateTime.now()
            .difference(_lastChangedDate!)
            .inDays;

        if (daysSinceChange < 30) {
          setState(() {
            _canChangeUsername = false;
            _daysRemaining = 30 - daysSinceChange;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking last username change: $e');
    }
  }

  void _onUsernameChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Reset state
    setState(() {
      _hasChecked = false;
      _isAvailable = false;
      _errorMessage = null;
    });

    // Don't check empty or invalid usernames
    if (value.trim().isEmpty || value.length < 3) {
      return;
    }

    // Start new timer - check after 500ms of no typing
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _checkUsernameAvailability(value.trim());
    });
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty) return;

    setState(() {
      _isChecking = true;
      _hasChecked = false;
      _errorMessage = null;
    });

    try {
      // Check if username already exists (excluding current user)
      final authProvider = context.read<AuthProvider>();
      final currentUserId = authProvider.currentUserId;

      final response = await Supabase.instance.client
          .from('users')
          .select('uid')
          .eq('username', username)
          .maybeSingle();

      // Username is available if no result or if it's the current user's username
      final isAvailable = response == null || response['uid'] == currentUserId;

      if (mounted) {
        setState(() {
          _isChecking = false;
          _hasChecked = true;
          _isAvailable = isAvailable;
          _errorMessage = isAvailable ? null : 'Username is already taken';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _hasChecked = true;
          _isAvailable = false;
          _errorMessage = 'Error checking availability';
        });
      }
    }
  }

  Future<void> _saveUsername() async {
    if (!_formKey.currentState!.validate() || !_isAvailable) {
      return;
    }

    if (!_canChangeUsername) {
      _showErrorDialog(
        'Cannot Change Username',
        'You can only change your username once every 30 days. Please wait $_daysRemaining more day${_daysRemaining == 1 ? '' : 's'}.',
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUserId;

    if (userId == null) return;

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              const Text('Updating username...'),
            ],
          ),
          duration: const Duration(seconds: 10),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    try {
      // Update username and last changed timestamp
      await Supabase.instance.client
          .from('users')
          .update({
            'username': _usernameController.text.trim(),
            'username_last_changed': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('uid', userId);

      // Reload user data
      await authProvider.reloadUserData();

      if (mounted) {
        // Dismiss loading indicator
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Username updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Navigate back
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) context.pop();
        });
      }
    } catch (e) {
      if (mounted) {
        // Dismiss loading indicator
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Error updating username: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final currentUsername = authProvider.currentUser?.username ?? '';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [kDarkBackground, kDarkBackground.withOpacity(0.8)]
                : [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_canChangeUsername) ...[
                          _buildWarningCard(isDark),
                          const SizedBox(height: 24),
                        ],
                        _buildInfoCard(isDark),
                        const SizedBox(height: 32),
                        _buildCurrentUsernameField(currentUsername, isDark),
                        const SizedBox(height: 24),
                        _buildNewUsernameField(isDark),
                        const SizedBox(height: 32),
                        _buildSaveButton(isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Change Username',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cooldown Period',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You can change your username again in $_daysRemaining day${_daysRemaining == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kPrimary.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: kPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You can only change your username once every 30 days. Choose carefully!',
                      style: TextStyle(
                        fontSize: 14,
                        color: (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentUsernameField(String username, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Username',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(
                    0.1,
                  ),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.alternate_email_rounded,
                      color: kPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    username,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: (isDark ? Colors.white : Colors.black).withOpacity(
                        0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.lock_outline_rounded,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(
                      0.3,
                    ),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewUsernameField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New Username',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hasChecked
                      ? (_isAvailable ? Colors.green : Colors.red).withOpacity(
                          0.5,
                        )
                      : (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: TextFormField(
                controller: _usernameController,
                enabled: _canChangeUsername,
                onChanged: _onUsernameChanged,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter new username',
                  hintStyle: TextStyle(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(
                      0.4,
                    ),
                  ),
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(14),
                    child: Icon(
                      Icons.alternate_email_rounded,
                      color: kPrimary,
                      size: 20,
                    ),
                  ),
                  suffixIcon: _isChecking
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                kPrimary,
                              ),
                            ),
                          ),
                        )
                      : _hasChecked
                      ? Icon(
                          _isAvailable ? Icons.check_circle : Icons.cancel,
                          color: _isAvailable ? Colors.green : Colors.red,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: (value) {
                  if (!_canChangeUsername) {
                    return null; // Don't validate if can't change
                  }
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a username';
                  }
                  if (value.trim().length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                  if (value.trim().length > 30) {
                    return 'Username must be less than 30 characters';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                    return 'Username can only contain letters, numbers, and underscores';
                  }
                  if (_errorMessage != null) {
                    return _errorMessage;
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
        if (_hasChecked && !_isAvailable && _errorMessage != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ],
          ),
        ],
        if (_hasChecked && _isAvailable) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Username is available',
                style: TextStyle(color: Colors.green, fontSize: 14),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSaveButton(bool isDark) {
    final isEnabled = _canChangeUsername && _isAvailable && _hasChecked;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEnabled
                ? [kPrimary, kPrimary.withOpacity(0.8)]
                : [Colors.grey, Colors.grey.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (isEnabled)
              BoxShadow(
                color: kPrimary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isEnabled ? _saveUsername : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Change Username',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
