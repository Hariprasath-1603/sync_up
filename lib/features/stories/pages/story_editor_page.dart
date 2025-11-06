import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme.dart';
import '../../../core/services/story_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Story Editor Page - Edit and preview story before posting
class StoryEditorPage extends StatefulWidget {
  final File mediaFile;
  final String mediaType; // 'image' or 'video'

  const StoryEditorPage({
    super.key,
    required this.mediaFile,
    required this.mediaType,
  });

  @override
  State<StoryEditorPage> createState() => _StoryEditorPageState();
}

class _StoryEditorPageState extends State<StoryEditorPage> {
  final TextEditingController _captionController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _showControls = true;

  // Text overlay properties
  String _overlayText = '';
  Offset _textPosition = const Offset(0.5, 0.5); // Center position (0-1 range)
  bool _isEditingText = false;

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == 'video') {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.file(widget.mediaFile);
      await _videoController!.initialize();
      setState(() => _isVideoInitialized = true);
      _videoController!.setLooping(true);
      _videoController!.play();
    } catch (e) {
      debugPrint('❌ Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _postStory() async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Step 1: Upload media to Supabase Storage
      setState(() => _uploadProgress = 0.3);

      final supabase = Supabase.instance.client;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = widget.mediaType == 'video' ? 'mp4' : 'jpg';
      final fileName = '${userId}/$timestamp.$extension';

      // Upload to stories bucket
      final bytes = await widget.mediaFile.readAsBytes();
      await supabase.storage
          .from('stories')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get public URL
      final mediaUrl = supabase.storage.from('stories').getPublicUrl(fileName);

      setState(() => _uploadProgress = 0.7);

      // Step 2: Save story metadata to database
      final storyService = StoryService();
      await storyService.uploadStory(
        mediaUrl: mediaUrl,
        mediaType: widget.mediaType,
        caption: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
        mood: null,
      );

      setState(() => _uploadProgress = 1.0);

      // Step 3: Show success and navigate back
      if (mounted) {
        _showSuccessAnimation();
      }
    } catch (e) {
      debugPrint('❌ Error posting story: $e');
      setState(() => _isUploading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post story: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 60),
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story posted successfully! 🎉'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _toggleTextEditor() {
    setState(() {
      _isEditingText = !_isEditingText;
    });

    if (_isEditingText) {
      _showTextInputDialog();
    }
  }

  void _showTextInputDialog() {
    final textController = TextEditingController(text: _overlayText);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Text'),
          content: TextField(
            controller: textController,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Type something...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _isEditingText = false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _overlayText = textController.text;
                  _isEditingText = false;
                });
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Media Preview
          GestureDetector(
            onTap: () => setState(() => _showControls = !_showControls),
            child: widget.mediaType == 'video'
                ? _buildVideoPlayer()
                : _buildImagePreview(),
          ),

          // Text Overlay
          if (_overlayText.isNotEmpty)
            Positioned(
              left: MediaQuery.of(context).size.width * _textPosition.dx - 100,
              top: MediaQuery.of(context).size.height * _textPosition.dy - 20,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _textPosition = Offset(
                      (_textPosition.dx +
                              details.delta.dx /
                                  MediaQuery.of(context).size.width)
                          .clamp(0.0, 1.0),
                      (_textPosition.dy +
                              details.delta.dy /
                                  MediaQuery.of(context).size.height)
                          .clamp(0.0, 1.0),
                    );
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _overlayText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                ),
              ),
            ),

          // Top Controls
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const Spacer(),
                        // Text Tool
                        IconButton(
                          onPressed: _toggleTextEditor,
                          icon: const Icon(
                            Icons.text_fields,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Bottom Controls
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Caption Input
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: TextField(
                            controller: _captionController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Add a caption...',
                              hintStyle: TextStyle(color: Colors.white60),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Post Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isUploading ? null : _postStory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isUploading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Uploading ${(_uploadProgress * 100).toInt()}%',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Post Story',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Upload Progress Overlay
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Image.file(widget.mediaFile, fit: BoxFit.cover);
  }
}
