import 'package:mute_music_app/src/domain/repositories/video_repository.dart';

class DiscardLeftoversUseCase {
  const DiscardLeftoversUseCase(this._repository);

  final VideoRepository _repository;

  Future<void> call() => _repository.discardLeftovers(before: DateTime.now());
}
