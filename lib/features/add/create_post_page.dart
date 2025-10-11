import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostPage extends StatefulWidget {
  final Map<String, dynamic>? draftData;

  const CreatePostPage({super.key, this.draftData});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Timer? _autosaveTimer;

  List<XFile> _selectedMedia = [];
  List<Map<String, dynamic>> _taggedUsers = [];
  List<String> _hashtags = [];
  String _selectedAudience = 'Public';
  List<Map<String, dynamic>> _customAudienceUsers = [];
  Map<String, dynamic>? _location;
  String? _feeling;
  bool _enableComments = true;
  bool _enableReactions = true;
  Map<String, dynamic>? _poll;
  DateTime? _scheduledDate;
  bool _showContentWarning = false;
  String? _contentWarningText;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _hasUnsavedChanges = false;

  // Advanced options
  bool _crossPostTwitter = false;
  bool _crossPostLinkedIn = false;
  bool _enableBoost = false;
  String _selectedLanguage = 'English';
  List<String> _productTags = [];

  @override
  void initState() {
    super.initState();
    if (widget.draftData != null) {
      _loadDraft(widget.draftData!);
    }
    _startAutosave();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _startAutosave() {
    _autosaveTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_hasUnsavedChanges) {
        _saveDraft(showMessage: false);
      }
    });
  }

  void _onTextChanged() {
    setState(() {
      _hasUnsavedChanges = true;
      _extractHashtags();
    });
  }

  void _extractHashtags() {
    final text = _textController.text;
    final hashtagPattern = RegExp(r'#\w+');
    final matches = hashtagPattern.allMatches(text);
    _hashtags = matches.map((m) => m.group(0)!).toList();
  }

  void _loadDraft(Map<String, dynamic> draft) {
    setState(() {
      _textController.text = draft['text'] ?? '';
      _titleController.text = draft['title'] ?? '';
      _selectedAudience = draft['audience'] ?? 'Public';
      _location = draft['location'];
      _feeling = draft['feeling'];
      _scheduledDate = draft['scheduledDate'];
    });
  }

  Future<void> _saveDraft({bool showMessage = true}) async {
    final draftData = {
      'text': _textController.text,
      'title': _titleController.text,
      'audience': _selectedAudience,
      'location': _location,
      'feeling': _feeling,
      'scheduledDate': _scheduledDate,
      'savedAt': DateTime.now().toIso8601String(),
    };

    // TODO: Save to local storage and server
    print('Draft saved: $draftData');

    setState(() {
      _hasUnsavedChanges = false;
    });

    if (showMessage) {
      _showSnackBar('Draft saved successfully', Colors.green);
    }
  }

  Future<void> _pickMediaFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedMedia.addAll(images);
          _hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking images: $e', Colors.red);
    }
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedMedia.add(video);
          _hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking video: $e', Colors.red);
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedMedia.add(photo);
          _hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      _showSnackBar('Error capturing photo: $e', Colors.red);
    }
  }

  Future<void> _captureVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
      if (video != null) {
        setState(() {
          _selectedMedia.add(video);
          _hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      _showSnackBar('Error capturing video: $e', Colors.red);
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
      _hasUnsavedChanges = true;
    });
  }

  void _reorderMedia(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _selectedMedia.removeAt(oldIndex);
      _selectedMedia.insert(newIndex, item);
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _publishPost() async {
    if (_textController.text.trim().isEmpty && _selectedMedia.isEmpty) {
      _showSnackBar('Please add some content', Colors.orange);
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Simulate upload progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        setState(() {
          _uploadProgress = i / 100;
        });
      }

      final postData = {
        'title': _titleController.text,
        'text': _textController.text,
        'media': _selectedMedia.map((m) => m.path).toList(),
        'tags': _taggedUsers,
        'hashtags': _hashtags,
        'audience': _selectedAudience,
        'location': _location,
        'feeling': _feeling,
        'enableComments': _enableComments,
        'enableReactions': _enableReactions,
        'poll': _poll,
        'scheduledFor': _scheduledDate?.toIso8601String(),
        'contentWarning': _showContentWarning ? _contentWarningText : null,
        'crossPost': {
          'twitter': _crossPostTwitter,
          'linkedin': _crossPostLinkedIn,
        },
        'language': _selectedLanguage,
        'productTags': _productTags,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // TODO: Upload to server with resumable uploads
      print('Post published: $postData');

      setState(() {
        _isUploading = false;
        _hasUnsavedChanges = false;
      });

      _showSnackBar('Post published successfully!', Colors.green);

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showSnackBar('Error publishing post: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _getBorderColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Add Media',
              style: TextStyle(
                color: _getTextColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildMediaOption(
              Icons.photo_library,
              'Photo Gallery',
              Colors.blue,
              _pickMediaFromGallery,
            ),
            _buildMediaOption(
              Icons.videocam,
              'Video Gallery',
              Colors.purple,
              _pickVideoFromGallery,
            ),
            _buildMediaOption(
              Icons.camera_alt,
              'Take Photo',
              Colors.green,
              _capturePhoto,
            ),
            _buildMediaOption(
              Icons.videocam,
              'Record Video',
              Colors.red,
              _captureVideo,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: TextStyle(color: _getTextColor(context))),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: _getSubtitleColor(context),
        size: 16,
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _showAudienceSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _getBorderColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Post Audience',
              style: TextStyle(
                color: _getTextColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildAudienceOption(
              Icons.public,
              'Public',
              'Anyone can see this post',
              Colors.blue,
            ),
            _buildAudienceOption(
              Icons.people,
              'Friends',
              'Only friends can see',
              Colors.green,
            ),
            _buildAudienceOption(
              Icons.lock,
              'Only me',
              'Only you can see',
              Colors.orange,
            ),
            _buildAudienceOption(
              Icons.settings,
              'Custom',
              'Choose specific people',
              Colors.purple,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAudienceOption(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    final isSelected = _selectedAudience == title;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(isSelected ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _getTextColor(context),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: _getSubtitleColor(context), fontSize: 12),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF4A6CF7))
          : Icon(Icons.circle_outlined, color: _getBorderColor(context)),
      onTap: () {
        Navigator.pop(context);
        if (title == 'Custom') {
          _showCustomAudienceSelector();
        } else {
          setState(() {
            _selectedAudience = title;
            _hasUnsavedChanges = true;
          });
        }
      },
    );
  }

  void _showTagPeopleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Tag People',
          style: TextStyle(
            color: _getTextColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: TextStyle(color: _getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Search people...',
                hintStyle: TextStyle(color: _getSubtitleColor(context)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4A6CF7)),
                filled: true,
                fillColor: _getBackgroundColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Search to tag friends',
              style: TextStyle(color: _getSubtitleColor(context)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Done',
              style: TextStyle(color: Color(0xFF4A6CF7)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationPicker() {
    final TextEditingController searchController = TextEditingController();
    final List<Map<String, dynamic>> allLocations = [
      // Major cities worldwide
      {'name': 'New York, USA', 'lat': 40.7128, 'lng': -74.0060},
      {'name': 'Los Angeles, USA', 'lat': 34.0522, 'lng': -118.2437},
      {'name': 'London, UK', 'lat': 51.5074, 'lng': -0.1278},
      {'name': 'Paris, France', 'lat': 48.8566, 'lng': 2.3522},
      {'name': 'Tokyo, Japan', 'lat': 35.6762, 'lng': 139.6503},
      {'name': 'Dubai, UAE', 'lat': 25.2048, 'lng': 55.2708},
      {'name': 'Singapore', 'lat': 1.3521, 'lng': 103.8198},
      {'name': 'Sydney, Australia', 'lat': -33.8688, 'lng': 151.2093},
      {'name': 'Mumbai, India', 'lat': 19.0760, 'lng': 72.8777},
      {'name': 'Delhi, India', 'lat': 28.7041, 'lng': 77.1025},
      {'name': 'Bengaluru, India', 'lat': 12.9716, 'lng': 77.5946},
      {'name': 'Chennai, India', 'lat': 13.0827, 'lng': 80.2707},
      {'name': 'Hyderabad, India', 'lat': 17.3850, 'lng': 78.4867},
      {'name': 'Kolkata, India', 'lat': 22.5726, 'lng': 88.3639},
      {'name': 'Pune, India', 'lat': 18.5204, 'lng': 73.8567},
      {'name': 'Shanghai, China', 'lat': 31.2304, 'lng': 121.4737},
      {'name': 'Beijing, China', 'lat': 39.9042, 'lng': 116.4074},
      {'name': 'Hong Kong', 'lat': 22.3193, 'lng': 114.1694},
      {'name': 'Seoul, South Korea', 'lat': 37.5665, 'lng': 126.9780},
      {'name': 'Bangkok, Thailand', 'lat': 13.7563, 'lng': 100.5018},
      {'name': 'Istanbul, Turkey', 'lat': 41.0082, 'lng': 28.9784},
      {'name': 'Moscow, Russia', 'lat': 55.7558, 'lng': 37.6173},
      {'name': 'Berlin, Germany', 'lat': 52.5200, 'lng': 13.4050},
      {'name': 'Rome, Italy', 'lat': 41.9028, 'lng': 12.4964},
      {'name': 'Madrid, Spain', 'lat': 40.4168, 'lng': -3.7038},
      {'name': 'Barcelona, Spain', 'lat': 41.3851, 'lng': 2.1734},
      {'name': 'Amsterdam, Netherlands', 'lat': 52.3676, 'lng': 4.9041},
      {'name': 'Toronto, Canada', 'lat': 43.6532, 'lng': -79.3832},
      {'name': 'Vancouver, Canada', 'lat': 49.2827, 'lng': -123.1207},
      {'name': 'Mexico City, Mexico', 'lat': 19.4326, 'lng': -99.1332},
      {'name': 'São Paulo, Brazil', 'lat': -23.5505, 'lng': -46.6333},
      {'name': 'Rio de Janeiro, Brazil', 'lat': -22.9068, 'lng': -43.1729},
      {'name': 'Buenos Aires, Argentina', 'lat': -34.6037, 'lng': -58.3816},
      {'name': 'Cairo, Egypt', 'lat': 30.0444, 'lng': 31.2357},
      {'name': 'Cape Town, South Africa', 'lat': -33.9249, 'lng': 18.4241},
      {'name': 'Nairobi, Kenya', 'lat': -1.2921, 'lng': 36.8219},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          List<Map<String, dynamic>> filteredLocations = allLocations;

          if (searchController.text.isNotEmpty) {
            filteredLocations = allLocations
                .where(
                  (loc) => loc['name'].toString().toLowerCase().contains(
                    searchController.text.toLowerCase(),
                  ),
                )
                .toList();
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: _getCardColor(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _getBorderColor(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Add Location',
                    style: TextStyle(
                      color: _getTextColor(context),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: searchController,
                    style: TextStyle(color: _getTextColor(context)),
                    decoration: InputDecoration(
                      hintText: 'Search location...',
                      hintStyle: TextStyle(color: _getSubtitleColor(context)),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF4A6CF7),
                      ),
                      filled: true,
                      fillColor: _getBackgroundColor(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setModalState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Use Current Location Button
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A6CF7).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: Color(0xFF4A6CF7),
                    ),
                  ),
                  title: Text(
                    'Use Current Location',
                    style: TextStyle(
                      color: _getTextColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Get your current location',
                    style: TextStyle(
                      color: _getSubtitleColor(context),
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    // Simulate getting current location
                    setState(() {
                      _location = {
                        'lat': 12.9716,
                        'lng': 77.5946,
                        'name': 'Current Location',
                      };
                      _hasUnsavedChanges = true;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Current location added'),
                        backgroundColor: Color(0xFF4A6CF7),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                Divider(color: _getBorderColor(context)),
                // Location List
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredLocations.length,
                    itemBuilder: (context, index) {
                      final location = filteredLocations[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: Color(0xFF4A6CF7),
                        ),
                        title: Text(
                          location['name'],
                          style: TextStyle(color: _getTextColor(context)),
                        ),
                        onTap: () {
                          setState(() {
                            _location = location;
                            _hasUnsavedChanges = true;
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Location: ${location['name']}'),
                              backgroundColor: const Color(0xFF4A6CF7),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFeelingActivity() {
    final feelings = [
      {'emoji': '😊', 'text': 'Happy'},
      {'emoji': '😢', 'text': 'Sad'},
      {'emoji': '😍', 'text': 'Loved'},
      {'emoji': '😎', 'text': 'Cool'},
      {'emoji': '🎉', 'text': 'Celebrating'},
      {'emoji': '🤔', 'text': 'Thinking'},
      {'emoji': '😴', 'text': 'Tired'},
      {'emoji': '🔥', 'text': 'Excited'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _getCardColor(context),
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
                color: _getBorderColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'How are you feeling?',
              style: TextStyle(
                color: _getTextColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: feelings.length,
              itemBuilder: (context, index) {
                final feeling = feelings[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _feeling = '${feeling['emoji']} ${feeling['text']}';
                      _hasUnsavedChanges = true;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getBackgroundColor(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _getBorderColor(context)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          feeling['emoji']!,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          feeling['text']!,
                          style: TextStyle(
                            color: _getSubtitleColor(context),
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showCreatePoll() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController questionController =
            TextEditingController();
        final List<TextEditingController> optionControllers = [
          TextEditingController(),
          TextEditingController(),
        ];

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _getCardColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Create Poll',
                style: TextStyle(
                  color: _getTextColor(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: questionController,
                      style: TextStyle(color: _getTextColor(context)),
                      decoration: InputDecoration(
                        hintText: 'Ask a question...',
                        hintStyle: TextStyle(color: _getSubtitleColor(context)),
                        filled: true,
                        fillColor: _getBackgroundColor(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(optionControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          controller: optionControllers[index],
                          style: TextStyle(color: _getTextColor(context)),
                          decoration: InputDecoration(
                            hintText: 'Option ${index + 1}',
                            hintStyle: TextStyle(
                              color: _getSubtitleColor(context),
                            ),
                            filled: true,
                            fillColor: _getBackgroundColor(context),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      );
                    }),
                    if (optionControllers.length < 5)
                      TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            optionControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add, color: Color(0xFF4A6CF7)),
                        label: const Text(
                          'Add Option',
                          style: TextStyle(color: Color(0xFF4A6CF7)),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: _getSubtitleColor(context)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (questionController.text.isNotEmpty) {
                      setState(() {
                        _poll = {
                          'question': questionController.text,
                          'options': optionControllers
                              .map((c) => c.text)
                              .where((t) => t.isNotEmpty)
                              .toList(),
                        };
                        _hasUnsavedChanges = true;
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Create',
                    style: TextStyle(color: Color(0xFF4A6CF7)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSchedulePost() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF4A6CF7),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1A1D24),
                    onSurface: Colors.white,
                  )
                : ColorScheme.light(
                    primary: const Color(0xFF4A6CF7),
                    onPrimary: Colors.white,
                    surface: Colors.grey[100]!,
                    onSurface: Colors.black87,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: isDark
                  ? const ColorScheme.dark(
                      primary: Color(0xFF4A6CF7),
                      onPrimary: Colors.white,
                      surface: Color(0xFF1A1D24),
                      onSurface: Colors.white,
                    )
                  : ColorScheme.light(
                      primary: const Color(0xFF4A6CF7),
                      onPrimary: Colors.white,
                      surface: Colors.grey[100]!,
                      onSurface: Colors.black87,
                    ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _scheduledDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          _hasUnsavedChanges = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Post scheduled for ${date.day}/${date.month}/${date.year} at ${time.format(context)}',
              ),
              backgroundColor: const Color(0xFF4A6CF7),
            ),
          );
        }
      }
    }
  }

  void _showAdvancedSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: _getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _getBorderColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Advanced Settings',
              style: TextStyle(
                color: _getTextColor(context),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildSettingTile(
                    'Enable Comments',
                    'Allow people to comment on your post',
                    _enableComments,
                    (val) => setState(() => _enableComments = val),
                  ),
                  _buildSettingTile(
                    'Enable Reactions',
                    'Allow people to react to your post',
                    _enableReactions,
                    (val) => setState(() => _enableReactions = val),
                  ),
                  _buildSettingTile(
                    'Cross-post to Twitter',
                    'Share this post on Twitter',
                    _crossPostTwitter,
                    (val) => setState(() => _crossPostTwitter = val),
                  ),
                  _buildSettingTile(
                    'Cross-post to LinkedIn',
                    'Share this post on LinkedIn',
                    _crossPostLinkedIn,
                    (val) => setState(() => _crossPostLinkedIn = val),
                  ),
                  _buildSettingTile(
                    'Content Warning',
                    'Mark this post as sensitive content',
                    _showContentWarning,
                    (val) => setState(() => _showContentWarning = val),
                  ),
                  if (_showContentWarning)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TextField(
                        style: TextStyle(color: _getTextColor(context)),
                        onChanged: (val) => _contentWarningText = val,
                        decoration: InputDecoration(
                          hintText: 'Warning text...',
                          hintStyle: TextStyle(
                            color: _getSubtitleColor(context),
                          ),
                          filled: true,
                          fillColor: _getBackgroundColor(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  _buildSettingTile(
                    'Boost Post',
                    'Promote this post to reach more people',
                    _enableBoost,
                    (val) => setState(() => _enableBoost = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            color: _getTextColor(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: _getSubtitleColor(context), fontSize: 12),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF4A6CF7),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: _getCardColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _getTextColor(context)),
          onPressed: () async {
            if (_hasUnsavedChanges) {
              final shouldSave = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: _getCardColor(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    'Save draft?',
                    style: TextStyle(
                      color: _getTextColor(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    'You have unsaved changes. Save as draft?',
                    style: TextStyle(color: _getSubtitleColor(context)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Discard',
                        style: TextStyle(color: _getSubtitleColor(context)),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Save',
                        style: TextStyle(color: Color(0xFF4A6CF7)),
                      ),
                    ),
                  ],
                ),
              );
              if (shouldSave == true) {
                await _saveDraft();
              }
            }
            if (mounted) Navigator.pop(context);
          },
        ),
        title: Text(
          'Create Post',
          style: TextStyle(
            color: _getTextColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isUploading)
            Container(
              margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              child: ElevatedButton(
                onPressed: _publishPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6CF7),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Publish',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Main scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User avatar and audience selector
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(
                              0xFF4A6CF7,
                            ).withOpacity(0.2),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF4A6CF7),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Name',
                                  style: TextStyle(
                                    color: _getTextColor(context),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: _showAudienceSelector,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getCardColor(context),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _getBorderColor(context),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getAudienceIcon(),
                                          size: 14,
                                          color: const Color(0xFF4A6CF7),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _selectedAudience,
                                          style: TextStyle(
                                            color: _getSubtitleColor(context),
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 14,
                                          color: _getSubtitleColor(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Title input
                      TextField(
                        controller: _titleController,
                        style: TextStyle(
                          color: _getTextColor(context),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add a title...',
                          hintStyle: TextStyle(
                            color: _getSubtitleColor(context),
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Text content
                      TextField(
                        controller: _textController,
                        style: TextStyle(
                          color: _getTextColor(context),
                          fontSize: 16,
                          height: 1.5,
                        ),
                        maxLines: null,
                        minLines: 3,
                        decoration: InputDecoration(
                          hintText: "What's on your mind?",
                          hintStyle: TextStyle(
                            color: _getSubtitleColor(context),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Media carousel with glassmorphism
                      if (_selectedMedia.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          height: 180,
                          child: ReorderableListView.builder(
                            scrollDirection: Axis.horizontal,
                            onReorder: _reorderMedia,
                            itemCount: _selectedMedia.length,
                            itemBuilder: (context, index) {
                              final media = _selectedMedia[index];
                              return Container(
                                key: ValueKey(media.path),
                                margin: const EdgeInsets.only(right: 12),
                                width: 140,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    children: [
                                      Image.file(
                                        File(media.path),
                                        width: 140,
                                        height: 180,
                                        fit: BoxFit.cover,
                                      ),
                                      // Gradient overlay
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.black.withOpacity(0.3),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Close button
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () => _removeMedia(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.6,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Index indicator
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.6,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            '${index + 1}/${_selectedMedia.length}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      // Active tags/additions section
                      if (_taggedUsers.isNotEmpty ||
                          _location != null ||
                          _feeling != null ||
                          _poll != null ||
                          _scheduledDate != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _getCardColor(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _getBorderColor(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tagged users
                              if (_taggedUsers.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _taggedUsers.map((user) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF4A6CF7,
                                          ).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF4A6CF7,
                                            ).withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.person,
                                              size: 14,
                                              color: Color(0xFF4A6CF7),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              user['name'],
                                              style: TextStyle(
                                                color: _getTextColor(context),
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _taggedUsers.remove(user);
                                                  _hasUnsavedChanges = true;
                                                });
                                              },
                                              child: Icon(
                                                Icons.close,
                                                size: 14,
                                                color: _getSubtitleColor(
                                                  context,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),

                              // Location
                              if (_location != null)
                                _buildInfoChip(
                                  Icons.location_on,
                                  _location!['name'],
                                  Colors.red,
                                  () {
                                    setState(() {
                                      _location = null;
                                      _hasUnsavedChanges = true;
                                    });
                                  },
                                ),

                              // Feeling
                              if (_feeling != null)
                                _buildInfoChip(
                                  Icons.emoji_emotions,
                                  _feeling!,
                                  Colors.orange,
                                  () {
                                    setState(() {
                                      _feeling = null;
                                      _hasUnsavedChanges = true;
                                    });
                                  },
                                ),

                              // Scheduled date
                              if (_scheduledDate != null)
                                _buildInfoChip(
                                  Icons.schedule,
                                  'Scheduled for ${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}',
                                  Colors.green,
                                  () {
                                    setState(() {
                                      _scheduledDate = null;
                                      _hasUnsavedChanges = true;
                                    });
                                  },
                                ),

                              // Poll
                              if (_poll != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getCardColor(context),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getBorderColor(context),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.poll,
                                            color: Color(0xFF4A6CF7),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _poll!['question'],
                                              style: TextStyle(
                                                color: _getTextColor(context),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _poll = null;
                                                _hasUnsavedChanges = true;
                                              });
                                            },
                                            child: Icon(
                                              Icons.close,
                                              color: _getSubtitleColor(context),
                                              size: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ...(_poll!['options'] as List).map((
                                        option,
                                      ) {
                                        return Container(
                                          margin: const EdgeInsets.only(top: 6),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? const Color(0xFF1A1D24)
                                                : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF4A6CF7),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                option,
                                                style: TextStyle(
                                                  color: _getSubtitleColor(
                                                    context,
                                                  ),
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom action bar with glassmorphism
              Container(
                decoration: BoxDecoration(
                  color: _getCardColor(context),
                  border: Border(
                    top: BorderSide(color: _getBorderColor(context)),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Main quick actions
                        Row(
                          children: [
                            _buildQuickActionButton(
                              Icons.photo_library,
                              'Media',
                              _showMediaOptions,
                            ),
                            _buildQuickActionButton(
                              Icons.person_add_outlined,
                              'Tag',
                              _showTagPeopleDialog,
                            ),
                            _buildQuickActionButton(
                              Icons.location_on_outlined,
                              'Location',
                              _showLocationPicker,
                            ),
                            _buildQuickActionButton(
                              Icons.emoji_emotions_outlined,
                              'Feeling',
                              _showFeelingActivity,
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _showMoreOptions,
                              icon: Icon(
                                Icons.more_horiz,
                                color: _getTextColor(context),
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: _getBackgroundColor(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Upload progress overlay
          if (_isUploading)
            Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.9)
                  : Colors.white.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF4A6CF7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Publishing your post...',
                      style: TextStyle(
                        color: _getTextColor(context),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style: TextStyle(
                        color: _getSubtitleColor(context),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 250,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1D24),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF4A6CF7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getAudienceIcon() {
    switch (_selectedAudience) {
      case 'Public':
        return Icons.public;
      case 'Friends':
        return Icons.people;
      case 'Only me':
        return Icons.lock;
      default:
        return Icons.settings;
    }
  }

  Widget _buildInfoChip(
    IconData icon,
    String text,
    Color color,
    VoidCallback onRemove,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: _getTextColor(context), fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: _getSubtitleColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getBorderColor(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFF4A6CF7), size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: _getSubtitleColor(context),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _getBorderColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'More Options',
              style: TextStyle(
                color: _getTextColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildMoreOption(
              Icons.poll_outlined,
              'Create Poll',
              _showCreatePoll,
            ),
            _buildMoreOption(
              Icons.schedule_outlined,
              'Schedule Post',
              _showSchedulePost,
            ),
            _buildMoreOption(Icons.save_outlined, 'Save as Draft', () {
              Navigator.pop(context);
              _saveDraft(showMessage: true);
            }),
            _buildMoreOption(
              Icons.settings_outlined,
              'Advanced Settings',
              _showAdvancedSettings,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreOption(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF4A6CF7).withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF4A6CF7), size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(color: _getTextColor(context), fontSize: 15),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: _getSubtitleColor(context),
        size: 16,
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _showCustomAudienceSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Sample followers and following data
          final List<Map<String, dynamic>> followers = [
            {
              'id': '1',
              'name': 'John Doe',
              'username': '@johndoe',
              'avatar': 'https://i.pravatar.cc/150?img=1',
            },
            {
              'id': '2',
              'name': 'Jane Smith',
              'username': '@janesmith',
              'avatar': 'https://i.pravatar.cc/150?img=2',
            },
            {
              'id': '3',
              'name': 'Mike Johnson',
              'username': '@mikej',
              'avatar': 'https://i.pravatar.cc/150?img=3',
            },
            {
              'id': '4',
              'name': 'Sarah Williams',
              'username': '@sarahw',
              'avatar': 'https://i.pravatar.cc/150?img=4',
            },
            {
              'id': '5',
              'name': 'Tom Brown',
              'username': '@tombrown',
              'avatar': 'https://i.pravatar.cc/150?img=5',
            },
            {
              'id': '6',
              'name': 'Emily Davis',
              'username': '@emilyd',
              'avatar': 'https://i.pravatar.cc/150?img=6',
            },
            {
              'id': '7',
              'name': 'Chris Wilson',
              'username': '@chrisw',
              'avatar': 'https://i.pravatar.cc/150?img=7',
            },
            {
              'id': '8',
              'name': 'Lisa Anderson',
              'username': '@lisaa',
              'avatar': 'https://i.pravatar.cc/150?img=8',
            },
          ];

          final List<Map<String, dynamic>> following = [
            {
              'id': '9',
              'name': 'David Lee',
              'username': '@davidlee',
              'avatar': 'https://i.pravatar.cc/150?img=9',
            },
            {
              'id': '10',
              'name': 'Amy Chen',
              'username': '@amychen',
              'avatar': 'https://i.pravatar.cc/150?img=10',
            },
            {
              'id': '11',
              'name': 'Mark Taylor',
              'username': '@markt',
              'avatar': 'https://i.pravatar.cc/150?img=11',
            },
            {
              'id': '12',
              'name': 'Jessica Moore',
              'username': '@jessicam',
              'avatar': 'https://i.pravatar.cc/150?img=12',
            },
            {
              'id': '13',
              'name': 'Ryan Garcia',
              'username': '@ryang',
              'avatar': 'https://i.pravatar.cc/150?img=13',
            },
            {
              'id': '14',
              'name': 'Sophia Martinez',
              'username': '@sophiam',
              'avatar': 'https://i.pravatar.cc/150?img=14',
            },
          ];

          final allUsers = [...followers, ...following];
          String searchQuery = '';
          List<Map<String, dynamic>> filteredUsers = allUsers;

          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: _getCardColor(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _getBorderColor(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back,
                          color: _getTextColor(context),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Custom Audience',
                          style: TextStyle(
                            color: _getTextColor(context),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedAudience = 'Custom';
                            _hasUnsavedChanges = true;
                          });
                          Navigator.pop(context);
                          _showSnackBar(
                            '${_customAudienceUsers.length} people selected',
                            const Color(0xFF4A6CF7),
                          );
                        },
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: Color(0xFF4A6CF7),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    style: TextStyle(color: _getTextColor(context)),
                    onChanged: (value) {
                      setModalState(() {
                        searchQuery = value.toLowerCase();
                        if (searchQuery.isEmpty) {
                          filteredUsers = allUsers;
                        } else {
                          filteredUsers = allUsers.where((user) {
                            return user['name']
                                    .toString()
                                    .toLowerCase()
                                    .contains(searchQuery) ||
                                user['username']
                                    .toString()
                                    .toLowerCase()
                                    .contains(searchQuery);
                          }).toList();
                        }
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search people...',
                      hintStyle: TextStyle(color: _getSubtitleColor(context)),
                      prefixIcon: Icon(
                        Icons.search,
                        color: _getSubtitleColor(context),
                      ),
                      filled: true,
                      fillColor: _getBackgroundColor(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Selected count
                if (_customAudienceUsers.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A6CF7).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF4A6CF7).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF4A6CF7),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_customAudienceUsers.length} people selected',
                          style: const TextStyle(
                            color: Color(0xFF4A6CF7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              _customAudienceUsers.clear();
                            });
                            setState(() {});
                          },
                          child: const Text(
                            'Clear all',
                            style: TextStyle(
                              color: Color(0xFF4A6CF7),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Tabs for Followers and Following
                DefaultTabController(
                  length: 3,
                  child: Expanded(
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: const Color(0xFF4A6CF7),
                          unselectedLabelColor: _getSubtitleColor(context),
                          indicatorColor: const Color(0xFF4A6CF7),
                          tabs: const [
                            Tab(text: 'All'),
                            Tab(text: 'Followers'),
                            Tab(text: 'Following'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildUserList(filteredUsers, setModalState),
                              _buildUserList(
                                followers.where((u) {
                                  if (searchQuery.isEmpty) return true;
                                  return u['name']
                                          .toString()
                                          .toLowerCase()
                                          .contains(searchQuery) ||
                                      u['username']
                                          .toString()
                                          .toLowerCase()
                                          .contains(searchQuery);
                                }).toList(),
                                setModalState,
                              ),
                              _buildUserList(
                                following.where((u) {
                                  if (searchQuery.isEmpty) return true;
                                  return u['name']
                                          .toString()
                                          .toLowerCase()
                                          .contains(searchQuery) ||
                                      u['username']
                                          .toString()
                                          .toLowerCase()
                                          .contains(searchQuery);
                                }).toList(),
                                setModalState,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserList(
    List<Map<String, dynamic>> users,
    StateSetter setModalState,
  ) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: _getSubtitleColor(context)),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(color: _getSubtitleColor(context), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isSelected = _customAudienceUsers.any(
          (u) => u['id'] == user['id'],
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: _getBackgroundColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4A6CF7)
                  : _getBorderColor(context),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF4A6CF7),
              child: Text(
                user['name'].toString()[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              user['name'],
              style: TextStyle(
                color: _getTextColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              user['username'],
              style: TextStyle(color: _getSubtitleColor(context), fontSize: 13),
            ),
            trailing: Checkbox(
              value: isSelected,
              onChanged: (value) {
                setModalState(() {
                  if (value == true) {
                    _customAudienceUsers.add(user);
                  } else {
                    _customAudienceUsers.removeWhere(
                      (u) => u['id'] == user['id'],
                    );
                  }
                });
                setState(() {});
              },
              activeColor: const Color(0xFF4A6CF7),
            ),
            onTap: () {
              setModalState(() {
                if (isSelected) {
                  _customAudienceUsers.removeWhere(
                    (u) => u['id'] == user['id'],
                  );
                } else {
                  _customAudienceUsers.add(user);
                }
              });
              setState(() {});
            },
          ),
        );
      },
    );
  }

  // Theme helper methods
  Color _getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0B0E13)
        : Colors.white;
  }

  Color _getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1D24)
        : Colors.grey[100]!;
  }

  Color _getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

  Color _getSubtitleColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white54
        : Colors.grey[600]!;
  }

  Color _getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white12
        : Colors.grey[300]!;
  }
}
