import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/supabase_storage_service.dart';
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
  bool _isUploadingPhoto = false;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

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
                        _buildTextField(
                          controller: _usernameController,
                          label: 'Username',
                          icon: Icons.alternate_email_rounded,
                          isDark: isDark,
                          prefixText: '@',
                        ),
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
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone',
                          icon: Icons.phone_outlined,
                          isDark: isDark,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _websiteController,
                          label: 'Website',
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: kPrimary.withOpacity(0.2),
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Icon(Icons.person_rounded, size: 60, color: kPrimary)
                        : null,
                  ),
                  if (_isUploadingPhoto)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    int? maxLength,
    String? prefixText,
    TextInputType? keyboardType,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            keyboardType: keyboardType,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
              prefixIcon: Icon(icon, color: kPrimary, size: 22),
              prefixText: prefixText,
              prefixStyle: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
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
            ),
            validator: (value) {
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        await _uploadPhoto();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _uploadPhoto() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUserId;

      if (userId == null) {
        throw Exception('User not authenticated. Please sign in again.');
      }

      print('DEBUG: Starting photo upload for user: $userId');

      // Upload to Supabase Storage
      print('DEBUG: Uploading to Supabase Storage...');
      final photoURL = await SupabaseStorageService.uploadProfilePhoto(
        _selectedImage!,
        userId,
      );

      if (photoURL == null) {
        throw Exception('Failed to upload photo to Supabase');
      }

      print('DEBUG: Photo URL: $photoURL');

      // Update Supabase user table
      print('DEBUG: Updating Supabase user document...');
      await Supabase.instance.client
          .from('users')
          .update({
            'photo_url': photoURL,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('uid', userId);
      print('DEBUG: Supabase updated successfully');

      // Update Firestore user document (so profile page shows it)
      print('DEBUG: Updating Firestore user document...');
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'photoURL': photoURL,
        'lastActive': Timestamp.now(),
      });
      print('DEBUG: Firestore updated successfully');

      // Update Firebase Auth profile (optional but recommended)
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.updatePhotoURL(photoURL);
        print('DEBUG: Firebase Auth profile updated');
      }

      // Reload user data
      print('DEBUG: Reloading user data...');
      await authProvider.reloadUserData();
      print('DEBUG: User data reloaded');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile photo updated successfully! ✓'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('ERROR: Photo upload failed: $e');
      if (mounted) {
        String errorMessage = 'Error uploading photo';

        if (e.toString().contains('permission-denied')) {
          errorMessage = 'Permission denied. Check Firebase Storage rules.';
        } else if (e.toString().contains('not authenticated')) {
          errorMessage = 'Please sign in again to upload photo.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Check your internet connection.';
        } else {
          errorMessage = 'Error uploading photo: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
          _selectedImage = null;
        });
      }
    }
  }

  Future<void> _removePhoto() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUserId;

    if (userId == null) return;

    try {
      // Delete from Supabase Storage
      await SupabaseStorageService.deleteProfilePhoto(userId);

      // Remove from Supabase database
      await Supabase.instance.client
          .from('users')
          .update({'photo_url': null})
          .eq('uid', userId);

      // Reload user data
      await authProvider.reloadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile photo removed'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing photo: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
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

    try {
      // Update Supabase user table with all fields
      await Supabase.instance.client
          .from('users')
          .update({
            'display_name': _nameController.text.trim(),
            'username': _usernameController.text.trim(),
            'bio': _bioController.text.trim(),
            'phone': _phoneController.text.trim(),
            'location': _locationController.text.trim(),
            'gender': _selectedGender,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('uid', userId);

      // Also update Firestore user table (for backwards compatibility)
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'displayName': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'gender': _selectedGender,
        'lastActive': Timestamp.now(),
      });

      // Reload user data to reflect changes
      await authProvider.reloadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully! ✓'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Navigate back after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) context.pop();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? kDarkBackground : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.blue),
              ),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Colors.purple,
                ),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
              ),
              title: const Text('Remove Photo'),
              onTap: () {
                Navigator.pop(context);
                _removePhoto();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
