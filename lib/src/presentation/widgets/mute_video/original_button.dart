import 'package:flutter/material.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:video_player/video_player.dart';

/// The original icon over an edited file (spec 006 §3.2). Pauses the edited
/// file and hands its position over, so the original opens at the same moment.
class OriginalButton extends StatelessWidget {
  const OriginalButton({
    required this.controller,
    required this.onOriginal,
    super.key,
  });

  final VideoPlayerController controller;
  final ValueChanged<Duration> onOriginal;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: S.of(context).showOriginal,
    icon: const Icon(Icons.history),
    onPressed: () async {
      await controller.pause();
      onOriginal(controller.value.position);
    },
  );
}
