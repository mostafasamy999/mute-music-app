import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/data/local/audio_pipeline_datasource.dart';
import 'package:mute_music_app/src/data/local/speech_audio.dart';
import 'package:mute_music_app/src/data/local/speech_datasource.dart';
import 'package:mute_music_app/src/data/local/video_mute_datasource.dart';
import 'package:mute_music_app/src/domain/entities/media_asset.dart';
import 'package:mute_music_app/src/domain/repositories/text_repository.dart';

class TextRepositoryImpl implements TextRepository {
  const TextRepositoryImpl(this._ocr, this._pipeline, this._speech);

  final VideoMuteDatasource _ocr;

  /// The existing native extract (called, not changed: spec 006 §0).
  final AudioPipelineDatasource _pipeline;
  final SpeechDatasource _speech;

  @override
  Future<DataState<String>> extractText(
    MediaAsset file, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final String text = file.isImage
          ? await _ocr.recognizeText(file.path)
          : await _transcribe(file, onProgress ?? (_) {});
      return text.trim().isEmpty
          ? const DataFailed<String>(AppFailure.noTextFound)
          : DataSuccess<String>(text.trim());
    } on _NoModel {
      return const DataFailed<String>(AppFailure.speechModelMissing);
    } on PlatformException catch (error) {
      return DataFailed<String>(
        error.code == 'no_audio_track'
            ? AppFailure.noAudioTrack
            : AppFailure.extractFailed,
      );
    } on Object {
      return const DataFailed<String>(AppFailure.extractFailed);
    }
  }

  Future<String> _transcribe(
    MediaAsset file,
    void Function(double) onProgress,
  ) async {
    final String? model = await _speech.readyModelPath();
    if (model == null) throw const _NoModel();
    final ExtractedAudio audio = await _pipeline.extract(file.path);
    final File pcm = File(audio.path);
    final Float32List samples;
    // The extracted PCM is tens of MB: it goes on every path.
    try {
      samples = await SpeechAudio.load(
        pcm.path,
        sampleRate: audio.sampleRate,
        channels: audio.channels,
      );
    } finally {
      if (pcm.existsSync()) pcm.deleteSync();
    }
    return _speech.transcribe(model, samples, onProgress: onProgress);
  }
}

class _NoModel implements Exception {
  const _NoModel();
}
