import 'package:flutter/material.dart';
import 'dart:async';

/// Animated progress bars for story segments
class StoryProgressBars extends StatefulWidget {
  const StoryProgressBars({
    super.key,
    required this.segmentCount,
    required this.currentIndex,
    required this.duration,
    required this.isPaused,
    required this.onSegmentComplete,
    this.videoDuration,
    this.videoPosition,
  });

  final int segmentCount;
  final int currentIndex;
  final Duration duration;
  final bool isPaused;
  final VoidCallback onSegmentComplete;
  final Duration? videoDuration;
  final Duration? videoPosition;

  @override
  State<StoryProgressBars> createState() => _StoryProgressBarsState();
}

class _StoryProgressBarsState extends State<StoryProgressBars>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Timer? _videoProgressTimer;

  @override
  void initState() {
    super.initState();
    _initializeProgress();
  }

  @override
  void didUpdateWidget(StoryProgressBars oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset progress when segment changes
    if (oldWidget.currentIndex != widget.currentIndex) {
      _initializeProgress();
    }

    // Handle pause/resume
    if (oldWidget.isPaused != widget.isPaused) {
      if (widget.isPaused) {
        _animationController?.stop();
        _videoProgressTimer?.cancel();
      } else {
        _animationController?.forward();
        if (widget.videoDuration != null) {
          _startVideoProgressTracking();
        }
      }
    }

    // Update video progress tracking
    if (widget.videoDuration != null &&
        widget.videoDuration != oldWidget.videoDuration) {
      _startVideoProgressTracking();
    }
  }

  void _initializeProgress() {
    _animationController?.dispose();
    _videoProgressTimer?.cancel();

    if (widget.videoDuration != null) {
      // For videos, track actual video progress
      _startVideoProgressTracking();
    } else {
      // For images, use fixed duration animation
      _animationController = AnimationController(
        vsync: this,
        duration: widget.duration,
      );

      _animationController!.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onSegmentComplete();
        }
      });

      if (!widget.isPaused) {
        _animationController!.forward();
      }
    }
  }

  void _startVideoProgressTracking() {
    _videoProgressTimer?.cancel();

    if (widget.videoDuration == null) return;

    // Update progress every 50ms based on video position
    _videoProgressTimer = Timer.periodic(const Duration(milliseconds: 50), (
      timer,
    ) {
      if (widget.videoPosition != null && widget.videoDuration != null) {
        final progress =
            widget.videoPosition!.inMilliseconds /
            widget.videoDuration!.inMilliseconds;

        setState(() {}); // Trigger rebuild to update progress

        // Check if video is complete
        if (progress >= 0.99) {
          timer.cancel();
          widget.onSegmentComplete();
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _videoProgressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: List.generate(
          widget.segmentCount,
          (index) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: _buildProgressIndicator(index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int index) {
    if (index < widget.currentIndex) {
      // Completed segments
      return Container(color: Colors.white);
    } else if (index == widget.currentIndex) {
      // Current segment with animated progress
      if (widget.videoDuration != null) {
        // Video progress
        final progress =
            widget.videoPosition != null && widget.videoDuration != null
            ? (widget.videoPosition!.inMilliseconds /
                      widget.videoDuration!.inMilliseconds)
                  .clamp(0.0, 1.0)
            : 0.0;

        return FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress,
          child: Container(color: Colors.white),
        );
      } else {
        // Image progress with animation
        return AnimatedBuilder(
          animation: _animationController!,
          builder: (context, child) {
            return FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _animationController!.value,
              child: Container(color: Colors.white),
            );
          },
        );
      }
    } else {
      // Upcoming segments (empty)
      return const SizedBox.shrink();
    }
  }
}
