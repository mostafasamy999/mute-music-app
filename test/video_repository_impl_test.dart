import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/data/local/temp_files_datasource.dart';
import 'package:mute_music_app/src/data/local/video_mute_datasource.dart';
import 'package:mute_music_app/src/data/repositories/video_repository_impl.dart';
import 'package:mute_music_app/src/domain/entities/clip_range.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';

class _MockPicker extends Mock implements ImagePicker {}

class _MockDatasource extends Mock implements VideoMuteDatasource {}

class _MockTempFiles extends Mock implements TempFilesDatasource {}

void main() {
  const VideoAsset source = VideoAsset(path: '/tmp/source.mp4');

  late _MockPicker picker;
  late _MockDatasource datasource;
  late _MockTempFiles tempFiles;
  late VideoRepositoryImpl repository;

  setUp(() {
    picker = _MockPicker();
    datasource = _MockDatasource();
    tempFiles = _MockTempFiles();
    repository = VideoRepositoryImpl(picker, datasource, tempFiles);
  });

  test(
    'a picker that is not a PlatformException still fails cleanly',
    () async {
      when(
        () => picker.pickVideo(source: ImageSource.gallery),
      ).thenThrow(MissingPluginException());

      final DataState<VideoAsset?> result = await repository.pickFromGallery();

      expect(
        (result as DataFailed<VideoAsset?>).failure,
        AppFailure.pickFailed,
      );
    },
  );

  test('a native no_video_track code maps to noVideoTrack', () async {
    when(
      () => datasource.removeSound(source.path),
    ).thenThrow(PlatformException(code: 'no_video_track'));

    final DataState<VideoAsset> result = await repository.removeSound(source);

    expect((result as DataFailed<VideoAsset>).failure, AppFailure.noVideoTrack);
  });

  test('a missing native handler fails as muteFailed', () async {
    when(
      () => datasource.removeSound(source.path),
    ).thenThrow(MissingPluginException());

    final DataState<VideoAsset> result = await repository.removeSound(source);

    expect((result as DataFailed<VideoAsset>).failure, AppFailure.muteFailed);
  });

  test('discard never throws, even when the delete does', () async {
    when(
      () => tempFiles.delete(source.path),
    ).thenThrow(const FileSystemException('busy'));

    await expectLater(repository.discard(source), completes);
  });

  group('cut', () {
    final ClipRange asked = ClipRange(
      start: const Duration(seconds: 60),
      end: const Duration(seconds: 120),
    );

    Future<DataState<VideoAsset>> cutWith() => repository.cut(source, asked);

    test('returns the part with the range it really covers', () async {
      when(
        () => datasource.cutVideo(source.path, startMs: 60000, endMs: 120000),
      ).thenAnswer(
        (_) async => (path: '/tmp/part_1.mp4', startMs: 58800, endMs: 120000),
      );

      final VideoAsset part = (await cutWith() as DataSuccess<VideoAsset>).data;

      expect(part.path, '/tmp/part_1.mp4');
      expect(part.range!.start, const Duration(milliseconds: 58800));
      expect(part.range!.end, const Duration(seconds: 120));
      expect(part.duration, const Duration(milliseconds: 61200));
    });

    for (final (String code, AppFailure failure) in <(String, AppFailure)>[
      ('no_video_track', AppFailure.noVideoTrack),
      ('bad_range', AppFailure.cutFailed),
      ('cut_failed', AppFailure.cutFailed),
    ]) {
      test('a native $code maps to ${failure.name}', () async {
        when(
          () => datasource.cutVideo(
            any(),
            startMs: any(named: 'startMs'),
            endMs: any(named: 'endMs'),
          ),
        ).thenThrow(PlatformException(code: code));

        expect((await cutWith() as DataFailed<VideoAsset>).failure, failure);
      });
    }

    test('anything else fails as cutFailed and never throws', () async {
      when(
        () => datasource.cutVideo(
          any(),
          startMs: any(named: 'startMs'),
          endMs: any(named: 'endMs'),
        ),
      ).thenThrow(MissingPluginException());

      expect(
        (await cutWith() as DataFailed<VideoAsset>).failure,
        AppFailure.cutFailed,
      );
    });
  });

  test(
    'a pick reads the length, and a failed read leaves it unknown',
    () async {
      when(
        () => picker.pickVideo(source: ImageSource.gallery),
      ).thenAnswer((_) async => XFile(source.path));
      when(
        () => datasource.durationMs(source.path),
      ).thenAnswer((_) async => 90500);

      final VideoAsset picked =
          (await repository.pickFromGallery() as DataSuccess<VideoAsset?>)
              .data!;
      expect(picked.duration, const Duration(milliseconds: 90500));

      when(
        () => datasource.durationMs(source.path),
      ).thenThrow(MissingPluginException());
      final VideoAsset unknown =
          (await repository.pickFromGallery() as DataSuccess<VideoAsset?>)
              .data!;
      expect(unknown.duration, isNull);
    },
  );
}
