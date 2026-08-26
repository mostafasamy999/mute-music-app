import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fftea/fftea.dart';

/// Short-time Fourier transform matching the settings baked into the MDX
/// vocals model. Every number here comes from the model's own parameter entry,
/// not from a guess — a wrong window or pad mode produces noise, not a warning.
class MdxStft {
  MdxStft() : _fft = FFT(nFft), _window = _hannPeriodic(nFft);

  static const int nFft = 6144;
  static const int hop = 1024;

  /// Bins the model keeps. The transform produces [bins]; the rest is dropped.
  static const int dimF = 2048;
  static const int bins = nFft ~/ 2 + 1;
  static const int pad = nFft ~/ 2;

  final FFT _fft;
  final Float64List _window;

  /// Same count as torch.stft with center: true.
  static int frameCount(int sampleCount) => 1 + sampleCount ~/ hop;

  /// Reflect padding, the default torch.stft uses. Mirrors without repeating
  /// the edge sample, so [a,b,c,d] with pad 2 becomes [c,b,a,b,c,d,c,b].
  static Float64List reflectPad(Float64List x) {
    final int n = x.length;
    final Float64List out = Float64List(n + 2 * pad);
    for (int i = 0; i < out.length; i++) {
      out[i] = x[_fold(i - pad, n)];
    }
    return out;
  }

  /// Bounces an out-of-range index back inside 0..n-1, reflecting as many times
  /// as needed. Clips shorter than the pad reflect more than once.
  static int _fold(int index, int n) {
    if (n == 1) return 0;
    final int period = 2 * (n - 1);
    final int m = index % period;
    return m <= n - 1 ? m : period - m;
  }

  /// Complex spectrum of one frame, length [bins].
  Float64x2List frame(Float64List padded, int index) {
    final Float64List buffer = Float64List(nFft);
    final int start = index * hop;
    for (int i = 0; i < nFft; i++) {
      buffer[i] = padded[start + i] * _window[i];
    }
    return _fft.realFft(buffer).discardConjugates();
  }

  /// Rebuilds one frame of samples from its spectrum, window already applied.
  Float64List inverseFrame(Float64x2List spectrum) {
    final Float64List samples = _fft.realInverseFft(
      spectrum.createConjugates(nFft),
    );
    for (int i = 0; i < nFft; i++) {
      samples[i] *= _window[i];
    }
    return samples;
  }

  /// Sum of squared window values per output sample, used to undo the overlap
  /// weighting after adding frames back together.
  static Float64List windowSum(int sampleCount) {
    final Float64List window = _hannPeriodic(nFft);
    final Float64List sum = Float64List(sampleCount + 2 * pad);
    final int frames = frameCount(sampleCount);
    for (int f = 0; f < frames; f++) {
      final int start = f * hop;
      for (int i = 0; i < nFft; i++) {
        if (start + i < sum.length) sum[start + i] += window[i] * window[i];
      }
    }
    return sum;
  }

  static Float64List _hannPeriodic(int size) {
    final Float64List window = Float64List(size);
    for (int i = 0; i < size; i++) {
      window[i] = 0.5 - 0.5 * math.cos(2 * math.pi * i / size);
    }
    return window;
  }
}
