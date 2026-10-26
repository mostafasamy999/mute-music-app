import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mute_music_app/src/core/di/injector.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/data/local/video_mute_datasource.dart';
import 'package:mute_music_app/src/domain/entities/removal_progress.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/domain/repositories/speech_model_repository.dart';
import 'package:mute_music_app/src/domain/repositories/text_repository.dart';
import 'package:mute_music_app/src/domain/use_cases/ensure_model_ready_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/remove_music_use_case.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Spec 006 S15: Remove music only end to end with the real separation
/// model, on a video (the original pipeline, VIP) and on a sound file (S13),
/// then Whisper checks that the voice is still there.
///
/// Pass a video with speech over music (made with the S15 media script):
///   --dart-define=MUSIC_VIDEO=/path/video_en.mp4
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const String source = String.fromEnvironment('MUSIC_VIDEO');

  final VideoMuteDatasource native = VideoMuteDatasource();
  late VideoAsset video;

  setUpAll(() async {
    setupInjector(await SharedPreferences.getInstance());
    final File copy = File(
      source,
    ).copySync('${Directory.systemTemp.path}/e2e_video.mp4');
    video = VideoAsset(
      path: copy.path,
      duration: Duration(milliseconds: (await native.durationMs(copy.path))!),
    );
    final Stopwatch clock = Stopwatch()..start();
    final DataState<void> model = await injector<EnsureModelReadyUseCase>()(
      onProgress: (_) {},
    );
    // ignore: avoid_print
    print('E2E separation model ready in ${clock.elapsedMilliseconds} ms');
    expect(model, isA<DataSuccess<void>>());
    expect(
      await injector<SpeechModelRepository>().download(onProgress: (_) {}),
      isA<DataSuccess<void>>(),
    );
  });

  Future<MediaAsset> removeMusic(MediaAsset file) async {
    final List<RemovalStep> steps = <RemovalStep>[];
    final Stopwatch clock = Stopwatch()..start();
    final DataState<VideoAsset> result = await injector<RemoveMusicUseCase>()(
      file,
      onProgress: (RemovalProgress p) {
        if (steps.isEmpty || steps.last != p.step) steps.add(p.step);
      },
    );
    // ignore: avoid_print
    print(
      'E2E remove music on ${file.kind.name} in '
      '${clock.elapsedMilliseconds} ms, steps $steps: $result',
    );
    return (result as DataSuccess<VideoAsset>).data;
  }

  Future<String> words(MediaAsset file) async {
    final DataState<String> text = await injector<TextRepository>().extractText(
      file,
    );
    // ignore: avoid_print
    print(
      'E2E heard in ${file.path.split('/').last}: '
      '${text is DataSuccess<String> ? text.data : text}',
    );
    return (text as DataSuccess<String>).data.toLowerCase();
  }

  testWidgets(
    'video: music removed, same length, voice kept (VIP)',
    (_) async {
      final MediaAsset result = await removeMusic(video);

      expect(result.isVideo, isTrue);
      final int length = (await native.durationMs(result.path))!;
      expect((length - video.duration!.inMilliseconds).abs(), lessThan(200));
      expect(await words(result), contains('hello'));
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );

  testWidgets(
    'sound file: music removed into .m4a, voice kept (S13)',
    (_) async {
      final MediaAsset sound = MediaAsset(
        path: await native.exportAudio(video.path),
        kind: MediaKind.audio,
        duration: video.duration,
      );

      final MediaAsset result = await removeMusic(sound);

      expect(result.isAudio, isTrue);
      expect(result.path, endsWith('.m4a'));
      final int length = (await native.durationMs(result.path))!;
      expect((length - video.duration!.inMilliseconds).abs(), lessThan(200));
      expect(await words(result), contains('hello'));
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
