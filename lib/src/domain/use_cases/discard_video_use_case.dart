import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/domain/repositories/video_repository.dart';

class DiscardVideoUseCase {
  const DiscardVideoUseCase(this._repository);

  final VideoRepository _repository;

  Future<void> call(VideoAsset video) => _repository.discard(video);
}
