import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Data models for overlays
class TextOverlay {
  String text;
  Offset position;
  Color color;
  double fontSize;
  FontStyle fontStyle;

  TextOverlay({
    required this.text,
    required this.position,
    this.color = Colors.white,
    this.fontSize = 24,
    this.fontStyle = FontStyle.normal,
  });
}

class StickerOverlay {
  String emoji;
  Offset position;
  double size;

  StickerOverlay({required this.emoji, required this.position, this.size = 64});
}

class CreateReelPage extends StatefulWidget {
  final String? preselectedAudioId;
  final bool isRemix;

  const CreateReelPage({
    super.key,
    this.preselectedAudioId,
    this.isRemix = false,
  });

  @override
  State<CreateReelPage> createState() => _CreateReelPageState();
}

class _CreateReelPageState extends State<CreateReelPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();

  XFile? _currentVideo;
  String _selectedAudio = 'Original Sound';
  double _coverFrameTime = 0.0;

  // Editing features
  String _selectedFilter = 'None';
  double _videoSpeed = 1.0;
  List<TextOverlay> _textOverlays = [];
  List<StickerOverlay> _stickerOverlays = [];
  bool _isPlaying = false;

  // Publishing metadata
  String _visibility = 'Public';
  bool _allowRemix = true;
  bool _allowDuet = true;
  bool _allowComments = true;
  bool _postToFeed = true;
  String? _location;
  List<String> _hashtags = [];
  List<String> _mentions = [];

  // Processing state
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedAudioId != null) {
      _selectedAudio = widget.preselectedAudioId!;
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  // Theme helpers
  Color _getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0B0E13)
        : const Color(0xFFF6F7FB);
  }

  Color _getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1D24)
        : Colors.white;
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

  Future<void> _recordVideo() async {
    try {
      final video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 90),
      );
      if (video != null) {
        setState(() {
          _currentVideo = video;
        });
      }
    } catch (e) {
      _showSnackBar('Error recording video: $e', Colors.red);
    }
  }

  Future<void> _uploadFromGallery() async {
    try {
      final video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _currentVideo = video;
        });
      }
    } catch (e) {
      _showSnackBar('Error selecting video: $e', Colors.red);
    }
  }

  void _showMediaSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
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
                'Create Reel',
                style: TextStyle(
                  color: _getTextColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildSourceOption(
                Icons.videocam,
                'Record Video',
                'Use camera to record',
                _recordVideo,
              ),
              _buildSourceOption(
                Icons.video_library,
                'Upload from Gallery',
                'Choose existing video',
                _uploadFromGallery,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF4A6CF7).withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF4A6CF7)),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _getTextColor(context),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: _getSubtitleColor(context), fontSize: 13),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _showAudioPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AudioPickerSheet(
        currentAudio: _selectedAudio,
        onSelect: (audio) {
          setState(() {
            _selectedAudio = audio;
          });
        },
      ),
    );
  }

  void _showSpeedControl() {
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
              'Video Speed',
              style: TextStyle(
                color: _getTextColor(context),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSpeedOption('0.5x', 0.5),
                _buildSpeedOption('1x', 1.0),
                _buildSpeedOption('1.5x', 1.5),
                _buildSpeedOption('2x', 2.0),
                _buildSpeedOption('3x', 3.0),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedOption(String label, double speed) {
    final isSelected = _videoSpeed == speed;
    return GestureDetector(
      onTap: () {
        setState(() {
          _videoSpeed = speed;
        });
        Navigator.pop(context);
        _showSnackBar('Speed set to $label', const Color(0xFF4A6CF7));
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A6CF7) : _getCardColor(context),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4A6CF7)
                : _getBorderColor(context),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : _getTextColor(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showFiltersAndEffects() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
              'Filters & Effects',
              style: TextStyle(
                color: _getTextColor(context),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.all(20),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildFilterOption('None', Icons.block),
                  _buildFilterOption('Bright', Icons.brightness_7),
                  _buildFilterOption('Warm', Icons.wb_sunny),
                  _buildFilterOption('Cool', Icons.ac_unit),
                  _buildFilterOption('Vintage', Icons.camera),
                  _buildFilterOption('B&W', Icons.filter_b_and_w),
                  _buildFilterOption('Sepia', Icons.palette),
                  _buildFilterOption('Vivid', Icons.color_lens),
                  _buildFilterOption('Fade', Icons.gradient),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String name, IconData icon) {
    final isSelected = _selectedFilter == name;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = name;
        });
        Navigator.pop(context);
        _showSnackBar('Filter "$name" applied', const Color(0xFF4A6CF7));
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4A6CF7).withOpacity(0.2)
              : _getCardColor(context),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4A6CF7)
                : _getBorderColor(context),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF4A6CF7)
                  : _getTextColor(context),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: _getTextColor(context),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTextEditor() {
    final textController = TextEditingController();
    Color selectedColor = Colors.white;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: _getCardColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Add Text',
              style: TextStyle(color: _getTextColor(context)),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  style: TextStyle(color: _getTextColor(context)),
                  decoration: InputDecoration(
                    hintText: 'Enter text...',
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
                Text(
                  'Text Color',
                  style: TextStyle(
                    color: _getTextColor(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children:
                      [
                        Colors.white,
                        Colors.black,
                        Colors.red,
                        Colors.blue,
                        Colors.green,
                        Colors.yellow,
                        Colors.purple,
                        Colors.orange,
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
                child: Text(
                  'Cancel',
                  style: TextStyle(color: _getSubtitleColor(context)),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (textController.text.isNotEmpty) {
                    setState(() {
                      _textOverlays.add(
                        TextOverlay(
                          text: textController.text,
                          position: const Offset(100, 200),
                          color: selectedColor,
                        ),
                      );
                    });
                    Navigator.pop(context);
                    _showSnackBar('Text added', const Color(0xFF4A6CF7));
                  }
                },
                child: const Text(
                  'Add',
                  style: TextStyle(color: Color(0xFF4A6CF7)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStickerPicker() {
    final stickers = [
      '😀',
      '😂',
      '😍',
      '🥳',
      '😎',
      '🤩',
      '🔥',
      '❤️',
      '⭐',
      '✨',
      '💯',
      '👍',
      '👏',
      '🎉',
      '🎊',
      '🎈',
      '🌟',
      '💫',
      '🌈',
      '☀️',
      '🌙',
      '⚡',
      '💥',
      '🎵',
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
              'Add Sticker',
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
                  crossAxisCount: 6,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: stickers.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _stickerOverlays.add(
                          StickerOverlay(
                            emoji: stickers[index],
                            position: Offset(
                              150 + (_stickerOverlays.length * 20.0),
                              250 + (_stickerOverlays.length * 20.0),
                            ),
                          ),
                        );
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
                          stickers[index],
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
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

  void _showPublishingOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PublishingOptionsSheet(
        caption: _captionController.text,
        visibility: _visibility,
        allowRemix: _allowRemix,
        allowDuet: _allowDuet,
        allowComments: _allowComments,
        postToFeed: _postToFeed,
        location: _location,
        hashtags: _hashtags,
        mentions: _mentions,
        onSave: (data) {
          setState(() {
            _captionController.text = data['caption'];
            _visibility = data['visibility'];
            _allowRemix = data['allowRemix'];
            _allowDuet = data['allowDuet'];
            _allowComments = data['allowComments'];
            _postToFeed = data['postToFeed'];
            _location = data['location'];
            _hashtags = data['hashtags'];
            _mentions = data['mentions'];
          });
        },
      ),
    );
  }

  Future<void> _publishReel() async {
    if (_currentVideo == null) {
      _showSnackBar('Please select or record a video', Colors.orange);
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

      final reelData = {
        'video_path': _currentVideo!.path,
        'caption': _captionController.text,
        'audio': _selectedAudio,
        'visibility': _visibility,
        'allow_remix': _allowRemix,
        'allow_duet': _allowDuet,
        'allow_comments': _allowComments,
        'post_to_feed': _postToFeed,
        'location': _location,
        'hashtags': _hashtags,
        'mentions': _mentions,
        'cover_frame_time': _coverFrameTime,
        'created_at': DateTime.now().toIso8601String(),
      };

      // TODO: Upload to server
      print('Reel published: $reelData');

      setState(() {
        _isUploading = false;
      });

      _showSnackBar('Reel published successfully!', Colors.green);

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showSnackBar('Error publishing reel: $e', Colors.red);
    }
  }

  void _saveToDrafts() {
    _showSnackBar('Saved to drafts', const Color(0xFF4A6CF7));
    Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: _getCardColor(context),
        leading: IconButton(
          icon: Icon(Icons.close, color: _getTextColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Reel',
          style: TextStyle(color: _getTextColor(context)),
        ),
        actions: [
          if (_currentVideo != null)
            TextButton(
              onPressed: _saveToDrafts,
              child: Text(
                'Save Draft',
                style: TextStyle(color: _getSubtitleColor(context)),
              ),
            ),
        ],
      ),
      body: _isUploading
          ? _buildUploadingView()
          : _currentVideo == null
          ? _buildInitialView()
          : _buildEditingView(),
    );
  }

  Widget _buildInitialView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_camera_back,
            size: 100,
            color: _getSubtitleColor(context),
          ),
          const SizedBox(height: 24),
          Text(
            'Create Your Reel',
            style: TextStyle(
              color: _getTextColor(context),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Record or upload a vertical video\n(9:16 aspect ratio, 5-90 seconds)',
            style: TextStyle(color: _getSubtitleColor(context), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: _showMediaSourceOptions,
            icon: const Icon(Icons.add),
            label: const Text('Get Started'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A6CF7),
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

  Widget _buildEditingView() {
    return Column(
      children: [
        // Video Preview
        Expanded(
          child: Container(
            color: Colors.black,
            child: Center(
              child: Stack(
                children: [
                  // Video player placeholder
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[900],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 80,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Video Preview',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentVideo!.name,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Top controls
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Column(
                      children: [
                        _buildEditButton(
                          Icons.music_note,
                          'Audio',
                          _showAudioPicker,
                        ),
                        const SizedBox(height: 12),
                        _buildEditButton(
                          Icons.speed,
                          'Speed',
                          _showSpeedControl,
                        ),
                        const SizedBox(height: 12),
                        _buildEditButton(
                          Icons.filter,
                          'Effects',
                          _showFiltersAndEffects,
                        ),
                        const SizedBox(height: 12),
                        _buildEditButton(
                          Icons.text_fields,
                          'Text',
                          _showTextEditor,
                        ),
                        const SizedBox(height: 12),
                        _buildEditButton(
                          Icons.emoji_emotions,
                          'Stickers',
                          _showStickerPicker,
                        ),
                      ],
                    ),
                  ),

                  // Render text overlays
                  ..._textOverlays.asMap().entries.map((entry) {
                    final index = entry.key;
                    final overlay = entry.value;
                    return Positioned(
                      left: overlay.position.dx,
                      top: overlay.position.dy,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _textOverlays[index] = TextOverlay(
                              text: overlay.text,
                              position: overlay.position + details.delta,
                              color: overlay.color,
                              fontSize: overlay.fontSize,
                              fontStyle: overlay.fontStyle,
                            );
                          });
                        },
                        onLongPress: () {
                          setState(() {
                            _textOverlays.removeAt(index);
                          });
                          _showSnackBar('Text removed', Colors.orange);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            overlay.text,
                            style: TextStyle(
                              color: overlay.color,
                              fontSize: overlay.fontSize,
                              fontStyle: overlay.fontStyle,
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

                  // Render sticker overlays
                  ..._stickerOverlays.asMap().entries.map((entry) {
                    final index = entry.key;
                    final overlay = entry.value;
                    return Positioned(
                      left: overlay.position.dx,
                      top: overlay.position.dy,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _stickerOverlays[index] = StickerOverlay(
                              emoji: overlay.emoji,
                              position: overlay.position + details.delta,
                              size: overlay.size,
                            );
                          });
                        },
                        onLongPress: () {
                          setState(() {
                            _stickerOverlays.removeAt(index);
                          });
                          _showSnackBar('Sticker removed', Colors.orange);
                        },
                        child: Text(
                          overlay.emoji,
                          style: TextStyle(fontSize: overlay.size),
                        ),
                      ),
                    );
                  }).toList(),

                  // Play/pause button
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPlaying = !_isPlaying;
                        });
                        _showSnackBar(
                          _isPlaying ? 'Playing video' : 'Video paused',
                          const Color(0xFF4A6CF7),
                        );
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),

                  // Speed indicator
                  if (_videoSpeed != 1.0)
                    Positioned(
                      bottom: 20,
                      left: 80,
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
                          '${_videoSpeed}x',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Filter indicator
                  if (_selectedFilter != 'None')
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A6CF7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.filter,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _selectedFilter,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Bottom controls
        Container(
          color: _getCardColor(context),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Caption input
              TextField(
                controller: _captionController,
                style: TextStyle(color: _getTextColor(context)),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Add a caption...',
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

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showPublishingOptions,
                      icon: const Icon(Icons.settings),
                      label: const Text('Options'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _getTextColor(context),
                        side: BorderSide(color: _getBorderColor(context)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _publishReel,
                      icon: const Icon(Icons.check),
                      label: const Text('Publish Reel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A6CF7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingView() {
    return Container(
      color: _getBackgroundColor(context),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A6CF7)),
            ),
            const SizedBox(height: 24),
            Text(
              'Publishing your reel...',
              style: TextStyle(
                color: _getTextColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${(_uploadProgress * 100).toInt()}%',
              style: TextStyle(color: _getSubtitleColor(context), fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              width: 250,
              height: 6,
              decoration: BoxDecoration(
                color: _getCardColor(context),
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
    );
  }
}

// Audio Picker Sheet
class _AudioPickerSheet extends StatefulWidget {
  final String currentAudio;
  final Function(String) onSelect;

  const _AudioPickerSheet({required this.currentAudio, required this.onSelect});

  @override
  State<_AudioPickerSheet> createState() => _AudioPickerSheetState();
}

class _AudioPickerSheetState extends State<_AudioPickerSheet> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _audioTracks = [
    {'id': '1', 'title': 'Original Sound', 'artist': 'Your Audio'},
    {'id': '2', 'title': 'Summer Vibes', 'artist': 'DJ Cool'},
    {'id': '3', 'title': 'Night Drive', 'artist': 'Synthwave'},
    {'id': '4', 'title': 'Happy Beat', 'artist': 'Pop Star'},
    {'id': '5', 'title': 'Chill Out', 'artist': 'Lofi Beats'},
    {'id': '6', 'title': 'Party Time', 'artist': 'Dance Mix'},
    {'id': '7', 'title': 'Dreamy Clouds', 'artist': 'Ambient Sounds'},
    {'id': '8', 'title': 'Epic Journey', 'artist': 'Orchestra'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1D24) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey[600]!;
    final backgroundColor = isDark
        ? const Color(0xFF0B0E13)
        : const Color(0xFFF6F7FB);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: subtitleColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Choose Audio',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Search music...',
                hintStyle: TextStyle(color: subtitleColor),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4A6CF7)),
                filled: true,
                fillColor: backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _audioTracks.length,
              itemBuilder: (context, index) {
                final track = _audioTracks[index];
                final isSelected = widget.currentAudio == track['title'];

                return ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A6CF7).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      color: Color(0xFF4A6CF7),
                    ),
                  ),
                  title: Text(
                    track['title']!,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    track['artist']!,
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Color(0xFF4A6CF7))
                      : null,
                  onTap: () {
                    widget.onSelect(track['title']!);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Publishing Options Sheet
class _PublishingOptionsSheet extends StatefulWidget {
  final String caption;
  final String visibility;
  final bool allowRemix;
  final bool allowDuet;
  final bool allowComments;
  final bool postToFeed;
  final String? location;
  final List<String> hashtags;
  final List<String> mentions;
  final Function(Map<String, dynamic>) onSave;

  const _PublishingOptionsSheet({
    required this.caption,
    required this.visibility,
    required this.allowRemix,
    required this.allowDuet,
    required this.allowComments,
    required this.postToFeed,
    required this.location,
    required this.hashtags,
    required this.mentions,
    required this.onSave,
  });

  @override
  State<_PublishingOptionsSheet> createState() =>
      _PublishingOptionsSheetState();
}

class _PublishingOptionsSheetState extends State<_PublishingOptionsSheet> {
  late String _visibility;
  late bool _allowRemix;
  late bool _allowDuet;
  late bool _allowComments;
  late bool _postToFeed;

  @override
  void initState() {
    super.initState();
    _visibility = widget.visibility;
    _allowRemix = widget.allowRemix;
    _allowDuet = widget.allowDuet;
    _allowComments = widget.allowComments;
    _postToFeed = widget.postToFeed;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1D24) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey[600]!;
    final borderColor = isDark ? Colors.white12 : Colors.grey[300]!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Publishing Options',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    widget.onSave({
                      'caption': widget.caption,
                      'visibility': _visibility,
                      'allowRemix': _allowRemix,
                      'allowDuet': _allowDuet,
                      'allowComments': _allowComments,
                      'postToFeed': _postToFeed,
                      'location': widget.location,
                      'hashtags': widget.hashtags,
                      'mentions': widget.mentions,
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Color(0xFF4A6CF7)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Visibility
                _buildOptionTile(
                  'Visibility',
                  _visibility,
                  Icons.public,
                  textColor,
                  subtitleColor,
                  () {
                    // Show visibility picker
                  },
                ),
                Divider(color: borderColor),

                // Switches
                SwitchListTile(
                  title: Text(
                    'Allow Remix',
                    style: TextStyle(color: textColor),
                  ),
                  subtitle: Text(
                    'Let others use your reel',
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                  value: _allowRemix,
                  activeColor: const Color(0xFF4A6CF7),
                  onChanged: (value) {
                    setState(() {
                      _allowRemix = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: Text('Allow Duet', style: TextStyle(color: textColor)),
                  subtitle: Text(
                    'Enable side-by-side videos',
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                  value: _allowDuet,
                  activeColor: const Color(0xFF4A6CF7),
                  onChanged: (value) {
                    setState(() {
                      _allowDuet = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: Text(
                    'Allow Comments',
                    style: TextStyle(color: textColor),
                  ),
                  subtitle: Text(
                    'People can comment',
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                  value: _allowComments,
                  activeColor: const Color(0xFF4A6CF7),
                  onChanged: (value) {
                    setState(() {
                      _allowComments = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: Text(
                    'Post to Feed',
                    style: TextStyle(color: textColor),
                  ),
                  subtitle: Text(
                    'Share to your main feed',
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                  value: _postToFeed,
                  activeColor: const Color(0xFF4A6CF7),
                  onChanged: (value) {
                    setState(() {
                      _postToFeed = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    String title,
    String value,
    IconData icon,
    Color textColor,
    Color subtitleColor,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4A6CF7)),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: Text(
        value,
        style: TextStyle(color: subtitleColor, fontSize: 13),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: subtitleColor),
      onTap: onTap,
    );
  }
}
