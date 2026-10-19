import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:mute_music_app/src/core/audio/chunk_window.dart';
import 'package:mute_music_app/src/core/audio/mdx_tensor.dart';
import 'package:mute_music_app/src/core/audio/pcm_io.dart';
import 'package:mute_music_app/src/core/constants/model_constants.dart';

/// Called with a label before and after each model call, so diagnostics can
/// log memory around it. Awaited, so the reading belongs to that exact point.
typedef SeparationProbe = Future<void> Function(String label);

/// Runs the vocals model over a whole track and returns the voice-only audio.
class MusicSeparator {
  const MusicSeparator({this.probe});

  /// TEMPORARY diagnostics hook. Null in normal runs.
  final SeparationProbe? probe;

  Future<void> _mark(String label) async => probe?.call(label);

  /// The model under-predicts level slightly; this is its published gain.
  static const double compensate = 1.035;

  Future<StereoAudio> separate({
    required String modelPath,
    required StereoAudio input,
    required void Function(int done, int total) onProgress,
  }) async {
    final OnnxRuntime runtime = OnnxRuntime();
    final OrtProvider provider = await _bestProvider(runtime);
    await _mark('before createSession (${provider.name})');
    final OrtSession session = await runtime.createSession(
      modelPath,
      options: OrtSessionOptions(
        // CPU is the fallback; listing it twice makes the runtime refuse to
        // create the session.
        providers: <OrtProvider>{provider, OrtProvider.CPU}.toList(),
        useArena: false,
      ),
    );
    await _mark('after createSession');
    try {
      return await _runChunks(session, input, onProgress);
    } finally {
      await session.close();
      await _mark('after session.close');
    }
  }

  Future<OrtProvider> _bestProvider(OnnxRuntime runtime) async {
    // TEMPORARY diagnostics: --dart-define=ORT_PROVIDER=CPU forces one.
    const String forced = String.fromEnvironment('ORT_PROVIDER');
    if (forced.isNotEmpty) return OrtProvider.values.byName(forced);
    final List<OrtProvider> available = await runtime.getAvailableProviders();
    // No XNNPACK: on Android (onnxruntime 1.23) each run with it kept about
    // 2.6 GB of native memory, even after dispose and session.close, so a
    // 15 s clip reached 3.4 GB and the OS killed the app. It was also slower:
    // about 45 s per chunk against 20 s on CPU (SM-A515F, profile build).
    for (final OrtProvider candidate in <OrtProvider>[
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
    void Function(int done, int total) onProgress,
  ) async {
    final int samples = input.length;
    final int padded = ChunkWindow.paddedLength(samples);
    final Float64List left = ChunkWindow.pad(input.left, padded);
    final Float64List right = ChunkWindow.pad(input.right, padded);
    final Float64List outLeft = Float64List(samples);
    final Float64List outRight = Float64List(samples);
    final MdxTensor codec = MdxTensor();
    final int total = ChunkWindow.chunkCount(samples);
    onProgress(0, total);

    for (int index = 0; index < total; index++) {
      final int start = index * ChunkWindow.genSize;
      final List<Float64List> piece = await _chunk(
        index,
        session,
        codec,
        ChunkWindow.sliceAt(left, start),
        ChunkWindow.sliceAt(right, start),
      );
      ChunkWindow.merge(outLeft, piece[0], start, compensate);
      ChunkWindow.merge(outRight, piece[1], start, compensate);
      onProgress(index + 1, total);
    }
    return StereoAudio(outLeft, outRight);
  }

  Future<List<Float64List>> _chunk(
    int index,
    OrtSession session,
    MdxTensor codec,
    Float64List left,
    Float64List right,
  ) async {
    final String at = 'chunk $index';
    final Float32List packed = codec.pack(left, right);
    await _mark('$at after pack');
    final OrtValue value = await OrtValue.fromList(
      packed,
      <int>[1, MdxTensor.channels, MdxTensor.dimF, MdxTensor.dimT],
    );
    await _mark('$at after fromList');
    final Map<String, OrtValue> result = await session.run(<String, OrtValue>{
      ModelConstants.inputName: value,
    });
    await _mark('$at after run (${result.length} outputs)');
    final OrtValue output = result.values.first;
    final Float32List floats = await _floats(output);
    await _mark('$at after asFlattenedList');
    final List<Float64List> waves = codec.unpack(floats);
    await value.dispose();
    await output.dispose();
    await _mark('$at after dispose');
    return waves;
  }

  Future<Float32List> _floats(OrtValue value) async {
    final List<dynamic> raw = await value.asFlattenedList();
    return raw is Float32List ? raw : Float32List.fromList(raw.cast<double>());
  }
}
