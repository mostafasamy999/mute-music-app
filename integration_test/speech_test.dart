import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/data/local/audio_pipeline_datasource.dart';
import 'package:mute_music_app/src/data/local/speech_datasource.dart';
import 'package:mute_music_app/src/data/local/video_mute_datasource.dart';
import 'package:mute_music_app/src/data/repositories/speech_model_repository_impl.dart';
import 'package:mute_music_app/src/data/repositories/text_repository_impl.dart';
import 'package:mute_music_app/src/domain/entities/media_asset.dart';

/// Spec 006 S14 end to end on a device or simulator: the real model
/// download (about 148 MB, SHA-256 checked), the native extract, the 16 kHz
/// conversion and whisper.cpp.
///
/// Pass sound files with speech, for example made with macOS `say`:
///   --dart-define=SPEECH_EN=/path/en.m4a --dart-define=SPEECH_AR=/path/ar.m4a
/// (an iOS simulator can read files on the Mac). Without them the test skips.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const String english = String.fromEnvironment('SPEECH_EN');
  const String arabic = String.fromEnvironment('SPEECH_AR');

  final SpeechDatasource speech = SpeechDatasource();
  final TextRepositoryImpl texts = TextRepositoryImpl(
    VideoMuteDatasource(),
    AudioPipelineDatasource(),
    speech,
  );

  Future<String> read(String hostPath) async {
    // A copy in the app's temp folder, like a picked file.
    final File copy = File(
      hostPath,
    ).copySync('${Directory.systemTemp.path}/${hostPath.split('/').last}');
    final Stopwatch clock = Stopwatch()..start();
    final DataState<String> result = await texts.extractText(
      MediaAsset(path: copy.path, kind: MediaKind.audio),
    );
    // ignore: avoid_print
    print(
      'S14 ${hostPath.split('/').last} in ${clock.elapsedMilliseconds} ms: '
      '${result is DataSuccess<String> ? result.data : result}',
    );
    return (result as DataSuccess<String>).data;
  }

  testWidgets(
    'the model downloads once and passes its SHA-256',
    (_) async {
      final SpeechModelRepositoryImpl models = SpeechModelRepositoryImpl(
        speech,
      );
      final Stopwatch clock = Stopwatch()..start();
      final DataState<void> done = await models.download(onProgress: (_) {});
      // ignore: avoid_print
      print('S14 model ready in ${clock.elapsedMilliseconds} ms');
      expect(done, isA<DataSuccess<void>>());
      expect(await models.isReady(), isTrue);
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );

  testWidgets('reads English speech', (_) async {
    final String text = (await read(english)).toLowerCase();
    expect(text, contains('hello'));
    expect(text, contains('world'));
  }, skip: english.isEmpty);

  testWidgets('reads Arabic speech', (_) async {
    final String text = await read(arabic);
    expect(text, contains(RegExp('[؀-ۿ]')));
    expect(text, contains('مرحب'));
  }, skip: arabic.isEmpty);
}
