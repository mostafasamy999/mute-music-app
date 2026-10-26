import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:video_player/video_player.dart';

/// The original video on the Choose a part screen. The screen owns the
/// controller, because the slider seeks it and the range limits playback.
class PartPreview extends StatelessWidget {
  const PartPreview({
    required this.controller,
    required this.failed,
    required this.onTap,
    this.isAudio = false,
    super.key,
  });

  /// Null while the video loads.
  final VideoPlayerController? controller;
  final ValueListenable<bool> failed;
  final VoidCallback onTap;

  /// A sound has no picture: show a sound mark with the play state instead.
  final bool isAudio;

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? player = controller;
    if (player != null) {
      return Center(child: isAudio ? _sound(context, player) : _player(player));
    }
    return ValueListenableBuilder<bool>(
      valueListenable: failed,
      builder: (BuildContext context, bool failed, _) => Center(
        child: failed
            ? Text(S.of(context).errorPickFailed, textAlign: TextAlign.center)
            : const CircularProgressIndicator(),
      ),
    );
  }

  Widget _sound(BuildContext context, VideoPlayerController player) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.graphic_eq, size: 96, color: scheme.primary),
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: player,
            builder: (_, VideoPlayerValue value, _) => Icon(
              value.isPlaying ? Icons.pause_circle : Icons.play_circle,
              size: 56,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _player(VideoPlayerController player) => ClipRRect(
    borderRadius: BorderRadius.circular(AppSpacing.radius),
    child: AspectRatio(
      aspectRatio: player.value.aspectRatio,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            VideoPlayer(player),
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: player,
              builder: (_, VideoPlayerValue value, _) => value.isPlaying
                  ? const SizedBox.shrink()
                  : const Icon(
                      Icons.play_circle,
                      size: 56,
                      color: Colors.white70,
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
