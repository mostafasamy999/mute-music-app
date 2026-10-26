import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/preview_unavailable.dart';
import 'package:video_player/video_player.dart';

/// Opens [path] in a player and hands the ready controller to [builder].
/// Shared by the video and the audio preview: `video_player` plays sound files
/// too. Uses a ValueNotifier instead of setState, so it follows the
/// no-setState rule while still owning the controller.
class PlayerHost extends StatefulWidget {
  const PlayerHost({
    required this.path,
    required this.builder,
    this.looping = false,
    this.startAt = Duration.zero,
    super.key,
  });

  final String path;
  final bool looping;

  /// Where playback starts, when the file is that long (spec 006 Q3).
  final Duration startAt;
  final Widget Function(VideoPlayerController controller) builder;

  @override
  State<PlayerHost> createState() => _PlayerHostState();
}

/// Where loading the current path stands.
sealed class _Load {
  const _Load();
}

class _Loading extends _Load {
  const _Loading();
}

class _Ready extends _Load {
  const _Ready(this.controller);

  final VideoPlayerController controller;
}

/// The file is missing or the player can't open it (spec 006 W11).
class _Failed extends _Load {
  const _Failed();
}

class _PlayerHostState extends State<PlayerHost> {
  final ValueNotifier<_Load> _load = ValueNotifier<_Load>(const _Loading());

  @override
  void initState() {
    super.initState();
    _open(widget.path);
  }

  @override
  void didUpdateWidget(covariant PlayerHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _open(widget.path);
  }

  @override
  void dispose() {
    _controllerOf(_load.value)?.dispose();
    _load.dispose();
    super.dispose();
  }

  Future<void> _open(String path) async {
    final VideoPlayerController? previous = _controllerOf(_load.value);
    _load.value = const _Loading();
    await previous?.dispose();
    final VideoPlayerController next = VideoPlayerController.file(File(path));
    try {
      await next.initialize();
      await next.setLooping(widget.looping);
      final Duration startAt = widget.startAt;
      if (startAt > Duration.zero && startAt < next.value.duration) {
        await next.seekTo(startAt);
      }
    } on Object {
      // Not awaited: when creating the player itself failed, dispose waits
      // forever for a creation that never completes.
      unawaited(next.dispose());
      if (_isCurrent(path)) _load.value = const _Failed();
      return;
    }
    // A newer path may have been asked for while this one was loading.
    if (!_isCurrent(path)) return next.dispose();
    _load.value = _Ready(next);
  }

  bool _isCurrent(String path) => mounted && widget.path == path;

  VideoPlayerController? _controllerOf(_Load load) => switch (load) {
    _Ready(:final VideoPlayerController controller) => controller,
    _ => null,
  };

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<_Load>(
    valueListenable: _load,
    builder: (BuildContext context, _Load load, _) => switch (load) {
      _Loading() => const Center(child: CircularProgressIndicator()),
      _Ready(:final VideoPlayerController controller) => widget.builder(
        controller,
      ),
      _Failed() => const PreviewUnavailable(),
    },
  );
}
