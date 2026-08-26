import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/repositories/separation_model_repository.dart';

class EnsureModelReadyUseCase {
  const EnsureModelReadyUseCase(this._repository);

  final SeparationModelRepository _repository;

  Future<DataState<void>> call({
    required void Function(double progress) onProgress,
  }) => _repository.ensureDownloaded(onProgress: onProgress);
}
