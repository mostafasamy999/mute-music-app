import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/data/local/audio_file_datasource.dart';
import 'package:mute_music_app/src/data/local/temp_files_datasource.dart';
import 'package:mute_music_app/src/data/local/video_mute_datasource.dart';
import 'package:mute_music_app/src/domain/entities/clip_range.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/domain/repositories/video_repository.dart';

class VideoRepositoryImpl implements VideoRepository {
  const VideoRepositoryImpl(
    this._picker,
    this._datasource,
    this._tempFiles,
    this._audioFiles,
  );

  final ImagePicker _picker;
  final VideoMuteDatasource _datasource;
  final TempFilesDatasource _tempFiles;
  final AudioFileDatasource _audioFiles;

  @override
  Future<DataState<MediaAsset?>> pick(MediaKind kind) async {
    try {
      final String? path = await _pickPath(kind);
      if (path == null) return const DataSuccess<MediaAsset?>(null);
      // An image has no length; sound and video do.
      final Duration? duration = kind == MediaKind.image
          ? null
          : await _durationOf(path);
      return DataSuccess<MediaAsset?>(
        _toAsset(path, kind: kind, duration: duration),
      );
    } on Object {
      return const DataFailed<MediaAsset?>(AppFailure.pickFailed);
    }
  }

  Future<String?> _pickPath(MediaKind kind) async => switch (kind) {
    MediaKind.video => (await _picker.pickVideo(
      source: ImageSource.gallery,
    ))?.path,
    MediaKind.image => (await _picker.pickImage(
      source: ImageSource.gallery,
    ))?.path,
    MediaKind.audio => await _audioFiles.pick(),
  };

  @override
  Future<DataState<VideoAsset>> removeSound(VideoAsset source) async {
    try {
      final String output = await _datasource.removeSound(source.path);
      return DataSuccess<VideoAsset>(_toAsset(output));
    } on PlatformException catch (error) {
      return DataFailed<VideoAsset>(_muteFailure(error.code));
    } on Object {
      return const DataFailed<VideoAsset>(AppFailure.muteFailed);
    }
  }

  @override
  Future<DataState<VideoAsset>> cut(
    VideoAsset original,
    ClipRange range,
  ) async {
    try {
      // A sound file gets its own native cut into an .m4a (spec 006 F3).
      final ({String path, int startMs, int endMs}) part = original.isAudio
          ? await _datasource.cutAudio(
              original.path,
              startMs: range.start.inMilliseconds,
              endMs: range.end.inMilliseconds,
            )
          : await _datasource.cutVideo(
              original.path,
              startMs: range.start.inMilliseconds,
              endMs: range.end.inMilliseconds,
            );
      final ClipRange real = ClipRange(
        start: Duration(milliseconds: part.startMs),
        end: Duration(milliseconds: part.endMs),
      );
      return DataSuccess<VideoAsset>(
        _toAsset(
          part.path,
          kind: original.kind,
          duration: real.length,
          range: real,
        ),
      );
    } on PlatformException catch (error) {
      return DataFailed<VideoAsset>(switch (error.code) {
        'no_video_track' => AppFailure.noVideoTrack,
        'no_audio_track' => AppFailure.noAudioTrack,
        _ => AppFailure.cutFailed,
      });
    } on Object {
      // Includes a native range the ClipRange rejects.
      return const DataFailed<VideoAsset>(AppFailure.cutFailed);
    }
  }

  @override
  Future<DataState<MediaAsset>> convertToAudio(MediaAsset video) async {
    try {
      final String path = await _datasource.exportAudio(video.path);
      return DataSuccess<MediaAsset>(
        _toAsset(
          path,
          kind: MediaKind.audio,
          duration: await _durationOf(path),
        ),
      );
    } on PlatformException catch (error) {
      return DataFailed<MediaAsset>(
        error.code == 'no_audio_track'
            ? AppFailure.noAudioTrack
            : AppFailure.convertFailed,
      );
    } on Object {
      return const DataFailed<MediaAsset>(AppFailure.convertFailed);
    }
  }

  @override
  Future<DataState<void>> saveToGallery(VideoAsset video) async {
    try {
      await Gal.putVideo(video.path, album: 'Mute Video');
      return const DataSuccess<void>(null);
    } on GalException catch (error) {
      return DataFailed<void>(
        error.type == GalExceptionType.accessDenied
            ? AppFailure.permissionDenied
            : AppFailure.saveFailed,
      );
    } on Object {
      return const DataFailed<void>(AppFailure.saveFailed);
    }
  }

  @override
  Future<void> discard(VideoAsset video) async {
    try {
      await _tempFiles.delete(video.path);
    } on Object {
      // A file that cannot be deleted now goes on the next launch.
    }
  }

  @override
  Future<void> discardLeftovers({required DateTime before}) async {
    try {
      await _tempFiles.deleteLeftovers(before: before);
    } on Object {
      // Nothing depends on this; the next launch tries again.
    }
  }

  AppFailure _muteFailure(String code) => code == 'no_video_track'
      ? AppFailure.noVideoTrack
      : AppFailure.muteFailed;

  /// Best effort: an unknown length only turns off the Remove music limit.
  Future<Duration?> _durationOf(String path) async {
    try {
      final int? ms = await _datasource.durationMs(path);
      return ms == null || ms <= 0 ? null : Duration(milliseconds: ms);
    } on Object {
      return null;
    }
  }

  VideoAsset _toAsset(
    String path, {
    MediaKind kind = MediaKind.video,
    Duration? duration,
    ClipRange? range,
  }) {
    final File file = File(path);
    return VideoAsset(
      path: path,
      kind: kind,
      sizeInBytes: file.existsSync() ? file.lengthSync() : null,
      duration: duration,
      range: range,
    );
  }
}
