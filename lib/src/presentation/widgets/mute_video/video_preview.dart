import 'package:flutter/material.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/player_host.dart';
import 'package:video_player/video_player.dart';

/// Plays a local video, looping. Tap to play or pause.
class VideoPreview extends StatelessWidget {
  const VideoPreview({required this.path, super.key});

  final String path;

  @override
  Widget build(BuildContext context) =>
      PlayerHost(path: path, looping: true, builder: _player);

  Widget _player(VideoPlayerController controller) => ClipRRect(
    borderRadius: BorderRadius.circular(AppSpacing.radius),
    child: AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: GestureDetector(
        onTap: () => _toggle(controller),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[VideoPlayer(controller), _playIcon(controller)],
        ),
      ),
    ),
  );

  Widget _playIcon(VideoPlayerController controller) =>
      ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (_, VideoPlayerValue value, _) => value.isPlaying
            ? const SizedBox.shrink()
            : const Icon(Icons.play_circle, size: 56, color: Colors.white70),
      );

  void _toggle(VideoPlayerController controller) =>
      controller.value.isPlaying ? controller.pause() : controller.play();
}
