import 'package:flutter/services.dart';
import 'package:mute_music_app/src/core/extensions/string_extensions.dart';

class ExtractedAudio {
  const ExtractedAudio({
    required this.path,
    required this.sampleRate,
    required this.channels,
  });

  final String path;
  final int sampleRate;
  final int channels;
}

/// Pulls audio out of a video and puts new audio back, both on the platform
/// side. The picture is copied, never re-encoded.
class AudioPipelineDatasource {
  static const MethodChannel _channel = MethodChannel(
    'com.mostafasamy.mutemusic/video',
  );

  Future<ExtractedAudio> extract(String videoPath) async {
    final Map<Object?, Object?>? map = await _channel
        .invokeMethod<Map<Object?, Object?>>('extractAudio', <String, String>{
          'sourcePath': videoPath,
        });
    if (map == null) throw PlatformException(code: 'extract_failed');
    return ExtractedAudio(
      path: map['path']! as String,
      sampleRate: map['sampleRate']! as int,
      channels: map['channels']! as int,
    );
  }

  Future<String> mux({
    required String videoPath,
    required String pcmPath,
  }) async {
    final String? output = await _channel
        .invokeMethod<String>('muxAudio', <String, Object>{
          'videoPath': videoPath,
          'pcmPath': pcmPath,
          'sampleRate': 44100,
          'channels': 2,
        });
    if (output.isEmptyOrNull) {
      throw PlatformException(code: 'mux_failed');
    }
    return output!;
  }
}
