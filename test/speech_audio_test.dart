import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mute_music_app/src/data/local/speech_audio.dart';

/// Spec 006 S14: what Whisper reads, mono float32 at 16 kHz.
void main() {
  Uint8List interleaved(List<double> samples) {
    final ByteData data = ByteData(samples.length * 4);
    for (int i = 0; i < samples.length; i++) {
      data.setFloat32(i * 4, samples[i], Endian.little);
    }
    return data.buffer.asUint8List();
  }

  test('stereo is averaged into mono', () {
    final Float32List mono = SpeechAudio.convert(
      interleaved(<double>[1, 0, 0.5, 0.5, -1, 1]),
      sampleRate: 16000,
      channels: 2,
    );
    expect(mono, <double>[0.5, 0.5, 0]);
  });

  test('44.1 kHz becomes 16 kHz with the same length in time', () {
    final Float32List out = SpeechAudio.convert(
      interleaved(List<double>.filled(44100, 0.25)),
      sampleRate: 44100,
      channels: 1,
    );
    expect(out.length, 16000);
    expect(out.every((double v) => (v - 0.25).abs() < 1e-6), isTrue);
  });

  test('a ramp stays a ramp after resampling (linear interpolation)', () {
    final Float32List out = SpeechAudio.convert(
      interleaved(<double>[0, 1, 2, 3, 4, 5, 6, 7]),
      sampleRate: 32000,
      channels: 1,
    );
    expect(out, <double>[0, 2, 4, 6]);
  });

  test('a half float at the end is ignored, empty input is empty', () {
    expect(
      SpeechAudio.convert(
        Uint8List.fromList(<int>[
          ...interleaved(<double>[0.5]),
          1,
          2,
        ]),
        sampleRate: 16000,
        channels: 1,
      ),
      <double>[0.5],
    );
    expect(
      SpeechAudio.convert(Uint8List(0), sampleRate: 44100, channels: 2),
      isEmpty,
    );
  });
}
