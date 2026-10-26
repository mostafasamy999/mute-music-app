import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/media_asset.dart';
import 'package:mute_music_app/src/domain/repositories/video_repository.dart';

class PickMediaUseCase {
  const PickMediaUseCase(this._repository);

  final VideoRepository _repository;

  /// Video by default, the only kind before spec 006.
  Future<DataState<MediaAsset?>> call([MediaKind kind = MediaKind.video]) =>
      _repository.pick(kind);
}
