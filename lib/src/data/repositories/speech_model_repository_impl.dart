import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/data/local/speech_datasource.dart';
import 'package:mute_music_app/src/domain/repositories/speech_model_repository.dart';

class SpeechModelRepositoryImpl implements SpeechModelRepository {
  const SpeechModelRepositoryImpl(this._speech);

  final SpeechDatasource _speech;

  @override
  Future<bool> isReady() async {
    try {
      return await _speech.readyModelPath() != null;
    } on Object {
      return false;
    }
  }

  @override
  Future<DataState<void>> download({
    required void Function(double progress) onProgress,
  }) async {
    try {
      await _speech.download(onProgress: onProgress);
      return await _speech.readyModelPath() == null
          ? const DataFailed<void>(AppFailure.speechModelDownloadFailed)
          : const DataSuccess<void>(null);
    } on Object {
      return const DataFailed<void>(AppFailure.speechModelDownloadFailed);
    }
  }
}
