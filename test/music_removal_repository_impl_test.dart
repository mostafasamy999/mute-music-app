import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mute_music_app/src/core/audio/pcm_io.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/data/local/audio_pipeline_datasource.dart';
import 'package:mute_music_app/src/data/local/model_storage.dart';
import 'package:mute_music_app/src/data/local/music_separator.dart';
import 'package:mute_music_app/src/data/repositories/music_removal_repository_impl.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';

class _MockPipeline extends Mock implements AudioPipelineDatasource {}

class _MockSeparator extends Mock implements MusicSeparator {}

class _MockStorage extends Mock implements ModelStorage {}

/// The PCM files are tens of MB each, so no failure may leave them behind.
void main() {
  const VideoAsset source = VideoAsset(path: '/tmp/source.mp4');

  late Directory directory;
  late _MockPipeline pipeline;
  late _MockSeparator separator;
  late MusicRemovalRepositoryImpl repository;

  setUpAll(
    () => registerFallbackValue(StereoAudio(Float64List(0), Float64List(0))),
  );

  setUp(() {
    directory = Directory.systemTemp.createTempSync('removal_test');
    pipeline = _MockPipeline();
    separator = _MockSeparator();
    final _MockStorage storage = _MockStorage();
    when(storage.isReady).thenAnswer((_) async => true);
    when(
      storage.modelFile,
    ).thenAnswer((_) async => File('${directory.path}/model.onnx'));
    repository = MusicRemovalRepositoryImpl(pipeline, separator, storage);

    // Extraction writes a real one-second stereo PCM file, like the platform.
    final File pcm = File('${directory.path}/audio.pcm');
    PcmIo.write(
      pcm,
      Float64List(PcmIo.targetRate),
      Float64List(PcmIo.targetRate),
    );
    when(() => pipeline.extract(source.path)).thenAnswer(
      (_) async => ExtractedAudio(
        path: pcm.path,
        sampleRate: PcmIo.targetRate,
        channels: 2,
      ),
    );
  });

  tearDown(() => directory.deleteSync(recursive: true));

  List<String> pcmFiles() => directory
      .listSync()
      .map((FileSystemEntity entity) => entity.path)
      .where((String path) => path.endsWith('.pcm'))
      .toList();

  void separatorReturns() =>
      when(
        () => separator.separate(
          modelPath: any(named: 'modelPath'),
          input: any(named: 'input'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer(
        (Invocation call) async => call.namedArguments[#input] as StereoAudio,
      );

  test('a separator that throws leaves no PCM files', () async {
    when(
      () => separator.separate(
        modelPath: any(named: 'modelPath'),
        input: any(named: 'input'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenThrow(StateError('out of memory'));

    final DataState<VideoAsset> result = await repository.removeMusic(
      source,
      onProgress: (_) {},
    );

    expect(
      (result as DataFailed<VideoAsset>).failure,
      AppFailure.musicRemovalFailed,
    );
    expect(pcmFiles(), isEmpty);
  });

  test('a mux that fails leaves no PCM files', () async {
    separatorReturns();
    when(
      () => pipeline.mux(
        videoPath: any(named: 'videoPath'),
        pcmPath: any(named: 'pcmPath'),
      ),
    ).thenThrow(PlatformException(code: 'no_video_track'));

    final DataState<VideoAsset> result = await repository.removeMusic(
      source,
      onProgress: (_) {},
    );

    expect((result as DataFailed<VideoAsset>).failure, AppFailure.noVideoTrack);
    expect(pcmFiles(), isEmpty);
  });

  test('a success returns the muxed video and leaves no PCM files', () async {
    separatorReturns();
    final File video = File('${directory.path}/nomusic.mp4')
      ..writeAsBytesSync(<int>[1, 2, 3]);
    when(
      () => pipeline.mux(
        videoPath: any(named: 'videoPath'),
        pcmPath: any(named: 'pcmPath'),
      ),
    ).thenAnswer((_) async => video.path);

    final DataState<VideoAsset> result = await repository.removeMusic(
      source,
      onProgress: (_) {},
    );

    expect(
      (result as DataSuccess<VideoAsset>).data,
      VideoAsset(path: video.path, sizeInBytes: 3),
    );
    expect(pcmFiles(), isEmpty);
  });
}
