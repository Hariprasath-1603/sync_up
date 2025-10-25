import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_storage_service.dart';

class SetupProfilePicturePage extends StatefulWidget {
  const SetupProfilePicturePage({super.key});

  @override
  State<SetupProfilePicturePage> createState() =>
      _SetupProfilePicturePageState();
}

class _SetupProfilePicturePageState extends State<SetupProfilePicturePage> {
  File? _selectedImage;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadAndContinue() async {
    if (_selectedImage == null) {
      // Skip to bio page without profile picture
      if (mounted) {
        context.go('/setup-bio');
      }
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Upload profile picture
      final photoUrl = await SupabaseStorageService.uploadProfilePhoto(
        _selectedImage!,
        user.id,
      );

      // Update user record with profile photo URL
      await Supabase.instance.client
          .from('users')
          .update({
            'photo_url': photoUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('uid', user.id);

      print('✅ Profile picture uploaded: $photoUrl');

      if (mounted) {
        context.go('/setup-bio');
      }
    } catch (e) {
      print('❌ Error uploading profile picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Choose Profile Picture',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add a photo so your friends can recognize you',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    GestureDetector(
                      onTap: _isUploading ? null : _showImageSourceDialog,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.surfaceContainerHighest,
                          border: Border.all(
                            color: colorScheme.primary,
                            width: 3,
                          ),
                          image: _selectedImage != null
                              ? DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _selectedImage == null
                            ? Icon(
                                Icons.add_a_photo,
                                size: 64,
                                color: colorScheme.onSurfaceVariant,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_selectedImage != null)
                      TextButton.icon(
                        onPressed: _isUploading ? null : _showImageSourceDialog,
                        icon: const Icon(Icons.edit),
                        label: const Text('Change Photo'),
                      ),
                  ],
                ),
              ),
              Column(
                children: [
                  FilledButton(
                    onPressed: _isUploading ? null : _uploadAndContinue,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _selectedImage != null ? 'Continue' : 'Skip',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isUploading
                          ? null
                          : () => context.go('/setup-bio'),
                      child: const Text('Skip for now'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
