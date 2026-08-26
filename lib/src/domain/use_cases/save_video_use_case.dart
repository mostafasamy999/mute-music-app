import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/domain/repositories/video_repository.dart';

class SaveVideoUseCase {
  const SaveVideoUseCase(this._repository);

  final VideoRepository _repository;

  Future<DataState<void>> call(VideoAsset video) =>
      _repository.saveToGallery(video);
}
