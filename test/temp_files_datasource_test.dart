import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mute_music_app/src/data/local/temp_files_datasource.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Points the temp folder at a throwaway directory.
class _FakePaths extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePaths(this.temp);

  final String temp;

  @override
  Future<String?> getTemporaryPath() async => temp;
}

void main() {
  late Directory temp;
  late Directory outside;
  final TempFilesDatasource datasource = TempFilesDatasource();

  setUp(() {
    temp = Directory.systemTemp.createTempSync('temp_files');
    outside = Directory.systemTemp.createTempSync('gallery');
    PathProviderPlatform.instance = _FakePaths(temp.path);
  });

  tearDown(() {
    temp.deleteSync(recursive: true);
    outside.deleteSync(recursive: true);
  });

  File touch(Directory directory, String name, {DateTime? modified}) {
    final File file = File('${directory.path}/$name')..writeAsStringSync('x');
    if (modified != null) file.setLastModifiedSync(modified);
    return file;
  }

  test('delete removes a file inside the temp folder', () async {
    final File file = touch(temp, 'muted_1.mp4');

    await datasource.delete(file.path);

    expect(file.existsSync(), isFalse);
  });

  test('delete never touches a file outside the temp folder', () async {
    final File original = touch(outside, 'holiday.mp4');

    await datasource.delete(original.path);

    expect(original.existsSync(), isTrue);
  });

  test('delete of a missing file does nothing', () async {
    await expectLater(datasource.delete('${temp.path}/gone.mp4'), completes);
  });

  test('leftovers: only old files with our prefixes go', () async {
    final DateTime start = DateTime.now();
    final DateTime old = start.subtract(const Duration(minutes: 5));
    final File muted = touch(temp, 'muted_1.mp4', modified: old);
    final File noMusic = touch(temp, 'nomusic_1.mp4', modified: old);
    final File audio = touch(temp, 'audio_1.pcm.voice.pcm', modified: old);
    final File foreign = touch(temp, 'image_picker_1.mp4', modified: old);
    final File fresh = touch(
      temp,
      'muted_2.mp4',
      modified: start.add(const Duration(seconds: 1)),
    );

    await datasource.deleteLeftovers(before: start);

    expect(muted.existsSync(), isFalse);
    expect(noMusic.existsSync(), isFalse);
    expect(audio.existsSync(), isFalse);
    expect(foreign.existsSync(), isTrue);
    expect(fresh.existsSync(), isTrue);
  });

  group('with a second temp folder (iOS tmp/ next to Library/Caches)', () {
    late Directory nativeTemp;
    late TempFilesDatasource twoFolders;

    setUp(() {
      nativeTemp = Directory.systemTemp.createTempSync('native_tmp');
      twoFolders = TempFilesDatasource(
        folders: () async => <Directory>[temp, nativeTemp],
      );
    });

    tearDown(() => nativeTemp.deleteSync(recursive: true));

    test(
      'delete removes a part or result the native side wrote there',
      () async {
        final File part = touch(nativeTemp, 'part_1.mp4');

        await twoFolders.delete(part.path);

        expect(part.existsSync(), isFalse);
      },
    );

    test('delete still never touches a file outside both folders', () async {
      final File original = touch(outside, 'holiday.mp4');

      await twoFolders.delete(original.path);

      expect(original.existsSync(), isTrue);
    });

    test('leftovers go from both folders', () async {
      final DateTime start = DateTime.now();
      final DateTime old = start.subtract(const Duration(minutes: 5));
      final File cached = touch(temp, 'muted_1.mp4', modified: old);
      final File part = touch(nativeTemp, 'part_1.mp4', modified: old);

      await twoFolders.deleteLeftovers(before: start);

      expect(cached.existsSync(), isFalse);
      expect(part.existsSync(), isFalse);
    });
  });
}
