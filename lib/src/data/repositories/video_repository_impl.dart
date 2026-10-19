import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/data/local/temp_files_datasource.dart';
import 'package:mute_music_app/src/data/local/video_mute_datasource.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/domain/repositories/video_repository.dart';

class VideoRepositoryImpl implements VideoRepository {
  const VideoRepositoryImpl(this._picker, this._datasource, this._tempFiles);

  final ImagePicker _picker;
  final VideoMuteDatasource _datasource;
  final TempFilesDatasource _tempFiles;

  @override
  Future<DataState<VideoAsset?>> pickFromGallery() async {
    try {
      final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file == null) return const DataSuccess<VideoAsset?>(null);
      return DataSuccess<VideoAsset?>(_toAsset(file.path));
    } on Object {
      return const DataFailed<VideoAsset?>(AppFailure.pickFailed);
    }
  }

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

  VideoAsset _toAsset(String path) {
    final File file = File(path);
    return VideoAsset(
      path: path,
      sizeInBytes: file.existsSync() ? file.lengthSync() : null,
    );
  }
}
