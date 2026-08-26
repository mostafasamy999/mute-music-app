import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:video_player/video_player.dart';

/// Plays a local file. Uses a ValueNotifier instead of setState, so the widget
/// follows the no-setState rule while still owning the player controller.
class VideoPreview extends StatefulWidget {
  const VideoPreview({required this.path, super.key});

  final String path;

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  final ValueNotifier<VideoPlayerController?> _controller =
      ValueNotifier<VideoPlayerController?>(null);

  @override
  void initState() {
    super.initState();
    _load(widget.path);
  }

  @override
  void didUpdateWidget(covariant VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _load(widget.path);
  }

  @override
  void dispose() {
    _controller.value?.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load(String path) async {
    final VideoPlayerController? previous = _controller.value;
    _controller.value = null;
    await previous?.dispose();
    final VideoPlayerController next = VideoPlayerController.file(File(path));
    await next.initialize();
    await next.setLooping(true);
    if (!mounted) return next.dispose();
    _controller.value = next;
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<VideoPlayerController?>(
        valueListenable: _controller,
        builder: (BuildContext context, VideoPlayerController? controller, _) =>
            controller == null
            ? const Center(child: CircularProgressIndicator())
            : _player(controller),
      );

  Widget _player(VideoPlayerController controller) => ClipRRect(
    borderRadius: BorderRadius.circular(AppSpacing.radius),
    child: AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: GestureDetector(
        onTap: () => _toggle(controller),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            VideoPlayer(controller),
            _playIcon(controller),
          ],
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
