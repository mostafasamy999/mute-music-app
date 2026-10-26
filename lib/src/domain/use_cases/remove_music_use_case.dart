import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/removal_progress.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/domain/repositories/music_removal_repository.dart';

class RemoveMusicUseCase {
  const RemoveMusicUseCase(this._repository, this._soundRepository);

  /// Videos: the original pipeline, unchanged (spec 006 §0).
  final MusicRemovalRepository _repository;

  /// Sound files: the same separation, written to an .m4a (spec 006 F6).
  final MusicRemovalRepository _soundRepository;

  Future<DataState<VideoAsset>> call(
    VideoAsset source, {
    required void Function(RemovalProgress progress) onProgress,
  }) => (source.isAudio ? _soundRepository : _repository).removeMusic(
    source,
    onProgress: onProgress,
  );
}
