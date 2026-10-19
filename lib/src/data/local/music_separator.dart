import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:mute_music_app/src/core/audio/chunk_window.dart';
import 'package:mute_music_app/src/core/audio/mdx_tensor.dart';
import 'package:mute_music_app/src/core/audio/pcm_io.dart';
import 'package:mute_music_app/src/core/constants/model_constants.dart';

/// Runs the vocals model over a whole track and returns the voice-only audio.
class MusicSeparator {
  /// The model under-predicts level slightly; this is its published gain.
  static const double compensate = 1.035;

  Future<StereoAudio> separate({
    required String modelPath,
    required StereoAudio input,
    required void Function(double progress) onProgress,
  }) async {
    final OnnxRuntime runtime = OnnxRuntime();
    final OrtSession session = await runtime.createSession(
      modelPath,
      options: OrtSessionOptions(
        providers: <OrtProvider>[await _bestProvider(runtime), OrtProvider.CPU],
        useArena: false,
      ),
    );
    try {
      return await _runChunks(session, input, onProgress);
    } finally {
      await session.close();
    }
  }

  /// XNNPACK is several times faster than plain CPU on phone hardware.
  Future<OrtProvider> _bestProvider(OnnxRuntime runtime) async {
    final List<OrtProvider> available = await runtime.getAvailableProviders();
    for (final OrtProvider candidate in <OrtProvider>[
      OrtProvider.XNNPACK,
      OrtProvider.CORE_ML,
      OrtProvider.CPU,
    ]) {
      if (available.contains(candidate)) return candidate;
    }
    return OrtProvider.CPU;
  }

  Future<StereoAudio> _runChunks(
    OrtSession session,
    StereoAudio input,
    void Function(double) onProgress,
  ) async {
    final int samples = input.length;
    final int padded = ChunkWindow.paddedLength(samples);
    final Float64List left = ChunkWindow.pad(input.left, padded);
    final Float64List right = ChunkWindow.pad(input.right, padded);
    final Float64List outLeft = Float64List(samples);
    final Float64List outRight = Float64List(samples);
    final MdxTensor codec = MdxTensor();
    final int total = ChunkWindow.chunkCount(samples);

    for (int index = 0; index < total; index++) {
      final int start = index * ChunkWindow.genSize;
      final List<Float64List> piece = await _chunk(
        session,
        codec,
        ChunkWindow.sliceAt(left, start),
        ChunkWindow.sliceAt(right, start),
      );
      ChunkWindow.merge(outLeft, piece[0], start, compensate);
      ChunkWindow.merge(outRight, piece[1], start, compensate);
      onProgress((index + 1) / total);
    }
    return StereoAudio(outLeft, outRight);
  }

  Future<List<Float64List>> _chunk(
    OrtSession session,
    MdxTensor codec,
    Float64List left,
    Float64List right,
  ) async {
    final OrtValue value = await OrtValue.fromList(
      codec.pack(left, right),
      <int>[1, MdxTensor.channels, MdxTensor.dimF, MdxTensor.dimT],
    );
    final Map<String, OrtValue> result = await session.run(<String, OrtValue>{
      ModelConstants.inputName: value,
    });
    final OrtValue output = result.values.first;
    final List<Float64List> waves = codec.unpack(await _floats(output));
    await value.dispose();
    await output.dispose();
    return waves;
  }

  Future<Float32List> _floats(OrtValue value) async {
    final List<dynamic> raw = await value.asFlattenedList();
    return raw is Float32List ? raw : Float32List.fromList(raw.cast<double>());
  }
}
