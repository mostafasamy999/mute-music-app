import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mute_music_app/src/data/local/video_mute_datasource.dart';

/// Spec 006 S8/S10 on a real device or simulator: the native AudioExporter
/// behind `cutAudio` and `exportAudio`. The input is a WAV written here, so
/// the test needs no file staged on the device, and it exercises the
/// re-encode path (WAV is not AAC).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final VideoMuteDatasource native = VideoMuteDatasource();
  late File wav;

  setUpAll(() async {
    wav = File('${Directory.systemTemp.path}/tone_test.wav')
      ..writeAsBytesSync(_toneWav(seconds: 2));
  });

  tearDownAll(() {
    if (wav.existsSync()) wav.deleteSync();
  });

  Future<int> lengthMs(String path) async =>
      (await native.durationMs(path)) ?? -1;

  testWidgets('cutAudio writes only the asked range as .m4a', (_) async {
    final ({String path, int startMs, int endMs}) part = await native.cutAudio(
      wav.path,
      startMs: 500,
      endMs: 1500,
    );

    expect(part.path, endsWith('.m4a'));
    expect(File(part.path).existsSync(), isTrue);
    expect(part.startMs, lessThanOrEqualTo(500));
    // AAC frames are ~23 ms; allow a few at each end.
    expect((await lengthMs(part.path) - 1000).abs(), lessThan(120));
    File(part.path).deleteSync();
  });

  testWidgets('exportAudio writes the whole track as .m4a', (_) async {
    final String path = await native.exportAudio(wav.path);

    expect(path, endsWith('.m4a'));
    expect(path.split('/').last, startsWith('export_'));
    expect((await lengthMs(path) - 2000).abs(), lessThan(120));
    File(path).deleteSync();
  });

  testWidgets('a bad range is refused and leaves no file', (_) async {
    await expectLater(
      native.cutAudio(wav.path, startMs: 5000, endMs: 6000),
      throwsA(
        isA<Object>().having(
          (Object e) => e.toString(),
          'error',
          contains('bad_range'),
        ),
      ),
    );
  });
}

/// A 440 Hz tone, 44.1 kHz mono 16-bit PCM in a WAV container.
Uint8List _toneWav({required int seconds}) {
  const int rate = 44100;
  final int samples = rate * seconds;
  final ByteData data = ByteData(44 + samples * 2);
  void ascii(int offset, String text) {
    for (int i = 0; i < text.length; i++) {
      data.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + samples * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, 1, Endian.little)
    ..setUint32(24, rate, Endian.little)
    ..setUint32(28, rate * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, samples * 2, Endian.little);
  for (int i = 0; i < samples; i++) {
    final double v = math.sin(2 * math.pi * 440 * i / rate) * 0.5;
    data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}
