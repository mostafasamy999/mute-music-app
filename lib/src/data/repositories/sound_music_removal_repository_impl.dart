import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/data/local/audio_pipeline_datasource.dart';
import 'package:mute_music_app/src/data/local/model_storage.dart';
import 'package:mute_music_app/src/data/local/separation_worker.dart';
import 'package:mute_music_app/src/data/local/video_mute_datasource.dart';
import 'package:mute_music_app/src/domain/entities/removal_progress.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/domain/repositories/music_removal_repository.dart';

/// Remove music only on a sound file (spec 006 F6).
///
/// The same extract and separation as [MusicRemovalRepositoryImpl] (the
/// existing native extract and [SeparationWorker], called, not changed). Only
/// the last step differs: with no video to put the voices back into, they are
/// encoded into a new .m4a by the new native `encodeVoices`. The video
/// pipeline stays exactly as it was (spec 006 §0).
class SoundMusicRemovalRepositoryImpl implements MusicRemovalRepository {
  const SoundMusicRemovalRepositoryImpl(
    this._pipeline,
    this._worker,
    this._storage,
    this._encoder,
  );

  final AudioPipelineDatasource _pipeline;
  final SeparationWorker _worker;
  final ModelStorage _storage;
  final VideoMuteDatasource _encoder;

  /// The worker always writes 44.1 kHz stereo (spec 001 §8).
  static const int _sampleRate = 44100;
  static const int _channels = 2;

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
      return DataFailed<VideoAsset>(
        error.code == 'no_audio_track'
            ? AppFailure.noAudioTrack
            : AppFailure.musicRemovalFailed,
      );
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
      final String sound = await _encoder.encodeVoices(
        out.path,
        sampleRate: _sampleRate,
        channels: _channels,
      );
      return MediaAsset(
        path: sound,
        kind: MediaKind.audio,
        sizeInBytes: File(sound).lengthSync(),
        duration: source.duration,
      );
    } finally {
      for (final File file in <File>[pcm, out]) {
        if (file.existsSync()) file.deleteSync();
      }
    }
  }
}
