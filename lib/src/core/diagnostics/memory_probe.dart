import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:mute_music_app/src/core/constants/model_constants.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/data/local/device_memory_datasource.dart';
import 'package:mute_music_app/src/data/local/model_storage.dart';
import 'package:mute_music_app/src/domain/use_cases/ensure_model_ready_use_case.dart';

/// One chunk covers 512 frames x 1024 hop at 44.1 kHz.
const double _chunkSeconds = 512 * 1024 / 44100;

/// TEMPORARY. Answers one question on a real device: does loading and running
/// the separation model fit in memory, and how fast is it? Delete when settled.
class MemoryProbe {
  const MemoryProbe(this._ensureModel, this._storage, this._memory);

  final EnsureModelReadyUseCase _ensureModel;
  final ModelStorage _storage;
  final DeviceMemoryDatasource _memory;

  Future<void> run({
    required void Function(String line) log,
    required void Function(double value) progress,
  }) async {
    final MemoryReport start = await _memory.read();
    log('device RAM   ${start.deviceTotalMb.toStringAsFixed(0)} MB');
    log('baseline     ${start.footprintMb.toStringAsFixed(0)} MB');
    if (!await _download(log, progress)) return;

    final OnnxRuntime runtime = OnnxRuntime();
    final List<OrtProvider> available = await runtime.getAvailableProviders();
    log('providers    ${available.map((OrtProvider p) => p.name).join(', ')}');
    log('');
    log('NOTE: memory is not returned between providers, so only the');
    log('FIRST block below is a clean reading. Later ones are inflated.');
    log('');

    final String path = (await _storage.modelFile()).path;
    for (final OrtProvider provider in _worthTesting(available)) {
      await _measure(runtime, path, provider, log, start.footprintMb);
    }
  }

  Future<bool> _download(
    void Function(String) log,
    void Function(double) progress,
  ) async {
    if (await _storage.isReady()) return true;
    log('downloading  ${ModelConstants.vocalsModelSizeInBytes ~/ 1048576} MB ...');
    final DataState<void> result = await _ensureModel(onProgress: progress);
    if (result is DataFailed<void>) {
      log('DOWNLOAD FAILED — check the connection and retry');
      return false;
    }
    return true;
  }

  List<OrtProvider> _worthTesting(List<OrtProvider> available) => <OrtProvider>[
    OrtProvider.CPU,
    OrtProvider.XNNPACK,
    OrtProvider.NNAPI,
    OrtProvider.CORE_ML,
  ].where(available.contains).toList();

  Future<void> _measure(
    OnnxRuntime runtime,
    String path,
    OrtProvider provider,
    void Function(String) log,
    double baselineMb,
  ) async {
    final MemoryReport before = await _memory.read();
    log('--- ${provider.name} ---');
    try {
      final OrtSession session = await runtime.createSession(
        path,
        options: OrtSessionOptions(
          providers: <OrtProvider>[provider, OrtProvider.CPU],
          useArena: false,
        ),
      );
      await _infer(session, log, before.footprintMb);
      await session.close();
    } on Object catch (error) {
      log('  FAILED: $error');
    }
    log('');
  }

  Future<void> _infer(
    OrtSession session,
    void Function(String) log,
    double baselineMb,
  ) async {
    final int count = ModelConstants.inputShape.reduce((int a, int b) => a * b);
    final OrtValue input = await OrtValue.fromList(
      Float32List(count),
      ModelConstants.inputShape,
    );
    final Stopwatch watch = Stopwatch()..start();
    final Map<String, OrtValue> output = await session.run(
      <String, OrtValue>{ModelConstants.inputName: input},
    );
    watch.stop();

    final MemoryReport after = await _memory.read();
    final double perMinute =
        watch.elapsedMilliseconds / 1000 * (60 / _chunkSeconds);
    log('  chunk      ${watch.elapsedMilliseconds} ms');
    log('  3-min clip ~${(perMinute * 3).toStringAsFixed(0)} s');
    log('  PEAK       ${after.footprintMb.toStringAsFixed(0)} MB'
        ' (+${(after.footprintMb - baselineMb).toStringAsFixed(0)})');

    await input.dispose();
    for (final OrtValue value in output.values) {
      await value.dispose();
    }
  }
}
