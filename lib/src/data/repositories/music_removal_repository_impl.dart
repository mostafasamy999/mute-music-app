import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mute_music_app/src/core/audio/pcm_io.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/data/local/audio_pipeline_datasource.dart';
import 'package:mute_music_app/src/data/local/model_storage.dart';
import 'package:mute_music_app/src/data/local/music_separator.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/domain/repositories/music_removal_repository.dart';

class MusicRemovalRepositoryImpl implements MusicRemovalRepository {
  const MusicRemovalRepositoryImpl(
    this._pipeline,
    this._separator,
    this._storage,
  );

  final AudioPipelineDatasource _pipeline;
  final MusicSeparator _separator;
  final ModelStorage _storage;

  @override
  Future<DataState<VideoAsset>> removeMusic(
    VideoAsset source, {
    required void Function(double progress) onProgress,
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
    void Function(double) onProgress,
  ) async {
    final ExtractedAudio audio = await _pipeline.extract(source.path);
    final File pcm = File(audio.path);
    final File out = File('${audio.path}.voice.pcm');
    // Each PCM file is tens of MB, so they go on every path, not just success.
    try {
      final StereoAudio input = PcmIo.read(
        pcm,
        audio.sampleRate,
        audio.channels,
      );

      final StereoAudio voice = await _separator.separate(
        modelPath: (await _storage.modelFile()).path,
        input: input,
        onProgress: onProgress,
      );

      PcmIo.write(out, voice.left, voice.right);
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
