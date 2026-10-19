import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/removal_progress.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';

abstract interface class MusicRemovalRepository {
  /// Keeps the voices and drops the background music. Slow — [onProgress]
  /// reports each step, and each chunk while separating.
  Future<DataState<VideoAsset>> removeMusic(
    VideoAsset source, {
    required void Function(RemovalProgress progress) onProgress,
  });
}
