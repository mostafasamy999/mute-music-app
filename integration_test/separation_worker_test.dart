import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mute_music_app/src/core/audio/pcm_io.dart';
import 'package:mute_music_app/src/core/di/injector.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/data/local/model_storage.dart';
import 'package:mute_music_app/src/data/local/separation_worker.dart';
import 'package:mute_music_app/src/domain/use_cases/ensure_model_ready_use_case.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Spec 002 T1: the real model runs inside the worker isolate, and the UI
/// isolate stays free while it does. Downloads the model on first run.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => setupInjector(await SharedPreferences.getInstance()));

  testWidgets('the model runs on the worker isolate and the UI stays free', (
    WidgetTester tester,
  ) async {
    final DataState<void> model = await injector<EnsureModelReadyUseCase>()(
      onProgress: (_) {},
    );
    expect(model, isA<DataSuccess<void>>());

    // 15 s of a stereo tone: two model chunks.
    final Directory temp = Directory.systemTemp.createTempSync('worker');
    const int frames = PcmIo.targetRate * 15;
    final Float64List left = Float64List(frames);
    for (int i = 0; i < frames; i++) {
      left[i] = 0.3 * math.sin(2 * math.pi * 440 * i / PcmIo.targetRate);
    }
    final File input = File('${temp.path}/in.pcm');
    PcmIo.write(input, left, Float64List.fromList(left));
    final File output = File('${temp.path}/out.pcm');
    final String modelPath = (await injector<ModelStorage>().modelFile()).path;

    // A 16 ms ticker on the UI isolate. If the work ran here, the gaps
    // between ticks would grow to whole seconds.
    final Stopwatch clock = Stopwatch()..start();
    int last = 0;
    int worstGapMs = 0;
    final Timer ticker = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final int now = clock.elapsedMilliseconds;
      worstGapMs = math.max(worstGapMs, now - last);
      last = now;
    });

    final List<(int, int)> chunks = <(int, int)>[];
    await tester.runAsync(
      () => const SeparationWorker().run(
        SeparationJob(
          inputPcmPath: input.path,
          sampleRate: PcmIo.targetRate,
          channels: 2,
          modelPath: modelPath,
          outputPcmPath: output.path,
        ),
        onChunk: (int done, int total) => chunks.add((done, total)),
      ),
    );
    ticker.cancel();
    final int totalMs = clock.elapsedMilliseconds;

    // ignore: avoid_print
    print(
      'T1 spike: ${chunks.length} progress messages $chunks, '
      'total ${totalMs}ms, worst UI gap ${worstGapMs}ms',
    );
    expect(chunks.last, (2, 2));
    expect(output.lengthSync(), frames * 2 * 4);
    expect(worstGapMs, lessThan(250));
    temp.deleteSync(recursive: true);
  });
}
