import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mute_music_app/src/core/audio/mdx_tensor.dart';

/// The same two tones the PyTorch reference was built from.
Float64List _tone(int length, double hz, double gain) {
  final Float64List x = Float64List(length);
  for (int n = 0; n < length; n++) {
    x[n] = gain * math.sin(2 * math.pi * hz * n / 44100);
  }
  return x;
}

void main() {
  final Map<String, dynamic> reference =
      jsonDecode(File('test/tensor_reference.json').readAsStringSync())
          as Map<String, dynamic>;

  test('chunk size and shape match the reference', () {
    expect(MdxTensor.chunkSamples, reference['chunk']);
    expect(MdxTensor.dimF, reference['dim_f']);
    expect(MdxTensor.dimT, reference['dim_t']);
  });

  test('packed tensor matches the PyTorch reference', () {
    final int chunk = MdxTensor.chunkSamples;
    final Float32List tensor = MdxTensor().pack(
      _tone(chunk, 440, 1),
      _tone(chunk, 1000, 0.5),
    );

    expect(tensor.length, MdxTensor.channels * MdxTensor.dimF * MdxTensor.dimT);

    for (final dynamic raw in reference['probes'] as List<dynamic>) {
      final Map<String, dynamic> p = raw as Map<String, dynamic>;
      final int c = p['c'] as int;
      final int f = p['f'] as int;
      final int t = p['t'] as int;
      final int index =
          (c * MdxTensor.dimF + f) * MdxTensor.dimT + t;
      expect(
        tensor[index],
        closeTo((p['v'] as num).toDouble(), 1e-2),
        reason: 'channel $c, bin $f, frame $t',
      );
    }
  });

  test('pack then unpack rebuilds the audio', () {
    final int chunk = MdxTensor.chunkSamples;
    final Float64List left = _tone(chunk, 440, 1);
    final Float64List right = _tone(chunk, 1000, 0.5);

    final MdxTensor codec = MdxTensor();
    final List<Float64List> out = codec.unpack(codec.pack(left, right));

    // The top third of the spectrum is dropped by dim_f, so the rebuilt signal
    // is close but not identical. Both test tones sit well below that cut.
    double worst = 0;
    for (int i = MdxStftPadding.safeStart; i < chunk - MdxStftPadding.safeStart; i++) {
      worst = math.max(worst, (out[0][i] - left[i]).abs());
      worst = math.max(worst, (out[1][i] - right[i]).abs());
    }
    expect(worst, lessThan(0.02), reason: 'round trip error $worst');
  });
}

/// Edges of a chunk overlap with neighbours in real use and get trimmed there.
abstract final class MdxStftPadding {
  static const int safeStart = 6144;
}
