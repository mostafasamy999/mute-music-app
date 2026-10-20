import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// Device checks for the native cut (spec 003 §6, task T1/T2).
///
/// Needs a clip with a video and an audio track, at least 4 s long, at
/// `<app support dir>/test_clip.mp4` (see native_cleanup_test.dart).
const MethodChannel _channel = MethodChannel('com.mostafasamy.mutemusic/video');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late File clip;
  late Directory cache;
  late int clipMs;

  setUpAll(() async {
    clip = File(
      '${(await getApplicationSupportDirectory()).path}/test_clip.mp4',
    );
    cache = await getTemporaryDirectory();
    expect(clip.existsSync(), isTrue, reason: 'push the test clip first');
    clipMs = (await _channel.invokeMethod<int>(
      'videoDuration',
      <String, Object>{'sourcePath': clip.path},
    ))!;
    expect(clipMs, greaterThan(4000), reason: 'the clip must be over 4 s');
  });

  List<String> parts() => cache
      .listSync()
      .whereType<File>()
      .map((File file) => file.uri.pathSegments.last)
      .where((String name) => name.startsWith('part_'))
      .toList();

  Future<Map<Object?, Object?>> cut(int startMs, int endMs) async =>
      (await _channel.invokeMapMethod<Object?, Object?>(
        'cutVideo',
        <String, Object>{
          'sourcePath': clip.path,
          'startMs': startMs,
          'endMs': endMs,
        },
      ))!;

  testWidgets('a cut keeps video and audio, and starts on or before the ask', (
    _,
  ) async {
    final Stopwatch watch = Stopwatch()..start();
    final Map<Object?, Object?> part = await cut(2000, 4000);
    watch.stop();
    final String path = part['path']! as String;
    final int startMs = part['startMs']! as int;
    final int endMs = part['endMs']! as int;
    final int partMs = (await _channel.invokeMethod<int>(
      'videoDuration',
      <String, Object>{'sourcePath': path},
    ))!;
    // ignore: avoid_print
    print(
      'CUT asked 2000-4000 got $startMs-$endMs, file ${partMs}ms, '
      '${File(path).lengthSync()} bytes, ${watch.elapsedMilliseconds}ms '
      '(clip ${clipMs}ms)',
    );

    expect(File(path).existsSync(), isTrue);
    expect(startMs, lessThanOrEqualTo(2000));
    expect(endMs, inInclusiveRange(3900, 4000));
    expect(partMs, closeTo(endMs - startMs, 150));
    expect(watch.elapsedMilliseconds, lessThan(3000));

    // The part still has an audio track: the audio pipeline can read it.
    final Map<Object?, Object?> pcm = (await _channel
        .invokeMapMethod<Object?, Object?>('extractAudio', <String, Object>{
          'sourcePath': path,
        }))!;
    File(pcm['path']! as String).deleteSync();

    // And a video track: removing the sound works on it.
    final String muted = (await _channel.invokeMethod<String>(
      'removeSound',
      <String, Object>{'sourcePath': path},
    ))!;
    File(muted).deleteSync();
    File(path).deleteSync();
  });

  testWidgets('an end past the video is cut at the video end', (_) async {
    final Map<Object?, Object?> part = await cut(clipMs - 1500, clipMs + 60000);
    expect(part['endMs']! as int, lessThanOrEqualTo(clipMs));
    File(part['path']! as String).deleteSync();
  });

  for (final (String name, int start, int end) in <(String, int, int)>[
    ('start after end', 3000, 1000),
    ('start past the video', 999999999, 1000000000),
  ]) {
    testWidgets('$name fails as bad_range and leaves no file', (_) async {
      final List<String> before = parts();
      await expectLater(
        cut(start, end),
        throwsA(
          isA<PlatformException>().having(
            (PlatformException e) => e.code,
            'code',
            'bad_range',
          ),
        ),
      );
      expect(parts(), before);
    });
  }

  testWidgets('a file that is not a video fails cleanly and leaves no part', (
    _,
  ) async {
    final File bogus = File('${cache.path}/not_a_video.mp4')
      ..writeAsBytesSync(List<int>.filled(1024, 7));
    await expectLater(
      _channel.invokeMethod<Object?>('cutVideo', <String, Object>{
        'sourcePath': bogus.path,
        'startMs': 0,
        'endMs': 1000,
      }),
      throwsA(isA<PlatformException>()),
    );
    bogus.deleteSync();
    expect(parts(), isEmpty);
  });
}
