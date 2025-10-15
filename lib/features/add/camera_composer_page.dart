import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CameraComposerPage extends StatefulWidget {
  final String type; // 'story', 'reel', or 'post'

  const CameraComposerPage({super.key, this.type = 'story'});

  @override
  State<CameraComposerPage> createState() => _CameraComposerPageState();
}

class _CameraComposerPageState extends State<CameraComposerPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _capturedMedia;
  bool _isVideo = false;
  bool _isProcessing = false;

  // Camera/Video settings
  bool _isFlashOn = false;
  String _selectedFilter = 'None';
  String? _selectedMusic;
  final double _videoSpeed = 1.0;
  final int _timerSeconds = 0;

  // AR Effects
  String? _selectedAREffect;
  final List<Map<String, dynamic>> _arEffects = [
    {'id': 'none', 'name': 'None', 'icon': Icons.block},
    {'id': 'beauty', 'name': 'Beauty', 'icon': Icons.face_retouching_natural},
    {'id': 'vintage', 'name': 'Vintage', 'icon': Icons.camera},
    {'id': 'cartoon', 'name': 'Cartoon', 'icon': Icons.emoji_emotions},
    {'id': 'neon', 'name': 'Neon', 'icon': Icons.lightbulb},
    {'id': 'blur', 'name': 'Blur BG', 'icon': Icons.blur_on},
  ];

  // Music library
  final List<Map<String, String>> _musicTracks = [
    {'id': '1', 'name': 'Summer Vibes', 'artist': 'DJ Cool'},
    {'id': '2', 'name': 'Night Drive', 'artist': 'Synthwave'},
    {'id': '3', 'name': 'Happy Beat', 'artist': 'Pop Star'},
    {'id': '4', 'name': 'Chill Out', 'artist': 'Lofi Beats'},
    {'id': '5', 'name': 'Party Time', 'artist': 'Dance Mix'},
  ];

  // Filters
  final List<String> _filters = [
    'None',
    'Bright',
    'Warm',
    'Cool',
    'Vintage',
    'B&W',
    'Sepia',
    'Vivid',
    'Fade',
  ];

  // Stickers and text overlays
  final List<Map<String, dynamic>> _overlays = [];

  AnimationController? _timerController;
  int _countdown = 0;

  // Theme helper methods
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

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    _timerController?.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_timerSeconds > 0) {
      await _startCountdown();
    }

    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _capturedMedia = photo;
          _isVideo = false;
        });
      }
    } catch (e) {
      _showSnackBar('Error capturing photo: $e', Colors.red);
    }
  }

  Future<void> _captureVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 60),
      );
      if (video != null) {
        setState(() {
          _capturedMedia = video;
          _isVideo = true;
        });
      }
    } catch (e) {
      _showSnackBar('Error capturing video: $e', Colors.red);
    }
  }

  Future<void> _startCountdown() async {
    for (int i = _timerSeconds; i > 0; i--) {
      setState(() {
        _countdown = i;
      });
      await Future.delayed(const Duration(seconds: 1));
    }
    setState(() {
      _countdown = 0;
    });
  }

  Future<void> _pickFromGallery() async {
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Select Media',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo, color: Colors.white),
                title: const Text(
                  'Photo',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, 'photo'),
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.white),
                title: const Text(
                  'Video',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, 'video'),
              ),
            ],
          ),
        ),
      );

      if (result == 'photo') {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.gallery,
        );
        if (photo != null) {
          setState(() {
            _capturedMedia = photo;
            _isVideo = false;
          });
        }
      } else if (result == 'video') {
        final XFile? video = await _picker.pickVideo(
          source: ImageSource.gallery,
        );
        if (video != null) {
          setState(() {
            _capturedMedia = video;
            _isVideo = true;
          });
        }
      }
    } catch (e) {
      _showSnackBar('Error picking media: $e', Colors.red);
    }
  }

  void _showMusicPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        decoration: BoxDecoration(
          color: _getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
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
            const SizedBox(height: 16),
            Text(
              'Choose Music',
              style: TextStyle(
                color: _getTextColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _musicTracks.length,
                itemBuilder: (context, index) {
                  final track = _musicTracks[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.music_note,
                      color: Color(0xFF4A6CF7),
                    ),
                    title: Text(
                      track['name']!,
                      style: TextStyle(color: _getTextColor(context)),
                    ),
                    subtitle: Text(
                      track['artist']!,
                      style: TextStyle(color: _getSubtitleColor(context)),
                    ),
                    trailing: _selectedMusic == track['id']
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedMusic = track['id']!;
                      });
                      Navigator.pop(context);
                      _showSnackBar(
                        'Music added: ${track['name']}',
                        Colors.green,
                      );
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

  void _showAREffects() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 200,
        decoration: BoxDecoration(
          color: _getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
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
            const SizedBox(height: 16),
            Text(
              'AR Effects',
              style: TextStyle(
                color: _getTextColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _arEffects.length,
                itemBuilder: (context, index) {
                  final effect = _arEffects[index];
                  final isSelected = _selectedAREffect == effect['id'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAREffect = effect['id'];
                      });
                      Navigator.pop(context);
                      _showSnackBar(
                        'Effect applied: ${effect['name']}',
                        Colors.green,
                      );
                    },
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF4A6CF7)
                            : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(effect['icon'], color: Colors.white, size: 32),
                          const SizedBox(height: 4),
                          Text(
                            effect['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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

  void _showTextOverlay() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController textController = TextEditingController();
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Add Text', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: textController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter text...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  setState(() {
                    _overlays.add({
                      'type': 'text',
                      'content': textController.text,
                    });
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showStickerPicker() {
    final stickers = [
      '😀',
      '😂',
      '😍',
      '🔥',
      '❤️',
      '👍',
      '🎉',
      '✨',
      '🌟',
      '💯',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 200,
        decoration: BoxDecoration(
          color: _getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
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
            const SizedBox(height: 16),
            Text(
              'Add Sticker',
              style: TextStyle(
                color: _getTextColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: stickers.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _overlays.add({
                          'type': 'sticker',
                          'content': stickers[index],
                        });
                      });
                      Navigator.pop(context);
                      _showSnackBar('Sticker added!', Colors.green);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
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

  Future<void> _publishContent() async {
    if (_capturedMedia == null) {
      _showSnackBar('Please capture or select media first', Colors.orange);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));

      final contentData = {
        'type': widget.type,
        'media': _capturedMedia!.path,
        'isVideo': _isVideo,
        'caption': _captionController.text,
        'filter': _selectedFilter,
        'music': _selectedMusic,
        'arEffect': _selectedAREffect,
        'overlays': _overlays,
        'videoSpeed': _videoSpeed,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // TODO: Upload to server with transcoding
      print('Content published: $contentData');

      setState(() {
        _isProcessing = false;
      });

      _showSnackBar('${widget.type.toUpperCase()} published!', Colors.green);

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showSnackBar('Error publishing: $e', Colors.red);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview or captured media
          if (_capturedMedia == null)
            _buildCameraControls()
          else
            _buildPreview(),

          // Countdown overlay
          if (_countdown > 0)
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$_countdown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraControls() {
    return Column(
      children: [
        // Top controls
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isFlashOn = !_isFlashOn;
                    });
                  },
                  icon: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: _showAREffects,
                  icon: const Icon(
                    Icons.face_retouching_natural,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: _showMusicPicker,
                  icon: const Icon(Icons.music_note, color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        // Bottom controls
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Filters
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Capture buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _pickFromGallery,
                    icon: const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  GestureDetector(
                    onTap: _capturePhoto,
                    onLongPress: _captureVideo,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: const Center(
                        child: Icon(Icons.circle, color: Colors.red, size: 50),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Switch camera
                      _showSnackBar('Camera switched', Colors.blue);
                    },
                    icon: const Icon(
                      Icons.cameraswitch,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Tap for photo, Hold for video',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        // Top bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _capturedMedia = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _showTextOverlay,
                  icon: const Icon(Icons.text_fields, color: Colors.white),
                ),
                IconButton(
                  onPressed: _showStickerPicker,
                  icon: const Icon(Icons.emoji_emotions, color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        // Media preview
        Expanded(
          child: Stack(
            children: [
              Center(
                child: Image.file(
                  File(_capturedMedia!.path),
                  fit: BoxFit.contain,
                ),
              ),
              // Overlays
              ...List.generate(_overlays.length, (index) {
                final overlay = _overlays[index];
                return Positioned(
                  top: 100.0 + (index * 50),
                  left: 50.0 + (index * 20),
                  child: Draggable(
                    feedback: Material(
                      color: Colors.transparent,
                      child: Text(
                        overlay['content'],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: overlay['type'] == 'sticker' ? 40 : 24,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                    childWhenDragging: Container(),
                    onDragEnd: (details) {
                      // Update position
                    },
                    child: Text(
                      overlay['content'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: overlay['type'] == 'sticker' ? 40 : 24,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // Caption and publish
        Container(
          color: Colors.grey[900],
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _captionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Add a caption...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _publishContent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Publish ${widget.type.toUpperCase()}'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
