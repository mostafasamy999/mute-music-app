import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mute_music_app/src/core/audio/mdx_stft.dart';

/// The same signal the PyTorch reference was generated from.
Float64List _signal(int length) {
  final Float64List x = Float64List(length);
  for (int n = 0; n < length; n++) {
    x[n] =
        math.sin(2 * math.pi * 440 * n / 44100) +
        0.5 * math.sin(2 * math.pi * 1000 * n / 44100);
  }
  return x;
}

void main() {
  final Map<String, dynamic> reference =
      jsonDecode(File('test/stft_reference.json').readAsStringSync())
          as Map<String, dynamic>;
  final int length = reference['length'] as int;

  test('settings match the model parameter table', () {
    expect(MdxStft.nFft, reference['n_fft']);
    expect(MdxStft.hop, reference['hop']);
    expect(MdxStft.frameCount(length), reference['frames']);
  });

  test('reflect padding mirrors without repeating the edge', () {
    final Float64List padded = MdxStft.reflectPad(
      Float64List.fromList(<double>[1, 2, 3, 4]),
    );
    // pad is 3072, far bigger than this input, so just check the seam.
    expect(padded[MdxStft.pad], 1);
    expect(padded[MdxStft.pad + 1], 2);
    expect(padded[MdxStft.pad - 1], 2);
    expect(padded[MdxStft.pad - 2], 3);
  });

  test('spectrum matches the PyTorch reference', () {
    final MdxStft stft = MdxStft();
    final Float64List padded = MdxStft.reflectPad(_signal(length));
    final Map<int, Float64x2List> frames = <int, Float64x2List>{};

    for (final dynamic raw in reference['probes'] as List<dynamic>) {
      final Map<String, dynamic> probe = raw as Map<String, dynamic>;
      final int f = probe['frame'] as int;
      final int b = probe['bin'] as int;
      final Float64x2List spectrum = frames.putIfAbsent(
        f,
        () => stft.frame(padded, f),
      );
      expect(spectrum.length, MdxStft.bins);
      expect(
        spectrum[b].x,
        closeTo((probe['re'] as num).toDouble(), 1e-3),
        reason: 'real part, frame $f bin $b',
      );
      expect(
        spectrum[b].y,
        closeTo((probe['im'] as num).toDouble(), 1e-3),
        reason: 'imaginary part, frame $f bin $b',
      );
    }
  });

  test('forward then inverse rebuilds the signal', () {
    final MdxStft stft = MdxStft();
    final Float64List original = _signal(length);
    final Float64List padded = MdxStft.reflectPad(original);
    final int frames = MdxStft.frameCount(length);

    final Float64List acc = Float64List(length + 2 * MdxStft.pad);
    for (int f = 0; f < frames; f++) {
      final Float64List piece = stft.inverseFrame(stft.frame(padded, f));
      final int start = f * MdxStft.hop;
      for (int i = 0; i < MdxStft.nFft; i++) {
        if (start + i < acc.length) acc[start + i] += piece[i];
      }
    }

    final Float64List sum = MdxStft.windowSum(length);
    double worst = 0;
    // Skip the padded edges; those are discarded by the chunk trim in real use.
    for (int i = MdxStft.pad; i < MdxStft.pad + length; i++) {
      if (sum[i] < 1e-8) continue;
      final double got = acc[i] / sum[i];
      worst = math.max(worst, (got - original[i - MdxStft.pad]).abs());
    }
    expect(worst, lessThan(1e-6), reason: 'round trip error $worst');
  });
}
