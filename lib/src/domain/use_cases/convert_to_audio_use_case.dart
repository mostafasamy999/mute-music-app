import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/media_asset.dart';
import 'package:mute_music_app/src/domain/repositories/video_repository.dart';

class ConvertToAudioUseCase {
  const ConvertToAudioUseCase(this._repository);

  final VideoRepository _repository;

  Future<DataState<MediaAsset>> call(MediaAsset video) =>
      _repository.convertToAudio(video);
}
