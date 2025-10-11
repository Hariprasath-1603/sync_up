import 'package:flutter/material.dart';

import 'create_reel_modern.dart';

/// Backwards-compatible entry point that forwards to the modern reel flow.
class CreateReelPage extends StatelessWidget {
  final String? preselectedAudioId;
  final bool isRemix;
  final List<ReelSegment> initialSegments;

  const CreateReelPage({
    super.key,
    this.preselectedAudioId,
    this.isRemix = false,
    this.initialSegments = const [],
  });

  @override
  Widget build(BuildContext context) {
    return CreateReelModern(
      preselectedAudioId: preselectedAudioId,
      isRemix: isRemix,
      initialClips: initialSegments,
    );
  }
}
