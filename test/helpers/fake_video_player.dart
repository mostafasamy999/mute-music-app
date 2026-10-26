import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// A fake [VideoPlayerPlatform] for widget tests. It opens any path except ones containing "missing", and can
/// hold back a path containing "slow" until [releaseSlow] is called.
class FakeVideoPlayer extends VideoPlayerPlatform {
  final Map<int, StreamController<VideoEvent>> _events =
      <int, StreamController<VideoEvent>>{};
  final Map<int, String> pathOf = <int, String>{};
  final List<int> disposed = <int>[];
  final List<int> played = <int>[];
  final List<Duration> seeks = <Duration>[];
  final List<int> _held = <int>[];
  int _nextId = 0;

  /// Sends the held "initialized" events. Done here, not with a Future the
  /// fake awaits, so it runs inside the test's fake async zone.
  void releaseSlow() => _held.forEach(_initialized);

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final int id = _nextId++;
    final String path = options.dataSource.uri ?? '';
    pathOf[id] = path;
    _events[id] = StreamController<VideoEvent>(
      onListen: () => _answer(id, path),
    );
    return id;
  }

  void _answer(int id, String path) {
    if (path.contains('missing')) {
      _events[id]!.addError(
        PlatformException(code: 'VideoError', message: 'No such file'),
      );
      return;
    }
    if (path.contains('slow')) {
      _held.add(id);
      return;
    }
    _initialized(id);
  }

  void _initialized(int id) {
    _events[id]!.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 5),
        size: const Size(320, 240),
      ),
    );
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events[playerId]!.stream;

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      SizedBox(key: ValueKey<String>('player:${pathOf[options.playerId]}'));

  @override
  Future<void> dispose(int playerId) async => disposed.add(playerId);

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async => played.add(playerId);

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async =>
      seeks.add(position);

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
}
