import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/clip_range.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/domain/repositories/video_repository.dart';

class CutVideoUseCase {
  const CutVideoUseCase(this._repository);

  final VideoRepository _repository;

  Future<DataState<VideoAsset>> call(VideoAsset original, ClipRange range) =>
      _repository.cut(original, range);
}
