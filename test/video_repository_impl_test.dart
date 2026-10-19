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
}
