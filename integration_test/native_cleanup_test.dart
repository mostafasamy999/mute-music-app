import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/core/di/injector.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/domain/use_cases/discard_leftovers_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/pick_video_use_case.dart';
import 'package:path_provider/path_provider.dart';

/// Device checks for temp-file cleanup and native resource release.
///
/// Needs a clip with a video and an audio track at
/// `<app support dir>/test_clip.mp4`. On Android:
/// ```
/// adb push test_clip.mp4 /data/local/tmp/
/// adb shell run-as com.mostafasamy.mutemusic.mute_music_app \
///   cp /data/local/tmp/test_clip.mp4 files/test_clip.mp4
/// ```
const MethodChannel _channel = MethodChannel('com.mostafasamy.mutemusic/video');

/// Hands out whatever the test queues, instead of opening the system picker.
class _QueuedPick implements PickVideoUseCase {
  final List<VideoAsset> queue = <VideoAsset>[];

  @override
  Future<DataState<VideoAsset?>> call() async =>
      DataSuccess<VideoAsset?>(queue.removeAt(0));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late File clip;
  late Directory cache;

  setUpAll(() async {
    setupInjector();
    clip = File(
      '${(await getApplicationSupportDirectory()).path}/test_clip.mp4',
    );
    cache = await getTemporaryDirectory();
    expect(clip.existsSync(), isTrue, reason: 'push the test clip first');
  });

  /// Only the files this app's pipeline names, ignoring the system's own.
  List<String> ours() =>
      cache
          .listSync()
          .whereType<File>()
          .map((File file) => file.uri.pathSegments.last)
          .where(
            (String name) =>
                name.startsWith('muted_') ||
                name.startsWith('nomusic_') ||
                name.startsWith('audio_') ||
                name.startsWith('picked_'),
          )
          .toList()
        ..sort();

  void clearOurs() {
    for (final String name in ours()) {
      File('${cache.path}/$name').deleteSync();
    }
  }

  group('T4.3 Android native pipeline', () {
    setUp(clearOurs);

    testWidgets('a mux that fails reports mux_failed and leaves no file', (
      _,
    ) async {
      await expectLater(
        _channel.invokeMethod<String>('muxAudio', <String, Object>{
          'videoPath': clip.path,
          'pcmPath': '${cache.path}/missing.pcm',
          'sampleRate': 44100,
          'channels': 2,
        }),
        throwsA(
          isA<PlatformException>().having(
            (PlatformException e) => e.code,
            'code',
            'mux_failed',
          ),
        ),
      );
      expect(ours(), isEmpty);
    });

    testWidgets('an extract that fails leaves no PCM file', (_) async {
      await expectLater(
        _channel.invokeMethod<Object>('extractAudio', <String, String>{
          'sourcePath': '${cache.path}/missing.mp4',
        }),
        throwsA(isA<PlatformException>()),
      );
      expect(ours(), isEmpty);
    });

    // A leaked encoder per failure would exhaust the device's codec
    // instances well before 30, so the real run at the end would fail.
    testWidgets('30 failed muxes in a row, then a real one still works', (
      _,
    ) async {
      for (int i = 0; i < 30; i++) {
        await expectLater(
          _channel.invokeMethod<String>('muxAudio', <String, Object>{
            'videoPath': clip.path,
            'pcmPath': '${cache.path}/missing.pcm',
            'sampleRate': 44100,
            'channels': 2,
          }),
          throwsA(isA<PlatformException>()),
        );
      }

      final Map<Object?, Object?> audio = (await _channel
          .invokeMethod<Map<Object?, Object?>>('extractAudio', <String, String>{
            'sourcePath': clip.path,
          }))!;
      final String pcm = audio['path']! as String;
      // The muxer reads 44.1 kHz stereo float32; a raw decode of a mono or
      // 22 kHz track would play at the wrong speed, but still proves the
      // codecs are usable, which is all this test is about.
      final String video = (await _channel.invokeMethod<String>(
        'muxAudio',
        <String, Object>{
          'videoPath': clip.path,
          'pcmPath': pcm,
          'sampleRate': 44100,
          'channels': 2,
        },
      ))!;

      expect(File(video).lengthSync(), greaterThan(0));
      File(pcm).deleteSync();
      File(video).deleteSync();
    });
  });

  group('T4.2 replaced files are discarded', () {
    setUp(clearOurs);

    testWidgets('pick → remove sound ×2 → pick leaves only current files', (
      _,
    ) async {
      final _QueuedPick pick = _QueuedPick();
      final MuteVideoCubit cubit = MuteVideoCubit(
        pick,
        injector(),
        injector(),
        injector(),
        injector(),
        injector(),
        injector(),
      );
      // Stand-ins for the copies image_picker makes in the cache.
      final File first = clip.copySync('${cache.path}/picked_1.mp4');
      final File second = clip.copySync('${cache.path}/picked_2.mp4');

      pick.queue.add(VideoAsset(path: first.path));
      await cubit.pickVideo();
      await cubit.removeSound();
      final String firstResult = cubit.state.muted!.path;
      await cubit.removeSound();
      final String secondResult = cubit.state.muted!.path;

      expect(cubit.state.status, MuteVideoStatus.muted);
      expect(File(firstResult).existsSync(), isFalse);
      expect(File(secondResult).existsSync(), isTrue);

      pick.queue.add(VideoAsset(path: second.path));
      await cubit.pickVideo();

      expect(ours(), <String>['picked_2.mp4']);
      await cubit.close();
    });

    testWidgets('a source outside the cache is never deleted', (_) async {
      final _QueuedPick pick = _QueuedPick();
      final MuteVideoCubit cubit = MuteVideoCubit(
        pick,
        injector(),
        injector(),
        injector(),
        injector(),
        injector(),
        injector(),
      );
      final File next = clip.copySync('${cache.path}/picked_3.mp4');

      pick.queue
        ..add(VideoAsset(path: clip.path))
        ..add(VideoAsset(path: next.path));
      await cubit.pickVideo();
      await cubit.pickVideo();

      expect(clip.existsSync(), isTrue);
      await cubit.close();
    });

    testWidgets('leftovers from an earlier launch go on start', (_) async {
      final DateTime earlier = DateTime.now().subtract(
        const Duration(minutes: 1),
      );
      for (final String name in <String>[
        'muted_old.mp4',
        'nomusic_old.mp4',
        'audio_old.pcm',
      ]) {
        File('${cache.path}/$name')
          ..writeAsStringSync('x')
          ..setLastModifiedSync(earlier);
      }

      await injector<DiscardLeftoversUseCase>()();

      expect(ours(), isEmpty);
    });
  });
}
