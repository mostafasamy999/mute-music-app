import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/data/local/audio_pipeline_datasource.dart';
import 'package:mute_music_app/src/data/local/model_storage.dart';
import 'package:mute_music_app/src/data/local/separation_worker.dart';
import 'package:mute_music_app/src/domain/entities/removal_progress.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/domain/repositories/music_removal_repository.dart';

class MusicRemovalRepositoryImpl implements MusicRemovalRepository {
  const MusicRemovalRepositoryImpl(this._pipeline, this._worker, this._storage);

  final AudioPipelineDatasource _pipeline;
  final SeparationWorker _worker;
  final ModelStorage _storage;

  @override
  Future<DataState<VideoAsset>> removeMusic(
    VideoAsset source, {
    required void Function(RemovalProgress progress) onProgress,
  }) async {
    if (!await _storage.isReady()) {
      return const DataFailed<VideoAsset>(AppFailure.modelMissing);
    }
    try {
      return DataSuccess<VideoAsset>(await _process(source, onProgress));
    } on PlatformException catch (error) {
      return DataFailed<VideoAsset>(_failureFor(error.code));
    } on Object {
      return const DataFailed<VideoAsset>(AppFailure.musicRemovalFailed);
    }
  }

  Future<VideoAsset> _process(
    VideoAsset source,
    void Function(RemovalProgress) onProgress,
  ) async {
    onProgress(const RemovalProgress(RemovalStep.extract));
    final ExtractedAudio audio = await _pipeline.extract(source.path);
    final File pcm = File(audio.path);
    final File out = File('${audio.path}.voice.pcm');
    // Each PCM file is tens of MB, so they go on every path, not just success.
    try {
      // Reading, separating and writing the PCM all happen off the UI
      // isolate; only chunk counts come back.
      await _worker.run(
        SeparationJob(
          inputPcmPath: pcm.path,
          sampleRate: audio.sampleRate,
          channels: audio.channels,
          modelPath: (await _storage.modelFile()).path,
          outputPcmPath: out.path,
        ),
        onChunk: (int done, int total) => onProgress(
          RemovalProgress(RemovalStep.separate, done: done, total: total),
        ),
      );

      onProgress(const RemovalProgress(RemovalStep.build));
      final String video = await _pipeline.mux(
        videoPath: source.path,
        pcmPath: out.path,
      );
      return VideoAsset(path: video, sizeInBytes: File(video).lengthSync());
    } finally {
      _cleanUp(<File>[pcm, out]);
    }
  }

  AppFailure _failureFor(String code) => switch (code) {
    'no_audio_track' => AppFailure.noAudioTrack,
    'no_video_track' => AppFailure.noVideoTrack,
    _ => AppFailure.musicRemovalFailed,
  };

  void _cleanUp(List<File> files) {
    for (final File file in files) {
      if (file.existsSync()) file.deleteSync();
    }
  }
}
