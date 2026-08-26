import 'package:flutter/services.dart';
import 'package:mute_music_app/src/core/extensions/string_extensions.dart';

/// Talks to the native remuxer. The platform copies the video track into a new
/// file and drops the audio track, so nothing is re-encoded.
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
}
