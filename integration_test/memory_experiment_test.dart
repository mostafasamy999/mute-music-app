import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mute_music_app/src/core/audio/pcm_io.dart';
import 'package:mute_music_app/src/core/di/injector.dart';
import 'package:mute_music_app/src/core/diagnostics/memory_logger.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/data/local/device_memory_datasource.dart';
import 'package:mute_music_app/src/data/local/model_storage.dart';
import 'package:mute_music_app/src/data/local/separation_worker.dart';
import 'package:mute_music_app/src/domain/use_cases/ensure_model_ready_use_case.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TEMPORARY. Where does separation memory go, and does it come back?
///
/// One mode per app launch, so one run can't inflate the other:
/// ```
/// flutter run -t integration_test/memory_experiment_test.dart \
///   --dart-define=MODE=worker -d <device>
/// adb logcat | grep '\[MEM\]'
/// ```
/// MODE=main runs the same body on the UI isolate, like the code before 002.
const String _mode = String.fromEnvironment('MODE', defaultValue: 'worker');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => setupInjector(await SharedPreferences.getInstance()));

  testWidgets('memory around separation ($_mode)', (WidgetTester tester) async {
    final MemoryLogger log = MemoryLogger(DeviceMemoryDatasource());
    await tester.runAsync(() async {
      final DataState<void> model = await injector<EnsureModelReadyUseCase>()(
        onProgress: (_) {},
      );
      expect(model, isA<DataSuccess<void>>());

      final Directory temp = Directory.systemTemp.createTempSync('memory');
      const int frames = PcmIo.targetRate * 15;
      final Float64List tone = Float64List(frames);
      for (int i = 0; i < frames; i++) {
        tone[i] = 0.3 * math.sin(2 * math.pi * 440 * i / PcmIo.targetRate);
      }
      final File input = File('${temp.path}/in.pcm');
      PcmIo.write(input, tone, Float64List.fromList(tone));
      final SeparationJob job = SeparationJob(
        inputPcmPath: input.path,
        sampleRate: PcmIo.targetRate,
        channels: 2,
        modelPath: (await injector<ModelStorage>().modelFile()).path,
        outputPcmPath: '${temp.path}/out.pcm',
      );

      await log.mark('EXPERIMENT $_mode start');
      if (_mode == 'main') {
        await separateTrack(job, (_, _) {});
      } else {
        await const SeparationWorker().run(job, onChunk: (_, _) {});
      }
      await log.mark('EXPERIMENT $_mode job done');
      for (int second = 5; second <= 15; second += 5) {
        await Future<void>.delayed(const Duration(seconds: 5));
        await log.mark('EXPERIMENT $_mode idle ${second}s');
      }
      temp.deleteSync(recursive: true);
      debugPrint('[MEM] EXPERIMENT DONE');
    });
  });
}
