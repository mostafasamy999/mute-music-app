import 'dart:io';
import 'dart:typed_data';

/// Raw interleaved float32 audio, the format both platforms hand us.
class StereoAudio {
  const StereoAudio(this.left, this.right);

  final Float64List left;
  final Float64List right;

  int get length => left.length;
}

abstract final class PcmIo {
  static const int targetRate = 44100;

  /// Reads interleaved float32, splits the channels, and lands on 44.1 kHz
  /// stereo — the only shape the model accepts.
  static StereoAudio read(File file, int sampleRate, int channels) {
    final Float32List raw = file.readAsBytesSync().buffer.asFloat32List();
    final int frames = raw.length ~/ channels;
    final Float64List left = Float64List(frames);
    final Float64List right = Float64List(frames);
    for (int i = 0; i < frames; i++) {
      left[i] = raw[i * channels];
      right[i] = channels > 1 ? raw[i * channels + 1] : raw[i * channels];
    }
    if (sampleRate == targetRate) return StereoAudio(left, right);
    return StereoAudio(
      _resample(left, sampleRate),
      _resample(right, sampleRate),
    );
  }

  /// Linear interpolation. Chosen over an FFT resampler because that would
  /// need a transform of the whole track, and memory is the tight resource
  /// here. Good enough for speech; slight loss at the very top of the range.
  static Float64List _resample(Float64List input, int sourceRate) {
    if (input.isEmpty) return input;
    final double ratio = targetRate / sourceRate;
    final int outLength = (input.length * ratio).round();
    final Float64List out = Float64List(outLength);
    for (int i = 0; i < outLength; i++) {
      final double position = i / ratio;
      final int index = position.floor();
      final double fraction = position - index;
      final double a = input[index.clamp(0, input.length - 1)];
      final double b = input[(index + 1).clamp(0, input.length - 1)];
      out[i] = a + (b - a) * fraction;
    }
    return out;
  }

  /// Writes interleaved float32 stereo, which is what the muxer reads back.
  static void write(File file, Float64List left, Float64List right) {
    final int frames = left.length;
    final Float32List out = Float32List(frames * 2);
    for (int i = 0; i < frames; i++) {
      out[i * 2] = left[i];
      out[i * 2 + 1] = right[i];
    }
    file.writeAsBytesSync(out.buffer.asUint8List(), flush: true);
  }
}
