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
import 'package:mute_music_app/src/data/local/separation_worker.dart';
import 'package:mute_music_app/src/data/repositories/music_removal_repository_impl.dart';
import 'package:mute_music_app/src/domain/entities/removal_progress.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';

class _MockPipeline extends Mock implements AudioPipelineDatasource {}

class _MockWorker extends Mock implements SeparationWorker {}

class _MockStorage extends Mock implements ModelStorage {}

/// The PCM files are tens of MB each, so no failure may leave them behind.
void main() {
  const VideoAsset source = VideoAsset(path: '/tmp/source.mp4');

  late Directory directory;
  late _MockPipeline pipeline;
  late _MockWorker worker;
  late MusicRemovalRepositoryImpl repository;

  setUpAll(
    () => registerFallbackValue(
      const SeparationJob(
        inputPcmPath: '',
        sampleRate: 0,
        channels: 0,
        modelPath: '',
        outputPcmPath: '',
      ),
    ),
  );

  setUp(() {
    directory = Directory.systemTemp.createTempSync('removal_test');
    pipeline = _MockPipeline();
    worker = _MockWorker();
    final _MockStorage storage = _MockStorage();
    when(storage.isReady).thenAnswer((_) async => true);
    when(
      storage.modelFile,
    ).thenAnswer((_) async => File('${directory.path}/model.onnx'));
    repository = MusicRemovalRepositoryImpl(pipeline, worker, storage);

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

  Future<void> Function(Invocation) writesVoice(int chunks) =>
      (Invocation call) async {
        final SeparationJob job =
            call.positionalArguments.first as SeparationJob;
        final ChunkCallback onChunk =
            call.namedArguments[#onChunk] as ChunkCallback;
        for (int done = 0; done <= chunks; done++) {
          onChunk(done, chunks);
        }
        File(job.outputPcmPath).writeAsBytesSync(<int>[0, 0, 0, 0]);
      };

  void workerReturns() => when(
    () => worker.run(any(), onChunk: any(named: 'onChunk')),
  ).thenAnswer(writesVoice(1));

  test('a worker that fails leaves no PCM files', () async {
    when(
      () => worker.run(any(), onChunk: any(named: 'onChunk')),
    ).thenThrow(const SeparationException('out of memory'));

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
    workerReturns();
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
    workerReturns();
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

  test('reports extract, every chunk, then build — in order', () async {
    when(
      () => worker.run(any(), onChunk: any(named: 'onChunk')),
    ).thenAnswer(writesVoice(2));
    final File video = File('${directory.path}/nomusic.mp4')
      ..writeAsBytesSync(<int>[1]);
    when(
      () => pipeline.mux(
        videoPath: any(named: 'videoPath'),
        pcmPath: any(named: 'pcmPath'),
      ),
    ).thenAnswer((_) async => video.path);
    final List<RemovalProgress> steps = <RemovalProgress>[];

    await repository.removeMusic(source, onProgress: steps.add);

    expect(steps, const <RemovalProgress>[
      RemovalProgress(RemovalStep.extract),
      RemovalProgress(RemovalStep.separate, total: 2),
      RemovalProgress(RemovalStep.separate, done: 1, total: 2),
      RemovalProgress(RemovalStep.separate, done: 2, total: 2),
      RemovalProgress(RemovalStep.build),
    ]);
  });

  test(
    'passes the extracted format and both PCM paths to the worker',
    () async {
      workerReturns();
      when(
        () => pipeline.mux(
          videoPath: any(named: 'videoPath'),
          pcmPath: any(named: 'pcmPath'),
        ),
      ).thenThrow(PlatformException(code: 'mux_failed'));

      await repository.removeMusic(source, onProgress: (_) {});

      final SeparationJob job =
          verify(
                () => worker.run(captureAny(), onChunk: any(named: 'onChunk')),
              ).captured.single
              as SeparationJob;
      expect(job.inputPcmPath, '${directory.path}/audio.pcm');
      expect(job.outputPcmPath, '${directory.path}/audio.pcm.voice.pcm');
      expect(job.sampleRate, PcmIo.targetRate);
      expect(job.channels, 2);
      expect(job.modelPath, '${directory.path}/model.onnx');
    },
  );
}
