import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/widgets/professional_camera_view.dart';
import '../../core/services/video_crop_service.dart';
import '../../core/services/image_crop_service.dart';

/// Example integration of professional camera in create post flow
class CameraIntegrationExample extends StatefulWidget {
  const CameraIntegrationExample({super.key});

  @override
  State<CameraIntegrationExample> createState() =>
      _CameraIntegrationExampleState();
}

class _CameraIntegrationExampleState extends State<CameraIntegrationExample> {
  File? _capturedFile;
  bool _isVideo = false;
  bool _isProcessing = false;

  Future<void> _openCameraForPost() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ProfessionalCameraView(
          initialMode: CameraAspectMode.square,
          showModeSelector: true,
          maxVideoDuration: const Duration(seconds: 60),
          onMediaCaptured: (path, thumbnailPath, isVideo) {
            Navigator.pop(context, {
              'path': path,
              'thumbnailPath': thumbnailPath,
              'isVideo': isVideo,
            });
          },
        ),
      ),
    );

    if (result != null) {
      await _processCapture(
        File(result['path']),
        result['thumbnailPath'],
        result['isVideo'],
        CameraAspectMode.square,
      );
    }
  }

  Future<void> _openCameraForReel() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ProfessionalCameraView(
          initialMode: CameraAspectMode.fullScreen,
          showModeSelector: false,
          maxVideoDuration: const Duration(seconds: 90),
          onMediaCaptured: (path, thumbnailPath, isVideo) {
            Navigator.pop(context, {
              'path': path,
              'thumbnailPath': thumbnailPath,
              'isVideo': isVideo,
            });
          },
        ),
      ),
    );

    if (result != null) {
      await _processCapture(
        File(result['path']),
        result['thumbnailPath'],
        result['isVideo'],
        CameraAspectMode.fullScreen,
      );
    }
  }

  Future<void> _processCapture(
    File file,
    String? thumbnailPath,
    bool isVideo,
    CameraAspectMode mode,
  ) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      File? processedFile;

      if (isVideo) {
        // Process video
        switch (mode) {
          case CameraAspectMode.square:
            processedFile = await VideoCropService().cropForPost(file);
            break;
          case CameraAspectMode.portrait:
            processedFile = await VideoCropService().cropForFeed(file);
            break;
          case CameraAspectMode.fullScreen:
            processedFile = await VideoCropService().cropForReel(file);
            break;
        }
      } else {
        // Process image
        switch (mode) {
          case CameraAspectMode.square:
            processedFile = await ImageCropService().cropForPost(file);
            break;
          case CameraAspectMode.portrait:
            processedFile = await ImageCropService().cropForFeed(file);
            break;
          case CameraAspectMode.fullScreen:
            processedFile = await ImageCropService().cropForReel(file);
            break;
        }
      }

      if (processedFile != null) {
        setState(() {
          _capturedFile = processedFile;
          _isVideo = isVideo;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isVideo ? 'Video ready to post!' : 'Photo ready to post!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing media: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Integration Example')),
      body: Center(
        child: _isProcessing
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing media...'),
                ],
              )
            : _capturedFile != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Preview
                  if (_isVideo)
                    Container(
                      width: 300,
                      height: 300,
                      color: Colors.black,
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Image.file(
                      _capturedFile!,
                      width: 300,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    _isVideo ? 'Video captured!' : 'Photo captured!',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _capturedFile = null;
                      });
                    },
                    child: const Text('Capture Again'),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _openCameraForPost,
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Open Camera for Post (1:1)'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _openCameraForReel,
                    icon: const Icon(Icons.video_camera_back),
                    label: const Text('Open Camera for Reel (9:16)'),
                  ),
                ],
              ),
      ),
    );
  }
}
