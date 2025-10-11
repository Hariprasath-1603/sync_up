import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'models/story_model.dart';

class TextLayer {
  String text;
  Offset position;
  Color color;
  double fontSize;
  String fontFamily;

  TextLayer({
    required this.text,
    required this.position,
    this.color = Colors.white,
    this.fontSize = 24,
    this.fontFamily = 'default',
  });
}

class StickerLayer {
  String type; // emoji, gif, mention, hashtag, location, etc.
  String value;
  Offset position;
  double size;

  StickerLayer({
    required this.type,
    required this.value,
    required this.position,
    this.size = 64,
  });
}

class CreateStoryPage extends StatefulWidget {
  final XFile? initialMedia;
  final StoryMediaType? mediaType;

  const CreateStoryPage({
    super.key,
    this.initialMedia,
    this.mediaType,
  });

  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  XFile? _media;
  StoryMediaType _mediaType = StoryMediaType.image;
  final _captionController = TextEditingController();
  
  // Creative layers
  final List<TextLayer> _textLayers = [];
  final List<StickerLayer> _stickerLayers = [];
  String _selectedFilter = 'None';
  String? _selectedMusic;
  
  // Publishing options
  StoryAudience _audience = StoryAudience.public;
  bool _allowReplies = true;
  bool _allowSharing = true;
  bool _addToHighlights = false;
  String? _location;
  final List<String> _mentions = [];
  final List<String> _hashtags = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialMedia != null) {
      _media = widget.initialMedia;
      _mediaType = widget.mediaType ?? StoryMediaType.image;
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0F1419)
        : const Color(0xFFF8F9FA);
  }

  Color _getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1D24)
        : Colors.white;
  }

  Color _getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  Color _getSubtitleColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF8899A6)
        : const Color(0xFF536471);
  }

  Color _getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2F3336)
        : const Color(0xFFE1E8ED);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _captureMedia(ImageSource source) async {
    try {
      final picker = ImagePicker();
      
      // Show media type selector
      final mediaType = await showDialog<StoryMediaType>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _getCardColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Capture', style: TextStyle(color: _getTextColor(context))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo, color: Color(0xFF4A6CF7)),
                title: Text('Photo', style: TextStyle(color: _getTextColor(context))),
                onTap: () => Navigator.pop(context, StoryMediaType.image),
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Color(0xFF4A6CF7)),
                title: Text('Video', style: TextStyle(color: _getTextColor(context))),
                onTap: () => Navigator.pop(context, StoryMediaType.video),
              ),
            ],
          ),
        ),
      );

      if (mediaType == null) return;

      final XFile? file;
      if (mediaType == StoryMediaType.image) {
        file = await picker.pickImage(
          source: source,
          imageQuality: 80,
        );
      } else {
        file = await picker.pickVideo(
          source: source,
          maxDuration: const Duration(seconds: 60),
        );
      }

      if (file != null) {
        setState(() {
          _media = file;
          _mediaType = mediaType;
        });
      }
    } catch (e) {
      _showSnackBar('Error selecting media', Colors.red);
    }
  }

  void _showTextEditor() {
    final textController = TextEditingController();
    Color selectedColor = Colors.white;
    double fontSize = 24;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: _getCardColor(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Add Text', style: TextStyle(color: _getTextColor(context))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  autofocus: true,
                  style: TextStyle(color: _getTextColor(context)),
                  decoration: InputDecoration(
                    hintText: 'Type something...',
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
                Row(
                  children: [
                    Text(
                      'Size',
                      style: TextStyle(
                        color: _getTextColor(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: fontSize,
                        min: 12,
                        max: 48,
                        divisions: 36,
                        label: fontSize.toStringAsFixed(0),
                        activeColor: const Color(0xFF4A6CF7),
                        onChanged: (value) {
                          setDialogState(() {
                            fontSize = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Color',
                  style: TextStyle(
                    color: _getTextColor(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    Colors.white,
                    Colors.black,
                    Colors.red,
                    Colors.blue,
                    Colors.green,
                    Colors.yellow,
                    Colors.purple,
                    Colors.orange,
                    Colors.pink,
                  ].map((color) {
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color
                                ? const Color(0xFF4A6CF7)
                                : Colors.grey,
                            width: selectedColor == color ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: _getSubtitleColor(context))),
              ),
              TextButton(
                onPressed: () {
                  if (textController.text.isNotEmpty) {
                    setState(() {
                      _textLayers.add(TextLayer(
                        text: textController.text,
                        position: const Offset(100, 200),
                        color: selectedColor,
                        fontSize: fontSize,
                      ));
                    });
                    Navigator.pop(context);
                    _showSnackBar('Text added', const Color(0xFF4A6CF7));
                  }
                },
                child: const Text('Add', style: TextStyle(color: Color(0xFF4A6CF7))),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStickerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: _getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            Text(
              'Add Sticker',
              style: TextStyle(
                color: _getTextColor(context),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: const Color(0xFF4A6CF7),
                      unselectedLabelColor: _getSubtitleColor(context),
                      indicatorColor: const Color(0xFF4A6CF7),
                      tabs: const [
                        Tab(icon: Icon(Icons.emoji_emotions), text: 'Emoji'),
                        Tab(icon: Icon(Icons.alternate_email), text: 'Mention'),
                        Tab(icon: Icon(Icons.location_on), text: 'Location'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildEmojiGrid(),
                          _buildMentionList(),
                          _buildLocationList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiGrid() {
    final emojis = [
      '😀', '😂', '😍', '🥳', '😎', '🤩', '🔥', '❤️',
      '⭐', '✨', '💯', '👍', '👏', '🎉', '🎊', '🎈',
      '🌟', '💫', '🌈', '☀️', '🌙', '⚡', '💥', '🎵',
      '🎸', '🎤', '🎧', '🎮', '⚽', '🏀', '🍕', '🍔',
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _stickerLayers.add(StickerLayer(
                type: 'emoji',
                value: emojis[index],
                position: Offset(
                  150 + (_stickerLayers.length * 20.0),
                  250 + (_stickerLayers.length * 20.0),
                ),
              ));
            });
            Navigator.pop(context);
            _showSnackBar('Sticker added', const Color(0xFF4A6CF7));
          },
          child: Container(
            decoration: BoxDecoration(
              color: _getBackgroundColor(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                emojis[index],
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMentionList() {
    // TODO: Replace with real user search
    final users = [
      {'username': 'john_doe', 'avatar': null},
      {'username': 'jane_smith', 'avatar': null},
      {'username': 'alex_dev', 'avatar': null},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: users.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF4A6CF7),
            child: Text(
              users[index]['username']!.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            '@${users[index]['username']}',
            style: TextStyle(color: _getTextColor(context)),
          ),
          onTap: () {
            final username = users[index]['username']!;
            setState(() {
              _mentions.add(username);
              _stickerLayers.add(StickerLayer(
                type: 'mention',
                value: '@$username',
                position: const Offset(100, 300),
                size: 48,
              ));
            });
            Navigator.pop(context);
            _showSnackBar('Mention added', const Color(0xFF4A6CF7));
          },
        );
      },
    );
  }

  Widget _buildLocationList() {
    final locations = [
      'Bengaluru, India',
      'Mumbai, India',
      'Delhi, India',
      'New York, USA',
      'London, UK',
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.location_on, color: Color(0xFF4A6CF7)),
          title: Text(
            locations[index],
            style: TextStyle(color: _getTextColor(context)),
          ),
          onTap: () {
            setState(() {
              _location = locations[index];
              _stickerLayers.add(StickerLayer(
                type: 'location',
                value: locations[index],
                position: const Offset(100, 400),
                size: 40,
              ));
            });
            Navigator.pop(context);
            _showSnackBar('Location added', const Color(0xFF4A6CF7));
          },
        );
      },
    );
  }

  void _showFilterSelector() {
    final filters = [
      'None', 'Bright', 'Vintage', 'B&W', 'Sepia', 
      'Cool', 'Warm', 'Vivid', 'Fade',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: _getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            Text(
              'Filters',
              style: TextStyle(
                color: _getTextColor(context),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: filters.length,
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = _selectedFilter == filter;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                      Navigator.pop(context);
                      _showSnackBar('Filter "$filter" applied', const Color(0xFF4A6CF7));
                    },
                    child: Column(
                      children: [
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: _getBackgroundColor(context),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF4A6CF7)
                                  : _getBorderColor(context),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.filter,
                              color: isSelected
                                  ? const Color(0xFF4A6CF7)
                                  : _getSubtitleColor(context),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          filter,
                          style: TextStyle(
                            color: _getTextColor(context),
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMusicPicker() {
    final tracks = [
      'Summer Vibes',
      'Chill Beats',
      'Party Time',
      'Sunset Dreams',
      'Indie Mix',
      'Hip Hop',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: _getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            Text(
              'Add Music',
              style: TextStyle(
                color: _getTextColor(context),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedMusic == tracks[index];
                  
                  return ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A6CF7).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.music_note, color: Color(0xFF4A6CF7)),
                    ),
                    title: Text(
                      tracks[index],
                      style: TextStyle(
                        color: _getTextColor(context),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      'Artist Name',
                      style: TextStyle(color: _getSubtitleColor(context), fontSize: 12),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Color(0xFF4A6CF7))
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedMusic = tracks[index];
                      });
                      Navigator.pop(context);
                      _showSnackBar('Music added', const Color(0xFF4A6CF7));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPublishingOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: _getCardColor(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _getBorderColor(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Story Settings',
                  style: TextStyle(
                    color: _getTextColor(context),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Audience
                Text(
                  'Who can see this?',
                  style: TextStyle(
                    color: _getTextColor(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...StoryAudience.values.map((audience) {
                  return RadioListTile<StoryAudience>(
                    value: audience,
                    groupValue: _audience,
                    activeColor: const Color(0xFF4A6CF7),
                    title: Text(
                      _getAudienceLabel(audience),
                      style: TextStyle(color: _getTextColor(context)),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        setState(() {
                          _audience = value!;
                        });
                      });
                    },
                  );
                }).toList(),
                const SizedBox(height: 16),
                
                // Settings
                SwitchListTile(
                  value: _allowReplies,
                  activeColor: const Color(0xFF4A6CF7),
                  title: Text('Allow Replies', style: TextStyle(color: _getTextColor(context))),
                  onChanged: (value) {
                    setModalState(() {
                      setState(() {
                        _allowReplies = value;
                      });
                    });
                  },
                ),
                SwitchListTile(
                  value: _allowSharing,
                  activeColor: const Color(0xFF4A6CF7),
                  title: Text('Allow Sharing', style: TextStyle(color: _getTextColor(context))),
                  onChanged: (value) {
                    setModalState(() {
                      setState(() {
                        _allowSharing = value;
                      });
                    });
                  },
                ),
                SwitchListTile(
                  value: _addToHighlights,
                  activeColor: const Color(0xFF4A6CF7),
                  title: Text('Add to Highlights', style: TextStyle(color: _getTextColor(context))),
                  onChanged: (value) {
                    setModalState(() {
                      setState(() {
                        _addToHighlights = value;
                      });
                    });
                  },
                ),
                const Spacer(),
                
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A6CF7),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getAudienceLabel(StoryAudience audience) {
    switch (audience) {
      case StoryAudience.public:
        return 'Public';
      case StoryAudience.friendsOnly:
        return 'Friends Only';
      case StoryAudience.closeFriends:
        return 'Close Friends';
      case StoryAudience.custom:
        return 'Custom';
    }
  }

  Future<void> _publishStory() async {
    if (_media == null) {
      _showSnackBar('Please add media', Colors.orange);
      return;
    }

    // Show uploading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _getCardColor(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF4A6CF7)),
              const SizedBox(height: 16),
              Text(
                'Publishing story...',
                style: TextStyle(color: _getTextColor(context)),
              ),
            ],
          ),
        ),
      ),
    );

    // Simulate upload
    await Future.delayed(const Duration(seconds: 2));

    // Create story model
    final story = StoryModel(
      id: 'story_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'current_user_id',
      username: 'current_username',
      mediaType: _mediaType,
      mediaUrl: _media!.path,
      caption: _captionController.text.trim(),
      audience: _audience,
      location: _location,
      mentions: _mentions,
      hashtags: _hashtags,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      allowReplies: _allowReplies,
      allowSharing: _allowSharing,
      addedToHighlights: _addToHighlights,
    );

    if (mounted) {
      Navigator.pop(context); // Close upload dialog
      Navigator.pop(context, story); // Return to previous screen with story
      _showSnackBar('Story published!', Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Media preview
          if (_media != null)
            Positioned.fill(
              child: Container(
                color: Colors.grey[900],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _mediaType == StoryMediaType.image
                            ? Icons.image
                            : Icons.videocam,
                        size: 100,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _media!.name,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 16,
                        ),
                      ),
                      if (_selectedFilter != 'None')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A6CF7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Filter: $_selectedFilter',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 100,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Add Photo or Video',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Render text layers
          ..._textLayers.asMap().entries.map((entry) {
            final index = entry.key;
            final layer = entry.value;
            return Positioned(
              left: layer.position.dx,
              top: layer.position.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _textLayers[index].position += details.delta;
                  });
                },
                onLongPress: () {
                  setState(() {
                    _textLayers.removeAt(index);
                  });
                  _showSnackBar('Text removed', Colors.orange);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    layer.text,
                    style: TextStyle(
                      color: layer.color,
                      fontSize: layer.fontSize,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: const Offset(1, 1),
                          blurRadius: 2,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),

          // Render sticker layers
          ..._stickerLayers.asMap().entries.map((entry) {
            final index = entry.key;
            final layer = entry.value;
            return Positioned(
              left: layer.position.dx,
              top: layer.position.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _stickerLayers[index].position += details.delta;
                  });
                },
                onLongPress: () {
                  setState(() {
                    _stickerLayers.removeAt(index);
                  });
                  _showSnackBar('Sticker removed', Colors.orange);
                },
                child: layer.type == 'emoji'
                    ? Text(layer.value, style: TextStyle(fontSize: layer.size))
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A6CF7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              layer.type == 'mention'
                                  ? Icons.alternate_email
                                  : Icons.location_on,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              layer.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            );
          }).toList(),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  if (_media != null) ...[
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: _showPublishingOptions,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Creative tools (side panel)
          if (_media != null)
            Positioned(
              right: 16,
              top: MediaQuery.of(context).padding.top + 100,
              child: Column(
                children: [
                  _buildToolButton(Icons.text_fields, 'Text', _showTextEditor),
                  const SizedBox(height: 12),
                  _buildToolButton(Icons.emoji_emotions, 'Sticker', _showStickerPicker),
                  const SizedBox(height: 12),
                  _buildToolButton(Icons.filter, 'Filter', _showFilterSelector),
                  const SizedBox(height: 12),
                  _buildToolButton(Icons.music_note, 'Music', _showMusicPicker),
                ],
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                top: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: _media == null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMediaSourceButton(
                          Icons.photo_library,
                          'Gallery',
                          () => _captureMedia(ImageSource.gallery),
                        ),
                        _buildMediaSourceButton(
                          Icons.camera_alt,
                          'Camera',
                          () => _captureMedia(ImageSource.camera),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _captionController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 1,
                            decoration: InputDecoration(
                              hintText: 'Add a caption...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4A6CF7),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _publishStory,
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

  Widget _buildToolButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMediaSourceButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 40),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
