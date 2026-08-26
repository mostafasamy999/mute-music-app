import 'dart:typed_data';

import 'package:mute_music_app/src/core/audio/mdx_stft.dart';
import 'package:mute_music_app/src/core/audio/mdx_tensor.dart';

/// Slicing rules for feeding a long track through a fixed-size model.
///
/// Each window is [MdxTensor.chunkSamples] long but only its middle
/// [genSize] samples are kept. The discarded edges are the parts where the
/// model had no context, so joins between chunks stay clean.
abstract final class ChunkWindow {
  static const int trim = MdxStft.pad;
  static const int genSize = MdxTensor.chunkSamples - 2 * trim;

  /// Zeros before and after the real audio, so the first and last chunk have
  /// the same shape as every other one.
  static int paddedLength(int samples) =>
      trim + samples + (genSize - samples % genSize) + trim;

  static int chunkCount(int samples) =>
      (samples + (genSize - samples % genSize)) ~/ genSize;

  static Float64List pad(Float64List source, int length) {
    final Float64List out = Float64List(length);
    out.setRange(trim, trim + source.length, source);
    return out;
  }

  static Float64List sliceAt(Float64List source, int start) {
    final Float64List out = Float64List(MdxTensor.chunkSamples);
    final int available = source.length - start;
    final int count = available < MdxTensor.chunkSamples
        ? available
        : MdxTensor.chunkSamples;
    if (count > 0) out.setRange(0, count, source, start);
    return out;
  }

  /// Writes the usable middle of one chunk into the final track.
  static void merge(
    Float64List target,
    Float64List chunk,
    int start,
    double gain,
  ) {
    for (int i = 0; i < genSize; i++) {
      final int at = start + i;
      if (at >= target.length) return;
      target[at] = chunk[trim + i] * gain;
    }
  }
}
