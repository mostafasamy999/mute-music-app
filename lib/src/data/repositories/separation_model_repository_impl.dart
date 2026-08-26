import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mute_music_app/src/core/constants/model_constants.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/data/local/model_storage.dart';
import 'package:mute_music_app/src/data/remote/model_download_service.dart';
import 'package:mute_music_app/src/domain/repositories/separation_model_repository.dart';

class SeparationModelRepositoryImpl implements SeparationModelRepository {
  const SeparationModelRepositoryImpl(this._storage, this._service);

  final ModelStorage _storage;
  final ModelDownloadService _service;

  @override
  Future<bool> isReady() => _storage.isReady();

  @override
  Future<DataState<void>> ensureDownloaded({
    required void Function(double progress) onProgress,
  }) async {
    if (await _storage.isReady()) return const DataSuccess<void>(null);
    try {
      await _storage.deleteBrokenFiles();
      final File partial = await _storage.partialFile();
      await _service.download(
        url: ModelConstants.vocalsModelUrl,
        target: partial,
        onProgress: onProgress,
      );
      return _promote(partial);
    } on DioException {
      await _storage.deleteBrokenFiles();
      return const DataFailed<void>(AppFailure.modelDownloadFailed);
    }
  }

  /// The file is renamed only once every byte arrived, so a killed download can
  /// never be mistaken for a ready model on the next launch.
  Future<DataState<void>> _promote(File partial) async {
    if (!partial.existsSync() ||
        partial.lengthSync() != ModelConstants.vocalsModelSizeInBytes) {
      await _storage.deleteBrokenFiles();
      return const DataFailed<void>(AppFailure.modelDownloadFailed);
    }
    final File target = await _storage.modelFile();
    await partial.rename(target.path);
    return const DataSuccess<void>(null);
  }
}
