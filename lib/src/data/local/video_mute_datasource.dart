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
  }) => _rangeCall('cutVideo', sourcePath, startMs: startMs, endMs: endMs);

  /// Copies [startMs]–[endMs] of a sound file into a new .m4a (spec 006 F3).
  /// Returns the new path and the range it really covers. Throws
  /// [PlatformException].
  Future<({String path, int startMs, int endMs})> cutAudio(
    String sourcePath, {
    required int startMs,
    required int endMs,
  }) => _rangeCall('cutAudio', sourcePath, startMs: startMs, endMs: endMs);

  Future<({String path, int startMs, int endMs})> _rangeCall(
    String method,
    String sourcePath, {
    required int startMs,
    required int endMs,
  }) async {
    final Map<Object?, Object?>? output = await _channel
        .invokeMapMethod<Object?, Object?>(method, <String, Object>{
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

  /// Writes the audio track of a video into a new .m4a (spec 006 F7). Returns
  /// its path. Throws [PlatformException].
  Future<String> exportAudio(String sourcePath) async {
    final String? output = await _channel.invokeMethod<String>(
      'exportAudio',
      <String, String>{'sourcePath': sourcePath},
    );
    if (output == null || output.isEmpty) {
      throw PlatformException(code: 'convert_failed');
    }
    return output;
  }

  /// Copies a sound file to the phone's music storage as [name] (spec 006
  /// F10): Music/Mute Video on Android, Files › Mute Video on iOS. Throws
  /// [PlatformException].
  Future<void> saveAudio(String sourcePath, {required String name}) =>
      _channel.invokeMethod<void>('saveAudio', <String, String>{
        'sourcePath': sourcePath,
        'name': name,
      });

  /// Text in an image, read offline in Arabic and English (spec 006 F8).
  /// Tesseract on Android, Apple Vision on iOS. Throws [PlatformException].
  Future<String> recognizeText(String imagePath) async =>
      await _channel.invokeMethod<String>('recognizeText', <String, String>{
        'imagePath': imagePath,
      }) ??
      '';

  /// Encodes separated voices (interleaved float32 PCM) into a new .m4a, for
  /// Remove music on a sound file (spec 006 F6). Throws [PlatformException].
  Future<String> encodeVoices(
    String pcmPath, {
    required int sampleRate,
    required int channels,
  }) async {
    final String? output = await _channel.invokeMethod<String>(
      'encodeVoices',
      <String, Object>{
        'pcmPath': pcmPath,
        'sampleRate': sampleRate,
        'channels': channels,
      },
    );
    if (output == null || output.isEmpty) {
      throw PlatformException(code: 'encode_failed');
    }
    return output;
  }

  /// The video's length in milliseconds, or null when it can't be read.
  Future<int?> durationMs(String sourcePath) => _channel.invokeMethod<int>(
    'videoDuration',
    <String, String>{'sourcePath': sourcePath},
  );
}
