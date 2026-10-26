import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/media_asset.dart';
import 'package:mute_music_app/src/domain/repositories/video_repository.dart';

class SaveAudioUseCase {
  const SaveAudioUseCase(this._repository);

  final VideoRepository _repository;

  Future<DataState<void>> call(MediaAsset audio) =>
      _repository.saveToMusic(audio);
}
