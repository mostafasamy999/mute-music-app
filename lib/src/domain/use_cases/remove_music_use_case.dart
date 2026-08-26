import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/domain/repositories/music_removal_repository.dart';

class RemoveMusicUseCase {
  const RemoveMusicUseCase(this._repository);

  final MusicRemovalRepository _repository;

  Future<DataState<VideoAsset>> call(
    VideoAsset source, {
    required void Function(double progress) onProgress,
  }) => _repository.removeMusic(source, onProgress: onProgress);
}
