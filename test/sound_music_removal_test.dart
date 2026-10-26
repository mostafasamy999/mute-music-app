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
import 'package:mute_music_app/src/data/local/video_mute_datasource.dart';
import 'package:mute_music_app/src/data/repositories/sound_music_removal_repository_impl.dart';
import 'package:mute_music_app/src/domain/entities/removal_progress.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/domain/repositories/music_removal_repository.dart';
import 'package:mute_music_app/src/domain/use_cases/remove_music_use_case.dart';

class _MockPipeline extends Mock implements AudioPipelineDatasource {}

class _MockWorker extends Mock implements SeparationWorker {}

class _MockStorage extends Mock implements ModelStorage {}

class _MockEncoder extends Mock implements VideoMuteDatasource {}

class _MockRemoval extends Mock implements MusicRemovalRepository {}

/// Spec 006 S13: Remove music only on a sound file. Same extract and
/// separation as the video pipeline; the voices are encoded into an .m4a.
void main() {
  const MediaAsset sound = MediaAsset(
    path: '/tmp/song.mp3',
    kind: MediaKind.audio,
    duration: Duration(seconds: 30),
  );

  setUpAll(() {
    registerFallbackValue(
      const SeparationJob(
        inputPcmPath: '',
        sampleRate: 0,
        channels: 0,
        modelPath: '',
        outputPcmPath: '',
      ),
    );
    registerFallbackValue(sound);
  });

  group('repository', () {
    late Directory directory;
    late _MockPipeline pipeline;
    late _MockWorker worker;
    late _MockStorage storage;
    late _MockEncoder encoder;
    late SoundMusicRemovalRepositoryImpl repository;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('sound_removal');
      pipeline = _MockPipeline();
      worker = _MockWorker();
      storage = _MockStorage();
      encoder = _MockEncoder();
      when(storage.isReady).thenAnswer((_) async => true);
      when(
        storage.modelFile,
      ).thenAnswer((_) async => File('${directory.path}/model.onnx'));
      repository = SoundMusicRemovalRepositoryImpl(
        pipeline,
        worker,
        storage,
        encoder,
      );
      final File pcm = File('${directory.path}/audio.pcm');
      PcmIo.write(
        pcm,
        Float64List(PcmIo.targetRate),
        Float64List(PcmIo.targetRate),
      );
      when(() => pipeline.extract(sound.path)).thenAnswer(
        (_) async => ExtractedAudio(
          path: pcm.path,
          sampleRate: PcmIo.targetRate,
          channels: 2,
        ),
      );
      when(() => worker.run(any(), onChunk: any(named: 'onChunk'))).thenAnswer((
        Invocation call,
      ) async {
        final SeparationJob job =
            call.positionalArguments.first as SeparationJob;
        final ChunkCallback onChunk =
            call.namedArguments[#onChunk] as ChunkCallback;
        onChunk(0, 1);
        onChunk(1, 1);
        File(job.outputPcmPath).writeAsBytesSync(<int>[0, 0, 0, 0]);
      });
    });

    tearDown(() => directory.deleteSync(recursive: true));

    List<String> pcmFiles() => directory
        .listSync()
        .map((FileSystemEntity e) => e.path)
        .where((String path) => path.endsWith('.pcm'))
        .toList();

    test('extracts, separates, encodes the voices into a sound file', () async {
      final File m4a = File('${directory.path}/nomusic_1.m4a')
        ..writeAsBytesSync(<int>[1, 2, 3]);
      when(
        () => encoder.encodeVoices(any(), sampleRate: 44100, channels: 2),
      ).thenAnswer((_) async => m4a.path);
      final List<RemovalStep> steps = <RemovalStep>[];

      final MediaAsset result =
          (await repository.removeMusic(
                    sound,
                    onProgress: (RemovalProgress p) => steps.add(p.step),
                  )
                  as DataSuccess<VideoAsset>)
              .data;

      expect(result.kind, MediaKind.audio);
      expect(result.path, m4a.path);
      expect(result.duration, sound.duration);
      expect(steps.first, RemovalStep.extract);
      expect(steps, contains(RemovalStep.separate));
      expect(steps.last, RemovalStep.build);
      expect(pcmFiles(), isEmpty);
    });

    test('a failed encode fails cleanly and leaves no PCM', () async {
      when(
        () => encoder.encodeVoices(
          any(),
          sampleRate: any(named: 'sampleRate'),
          channels: any(named: 'channels'),
        ),
      ).thenThrow(PlatformException(code: 'encode_failed'));

      final DataState<VideoAsset> result = await repository.removeMusic(
        sound,
        onProgress: (_) {},
      );

      expect(
        (result as DataFailed<VideoAsset>).failure,
        AppFailure.musicRemovalFailed,
      );
      expect(pcmFiles(), isEmpty);
    });

    test('a file with no sound maps to noAudioTrack', () async {
      when(
        () => pipeline.extract(any()),
      ).thenThrow(PlatformException(code: 'no_audio_track'));

      expect(
        (await repository.removeMusic(sound, onProgress: (_) {})
                as DataFailed<VideoAsset>)
            .failure,
        AppFailure.noAudioTrack,
      );
    });

    test('no model is modelMissing, and nothing runs', () async {
      when(storage.isReady).thenAnswer((_) async => false);

      expect(
        (await repository.removeMusic(sound, onProgress: (_) {})
                as DataFailed<VideoAsset>)
            .failure,
        AppFailure.modelMissing,
      );
      verifyNever(() => pipeline.extract(any()));
    });
  });

  group('use case', () {
    late _MockRemoval video;
    late _MockRemoval audio;
    late RemoveMusicUseCase useCase;

    setUp(() {
      video = _MockRemoval();
      audio = _MockRemoval();
      useCase = RemoveMusicUseCase(video, audio);
      for (final _MockRemoval repo in <_MockRemoval>[video, audio]) {
        when(
          () => repo.removeMusic(any(), onProgress: any(named: 'onProgress')),
        ).thenAnswer(
          (_) async => const DataFailed<VideoAsset>(AppFailure.modelMissing),
        );
      }
    });

    test('a sound file goes to the sound pipeline', () async {
      await useCase(sound, onProgress: (_) {});

      verify(
        () => audio.removeMusic(sound, onProgress: any(named: 'onProgress')),
      ).called(1);
      verifyNever(
        () => video.removeMusic(any(), onProgress: any(named: 'onProgress')),
      );
    });

    test('a video still goes to the original pipeline (VIP)', () async {
      const VideoAsset clip = VideoAsset(path: '/tmp/clip.mp4');

      await useCase(clip, onProgress: (_) {});

      verify(
        () => video.removeMusic(clip, onProgress: any(named: 'onProgress')),
      ).called(1);
      verifyNever(
        () => audio.removeMusic(any(), onProgress: any(named: 'onProgress')),
      );
    });
  });
}
