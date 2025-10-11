import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';

class CreateStoryPage extends StatefulWidget {
  const CreateStoryPage({super.key});

  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  XFile? _selectedMedia;
  final _captionController = TextEditingController();
  String _selectedAudience = 'public';
  bool _allowReplies = true;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source) async {
    final picker = ImagePicker();
    final media = await picker.pickImage(source: source);

    if (media != null) {
      setState(() {
        _selectedMedia = media;
      });
    }
  }

  void _showMediaSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1D24) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Add Story',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildSourceOption(
                context,
                Icons.camera_alt,
                'Camera',
                'Take a photo or video',
                () {
                  Navigator.pop(context);
                  _pickMedia(ImageSource.camera);
                },
                isDark,
              ),
              const SizedBox(height: 12),
              _buildSourceOption(
                context,
                Icons.photo_library,
                'Gallery',
                'Choose from your photos',
                () {
                  Navigator.pop(context);
                  _pickMedia(ImageSource.gallery);
                },
                isDark,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
    bool isDark,
  ) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: kPrimary),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontSize: 13,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isDark ? const Color(0xFF0B0E13) : Colors.grey[100],
    );
  }

  Future<void> _publishStory() async {
    if (_selectedMedia == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Simulate upload
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.pop(context); // Close loading
    Navigator.pop(context, true); // Return to home with success

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Story published successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E13) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1D24) : Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Story',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        actions: [
          if (_selectedMedia != null)
            TextButton(
              onPressed: _publishStory,
              child: const Text(
                'Share',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _selectedMedia == null
          ? _buildInitialView(isDark)
          : _buildEditView(isDark),
    );
  }

  Widget _buildInitialView(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 100,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Create Your Story',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Share a photo or video that will\ndisappear after 24 hours',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: _showMediaSourceOptions,
            icon: const Icon(Icons.add),
            label: const Text('Add Story'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditView(bool isDark) {
    return Column(
      children: [
        // Preview
        Expanded(
          child: Container(
            color: Colors.black,
            child: Center(
              child: Text(
                'Story Preview',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        // Options
        Container(
          color: isDark ? const Color(0xFF1A1D24) : Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _captionController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Add a caption...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0B0E13)
                      : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Audience',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  DropdownButton<String>(
                    value: _selectedAudience,
                    dropdownColor: isDark
                        ? const Color(0xFF1A1D24)
                        : Colors.white,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'public', child: Text('Public')),
                      DropdownMenuItem(
                        value: 'friends',
                        child: Text('Friends'),
                      ),
                      DropdownMenuItem(
                        value: 'close',
                        child: Text('Close Friends'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedAudience = value!;
                      });
                    },
                  ),
                ],
              ),
              SwitchListTile(
                title: Text(
                  'Allow Replies',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                value: _allowReplies,
                onChanged: (value) {
                  setState(() {
                    _allowReplies = value;
                  });
                },
                activeColor: kPrimary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
