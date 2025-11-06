import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/story_model.dart';

/// Controller for managing story viewing state and playback
class StoryViewController extends ChangeNotifier {
  StoryViewController({
    required this.stories,
    required this.initialStoryIndex,
    required this.currentUserId,
  }) : _currentStoryIndex = initialStoryIndex,
       _currentSegmentIndex = 0;

  final List<StoryItem> stories;
  final int initialStoryIndex;
  final String currentUserId;

  int _currentStoryIndex;
  int _currentSegmentIndex;
  VideoPlayerController? _videoController;
  bool _isPaused = false;
  bool _isLoading = false;

  int get currentStoryIndex => _currentStoryIndex;
  int get currentSegmentIndex => _currentSegmentIndex;
  bool get isPaused => _isPaused;
  bool get isLoading => _isLoading;

  StoryItem get currentStory => stories[_currentStoryIndex];
  StorySegment get currentSegment =>
      currentStory.segments[_currentSegmentIndex];
  bool get isOwnStory => currentStory.userId == currentUserId;

  VideoPlayerController? get videoController => _videoController;

  /// Initialize the first story
  Future<void> initialize() async {
    await _loadSegment();
  }

  /// Load the current segment (image or video)
  Future<void> _loadSegment() async {
    _isLoading = true;
    notifyListeners();

    // Dispose previous video controller
    await _videoController?.dispose();
    _videoController = null;

    final segment = currentSegment;

    if (segment.mediaType == StoryMediaType.video) {
      try {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(segment.mediaUrl),
        );
        await _videoController!.initialize();
        _videoController!.setLooping(false);

        if (!_isPaused) {
          await _videoController!.play();
        }
      } catch (e) {
        debugPrint('❌ Error loading video: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Move to next segment or story
  Future<void> next() async {
    // If there are more segments in current story
    if (_currentSegmentIndex < currentStory.segments.length - 1) {
      _currentSegmentIndex++;
      await _loadSegment();
      notifyListeners();
      return;
    }

    // If there are more stories
    if (_currentStoryIndex < stories.length - 1) {
      _currentStoryIndex++;
      _currentSegmentIndex = 0;
      await _loadSegment();
      notifyListeners();
      return;
    }

    // No more stories - signal to close
    // This will be handled by the UI
  }

  /// Move to previous segment or story
  Future<void> previous() async {
    // If not at first segment, go to previous segment
    if (_currentSegmentIndex > 0) {
      _currentSegmentIndex--;
      await _loadSegment();
      notifyListeners();
      return;
    }

    // If not at first story, go to previous story's last segment
    if (_currentStoryIndex > 0) {
      _currentStoryIndex--;
      _currentSegmentIndex = currentStory.segments.length - 1;
      await _loadSegment();
      notifyListeners();
      return;
    }

    // Already at first segment of first story - do nothing
  }

  /// Pause story playback
  void pause() {
    _isPaused = true;
    _videoController?.pause();
    notifyListeners();
  }

  /// Resume story playback
  void resume() {
    _isPaused = false;
    _videoController?.play();
    notifyListeners();
  }

  /// Toggle pause/resume
  void togglePause() {
    if (_isPaused) {
      resume();
    } else {
      pause();
    }
  }

  /// Jump to a specific story and segment
  Future<void> jumpTo(int storyIndex, int segmentIndex) async {
    if (storyIndex < 0 ||
        storyIndex >= stories.length ||
        segmentIndex < 0 ||
        segmentIndex >= stories[storyIndex].segments.length) {
      return;
    }

    _currentStoryIndex = storyIndex;
    _currentSegmentIndex = segmentIndex;
    await _loadSegment();
    notifyListeners();
  }

  /// Check if this is the last segment of the last story
  bool get isLastSegment {
    return _currentStoryIndex == stories.length - 1 &&
        _currentSegmentIndex == currentStory.segments.length - 1;
  }

  /// Check if this is the first segment of the first story
  bool get isFirstSegment {
    return _currentStoryIndex == 0 && _currentSegmentIndex == 0;
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}
