import 'dart:typed_data';

import 'package:mute_music_app/src/core/audio/mdx_stft.dart';

/// Converts one chunk of stereo audio into the exact tensor the MDX model
/// expects, and back again.
///
/// Channel order is [left real, left imag, right real, right imag] — the model
/// was trained that way, and swapping two of them still produces audio, just
/// wrong audio. That is why this is covered by a test against the reference.
class MdxTensor {
  MdxTensor() : _stft = MdxStft();

  static const int dimF = 2048;
  static const int dimT = 512;
  static const int channels = 4;

  /// Samples one chunk covers: 523264, about 11.87 s at 44.1 kHz.
  static const int chunkSamples = MdxStft.hop * (dimT - 1);

  final MdxStft _stft;

  Float32List pack(Float64List left, Float64List right) {
    final Float32List out = Float32List(channels * dimF * dimT);
    _packChannel(left, out, 0);
    _packChannel(right, out, 1);
    return out;
  }

  void _packChannel(Float64List samples, Float32List out, int channel) {
    final Float64List padded = MdxStft.reflectPad(samples);
    final int realBase = channel * 2 * dimF * dimT;
    final int imagBase = (channel * 2 + 1) * dimF * dimT;
    for (int t = 0; t < dimT; t++) {
      final Float64x2List spectrum = _stft.frame(padded, t);
      for (int f = 0; f < dimF; f++) {
        out[realBase + f * dimT + t] = spectrum[f].x;
        out[imagBase + f * dimT + t] = spectrum[f].y;
      }
    }
  }

  /// Rebuilds stereo samples from a model output tensor.
  List<Float64List> unpack(Float32List tensor) => <Float64List>[
    _unpackChannel(tensor, 0),
    _unpackChannel(tensor, 1),
  ];

  Float64List _unpackChannel(Float32List tensor, int channel) {
    final int realBase = channel * 2 * dimF * dimT;
    final int imagBase = (channel * 2 + 1) * dimF * dimT;
    final Float64List acc = Float64List(chunkSamples + 2 * MdxStft.pad);

    for (int t = 0; t < dimT; t++) {
      final Float64x2List spectrum = Float64x2List(MdxStft.bins);
      for (int f = 0; f < dimF; f++) {
        spectrum[f] = Float64x2(
          tensor[realBase + f * dimT + t],
          tensor[imagBase + f * dimT + t],
        );
      }
      _addFrame(acc, _stft.inverseFrame(spectrum), t * MdxStft.hop);
    }
    return _normalise(acc);
  }

  void _addFrame(Float64List acc, Float64List frame, int start) {
    final int end = start + MdxStft.nFft < acc.length
        ? MdxStft.nFft
        : acc.length - start;
    for (int i = 0; i < end; i++) {
      acc[start + i] += frame[i];
    }
  }

  /// Undoes the overlap weighting and drops the padded edges.
  Float64List _normalise(Float64List acc) {
    final Float64List sum = MdxStft.windowSum(chunkSamples);
    final Float64List out = Float64List(chunkSamples);
    for (int i = 0; i < chunkSamples; i++) {
      final double weight = sum[i + MdxStft.pad];
      out[i] = weight < 1e-8 ? 0 : acc[i + MdxStft.pad] / weight;
    }
    return out;
  }
}
