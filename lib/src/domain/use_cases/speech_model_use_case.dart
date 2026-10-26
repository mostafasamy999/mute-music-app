import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/repositories/speech_model_repository.dart';

/// Whether the speech model is there, and downloading it (spec 006 S14).
class SpeechModelUseCase {
  const SpeechModelUseCase(this._repository);

  final SpeechModelRepository _repository;

  Future<bool> isReady() => _repository.isReady();

  Future<DataState<void>> download({
    required void Function(double progress) onProgress,
  }) => _repository.download(onProgress: onProgress);
}
