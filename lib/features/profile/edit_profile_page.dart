import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/image_picker_service.dart';
import '../../core/theme.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _websiteController;
  late final TextEditingController _locationController;

  String _selectedGender = 'Male';
  bool _isPrivateAccount = false;
  bool _showActivityStatus = true;
  bool _allowMessagesFromEveryone = false;
  final ImagePickerService _imagePickerService = ImagePickerService();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current user data
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    _nameController = TextEditingController(
      text: currentUser?.displayName ?? '',
    );
    _usernameController = TextEditingController(
      text: currentUser?.username ?? '',
    );
    _bioController = TextEditingController(text: currentUser?.bio ?? '');
    _emailController = TextEditingController(text: currentUser?.email ?? '');
    _phoneController = TextEditingController(text: currentUser?.phone ?? '');
    _websiteController = TextEditingController(text: '');
    _locationController = TextEditingController(
      text: currentUser?.location ?? '',
    );

    // Set gender if available
    if (currentUser?.gender != null) {
      _selectedGender = currentUser!.gender!;
    }

    // Initialize privacy settings from user data
    _isPrivateAccount = currentUser?.isPrivate ?? false;
    _showActivityStatus = currentUser?.showActivityStatus ?? true;
    _allowMessagesFromEveryone =
        currentUser?.allowMessagesFromEveryone ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [kDarkBackground, kDarkBackground.withOpacity(0.8)]
                : [kLightBackground, const Color(0xFFF0F2F8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfilePhoto(isDark),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Personal Information', isDark),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person_outline_rounded,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildClickableUsernameField(isDark),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _bioController,
                          label: 'Bio',
                          icon: Icons.edit_note_rounded,
                          isDark: isDark,
                          maxLines: 4,
                          maxLength: 150,
                        ),
                        const SizedBox(height: 16),
                        _buildGenderSelector(isDark),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Contact Information', isDark),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          isDark: isDark,
                          keyboardType: TextInputType.emailAddress,
                          enabled: false, // Gray out email field
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone',
                          icon: Icons.phone_outlined,
                          isDark: isDark,
                          keyboardType: TextInputType.phone,
                          enabled: false, // Gray out phone field
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _websiteController,
                          label: 'URL',
                          icon: Icons.link_rounded,
                          isDark: isDark,
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _locationController,
                          label: 'Location',
                          icon: Icons.location_on_outlined,
                          isDark: isDark,
                          enabled: false, // Gray out location field
                        ),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Privacy Settings', isDark),
                        const SizedBox(height: 16),
                        _buildPrivacyOptions(isDark),
                        const SizedBox(height: 32),
                        _buildSaveButton(isDark),
                        const SizedBox(height: 40),
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

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
        border: Border(
          bottom: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => context.pop(),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [kPrimary, kPrimary.withOpacity(0.7)],
              ).createShader(bounds),
              child: const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhoto(bool isDark) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final avatarUrl = currentUser?.photoURL;

    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [kPrimary, kPrimary.withOpacity(0.6)],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? kDarkBackground : kLightBackground,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.2),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: kPrimary),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.2),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            size: 60,
                            color: kPrimary,
                          ),
                        ),
                      )
                    : Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.2),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          size: 60,
                          color: kPrimary,
                        ),
                      ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                _showPhotoOptions();
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimary, kPrimary.withOpacity(0.8)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? kDarkBackground : kLightBackground,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildClickableUsernameField(bool isDark) {
    final authProvider = context.watch<AuthProvider>();
    final currentUsername = authProvider.currentUser?.username ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: (isDark ? Colors.white60 : Colors.grey.shade600),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: InkWell(
              onTap: () {
                // Navigate to change username page
                context.push('/change-username');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(
                    0.05,
                  ),
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
                    Icon(
                      Icons.alternate_email_rounded,
                      color: kPrimary,
                      size: 22,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        currentUsername.isNotEmpty
                            ? '@$currentUsername'
                            : 'Set username',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: (isDark ? Colors.white : Colors.black).withOpacity(
                        0.4,
                      ),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    int? maxLength,
    String? prefixText,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: enabled
                ? (isDark ? Colors.white : Colors.black).withOpacity(0.05)
                : (isDark ? Colors.white : Colors.black).withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(
                enabled ? 0.1 : 0.05,
              ),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            keyboardType: keyboardType,
            enabled: enabled,
            style: TextStyle(
              color: enabled
                  ? (isDark ? Colors.white : Colors.black87)
                  : (isDark ? Colors.white38 : Colors.black38),
              fontSize: 15,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: enabled
                    ? (isDark ? Colors.white60 : Colors.grey.shade600)
                    : (isDark ? Colors.white30 : Colors.grey.shade400),
              ),
              prefixIcon: Icon(
                icon,
                color: enabled
                    ? kPrimary
                    : (isDark ? Colors.white30 : Colors.grey.shade400),
                size: 22,
              ),
              prefixText: prefixText,
              prefixStyle: TextStyle(
                color: enabled
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.white38 : Colors.black38),
                fontSize: 15,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              counterStyle: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
              suffixIcon: !enabled
                  ? Icon(
                      Icons.lock_outline,
                      color: isDark ? Colors.white30 : Colors.grey.shade400,
                      size: 18,
                    )
                  : null,
            ),
            validator: (value) {
              if (!enabled) return null; // Skip validation for disabled fields
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelector(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.wc_rounded, color: kPrimary, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'Gender',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildGenderOption(
                      'Male',
                      Icons.male_rounded,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGenderOption(
                      'Female',
                      Icons.female_rounded,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGenderOption(
                      'Other',
                      Icons.transgender_rounded,
                      isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String gender, IconData icon, bool isDark) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [kPrimary, kPrimary.withOpacity(0.8)])
              : null,
          color: isSelected
              ? null
              : (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : kPrimary, size: 24),
            const SizedBox(height: 4),
            Text(
              gender,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOptions(bool isDark) {
    return Column(
      children: [
        _buildSwitchTile(
          title: 'Private Account',
          subtitle: 'Only approved followers can see your posts',
          icon: Icons.lock_outline_rounded,
          value: _isPrivateAccount,
          onChanged: (value) {
            setState(() {
              _isPrivateAccount = value;
            });
          },
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildSwitchTile(
          title: 'Show Activity Status',
          subtitle: 'Let others see when you\'re active',
          icon: Icons.circle_outlined,
          value: _showActivityStatus,
          onChanged: (value) {
            setState(() {
              _showActivityStatus = value;
            });
          },
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildSwitchTile(
          title: 'Messages from Everyone',
          subtitle: 'Allow messages from people you don\'t follow',
          icon: Icons.mail_outline_rounded,
          value: _allowMessagesFromEveryone,
          onChanged: (value) {
            setState(() {
              _allowMessagesFromEveryone = value;
            });
          },
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
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
                child: Icon(icon, color: kPrimary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: kPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary, kPrimary.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              await _saveProfileChanges();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Save Changes',
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

  Future<void> _saveProfileChanges() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUserId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to update profile'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

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
              const Text('Saving changes...'),
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
      // Update Supabase user table with all editable fields
      await Supabase.instance.client
          .from('users')
          .update({
            'display_name': _nameController.text.trim(),
            'full_name': _nameController.text.trim(), // Also update full_name
            'username': _usernameController.text.trim(),
            'bio': _bioController.text.trim(),
            'website': _websiteController.text.trim(),
            'gender': _selectedGender,
            'is_private': _isPrivateAccount,
            'show_activity_status': _showActivityStatus,
            'allow_messages_from_everyone': _allowMessagesFromEveryone,
            'updated_at': DateTime.now().toIso8601String(),
            // Note: phone, email, location are disabled and not updated
          })
          .eq('uid', userId);

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
                const Text('Profile updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Reload user data AFTER showing success but BEFORE popping
        await authProvider.reloadUserData(showLoading: false);

        // Small delay to ensure data is loaded, then pop
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) context.pop(true); // Return true to indicate success
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
                  child: Text('Error updating profile: ${e.toString()}'),
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

  void _showPhotoOptions() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUserId;
    final currentUser = authProvider.currentUser;

    if (userId == null) return;

    _imagePickerService.showImageSourceBottomSheet(
      context: context,
      photoType: PhotoType.profile,
      userId: userId,
      currentImageUrl: currentUser?.photoURL,
      onImageUploaded: (url) async {
        // Clear image cache for old profile photo
        if (currentUser?.photoURL != null) {
          final oldImage = NetworkImage(currentUser!.photoURL!);
          await oldImage.evict();
        }

        authProvider.applyLocalProfilePhoto(url);
        await authProvider.reloadUserData(showLoading: false);

        // Force UI update
        if (mounted) {
          setState(() {});
        }
      },
    );
  }
}
