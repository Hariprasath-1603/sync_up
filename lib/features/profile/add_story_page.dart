import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/theme.dart';

class AddStoryPage extends StatefulWidget {
  const AddStoryPage({Key? key}) : super(key: key);

  @override
  State<AddStoryPage> createState() => _AddStoryPageState();
}

class _AddStoryPageState extends State<AddStoryPage> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  final TextEditingController _captionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Story posted successfully!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _postStory() async {
    if (_selectedImage == null) {
      _showError('Please select an image first');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate upload delay
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    _showSuccess();
    
    // Return to previous page after posting
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0B0E13),
                    const Color(0xFF1A1F2E),
                    kPrimary.withOpacity(0.15),
                  ]
                : [
                    const Color(0xFFF6F7FB),
                    kPrimary.withOpacity(0.08),
                    const Color(0xFFE8ECFF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context, isDark),
              // Content
              Expanded(
                child: _selectedImage == null
                    ? _buildImageSelector(isDark)
                    : _buildImageEditor(isDark),
              ),
              // Post Button
              if (_selectedImage != null) _buildPostButton(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                // Back Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.close_rounded,
                        color: kPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Story',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Share your moment',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [kPrimary.withOpacity(0.3), kPrimary.withOpacity(0.1)],
              ),
            ),
            child: Icon(
              Icons.image_outlined,
              size: 80,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Add to Your Story',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Share a photo or video to your story',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          // Camera Button
          _buildSelectorButton(
            icon: Icons.camera_alt_rounded,
            label: 'Take Photo',
            onTap: () => _pickImage(ImageSource.camera),
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          // Gallery Button
          _buildSelectorButton(
            icon: Icons.photo_library_rounded,
            label: 'Choose from Gallery',
            onTap: () => _pickImage(ImageSource.gallery),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.3),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: kPrimary,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageEditor(bool isDark) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Image Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Image
                  AspectRatio(
                    aspectRatio: 9 / 16,
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Change Image Button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _pickImage(ImageSource.gallery),
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Icon(
                                  Icons.edit_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Caption Input
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: TextField(
                    controller: _captionController,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      hintText: 'Add a caption... (optional)',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Story Options
            _buildStoryOption(
              icon: Icons.access_time_rounded,
              label: 'Story Duration',
              value: '24 hours',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildStoryOption(
              icon: Icons.visibility_rounded,
              label: 'Who can see this',
              value: 'Everyone',
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryOption({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: kPrimary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimary.withOpacity(0.8), kPrimary],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _postStory,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _isLoading
                      ? const Center(
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Post Story',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
