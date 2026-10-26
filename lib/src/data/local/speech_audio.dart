import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

/// Turns the platform's extracted audio (interleaved float32, any rate and
/// channel count) into what Whisper reads: mono float32 at 16 kHz
/// (spec 006 S14). Runs in a background isolate, so the UI never stalls on a
/// long file.
abstract final class SpeechAudio {
  static const int whisperRate = 16000;

  static Future<Float32List> load(
    String pcmPath, {
    required int sampleRate,
    required int channels,
  }) => Isolate.run(
    () => convert(
      File(pcmPath).readAsBytesSync(),
      sampleRate: sampleRate,
      channels: channels,
    ),
  );

  /// Pure, for tests: downmix by averaging the channels, then resample
  /// linearly. Linear is enough for speech, which Whisper hears at 16 kHz
  /// anyway.
  static Float32List convert(
    Uint8List bytes, {
    required int sampleRate,
    required int channels,
  }) {
    final int floats = bytes.lengthInBytes ~/ 4;
    final ByteData data = ByteData.sublistView(bytes, 0, floats * 4);
    final int frames = floats ~/ channels;
    final Float32List mono = Float32List(frames);
    for (int frame = 0; frame < frames; frame++) {
      double sum = 0;
      for (int channel = 0; channel < channels; channel++) {
        sum += data.getFloat32((frame * channels + channel) * 4, Endian.little);
      }
      mono[frame] = sum / channels;
    }
    if (sampleRate == whisperRate || frames == 0) return mono;

    final int outFrames = (frames * whisperRate / sampleRate).floor();
    final Float32List out = Float32List(outFrames);
    final double step = sampleRate / whisperRate;
    for (int i = 0; i < outFrames; i++) {
      final double at = i * step;
      final int left = at.floor();
      final int right = left + 1 < frames ? left + 1 : left;
      final double weight = at - left;
      out[i] = mono[left] * (1 - weight) + mono[right] * weight;
    }
    return out;
  }
}
