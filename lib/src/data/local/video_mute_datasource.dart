import 'package:flutter/services.dart';
import 'package:mute_music_app/src/core/extensions/string_extensions.dart';

/// Talks to the native remuxer. Nothing it does re-encodes the video: it
/// copies samples into a new file and leaves the rest behind.
class VideoMuteDatasource {
  static const MethodChannel _channel = MethodChannel(
    'com.mostafasamy.mutemusic/video',
  );

  /// Returns the path of the new, silent file. Throws [PlatformException].
  Future<String> removeSound(String sourcePath) async {
    final String? output = await _channel.invokeMethod<String>(
      'removeSound',
      <String, String>{'sourcePath': sourcePath},
    );
    if (output.isEmptyOrNull) {
      throw PlatformException(code: 'mute_failed');
    }
    return output!;
  }

  /// Copies [startMs]–[endMs] of the source into a new file. Returns the new
  /// path and the range it really covers. Throws [PlatformException].
  Future<({String path, int startMs, int endMs})> cutVideo(
    String sourcePath, {
    required int startMs,
    required int endMs,
  }) async {
    final Map<Object?, Object?>? output = await _channel
        .invokeMapMethod<Object?, Object?>('cutVideo', <String, Object>{
          'sourcePath': sourcePath,
          'startMs': startMs,
          'endMs': endMs,
        });
    final Object? path = output?['path'];
    final Object? start = output?['startMs'];
    final Object? end = output?['endMs'];
    if (path is! String || path.isEmpty || start is! int || end is! int) {
      throw PlatformException(code: 'cut_failed');
    }
    return (path: path, startMs: start, endMs: end);
  }

  /// The video's length in milliseconds, or null when it can't be read.
  Future<int?> durationMs(String sourcePath) => _channel.invokeMethod<int>(
    'videoDuration',
    <String, String>{'sourcePath': sourcePath},
  );
}
