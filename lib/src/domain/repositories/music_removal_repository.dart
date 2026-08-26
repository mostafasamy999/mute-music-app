import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';

abstract interface class MusicRemovalRepository {
  /// Keeps the voices and drops the background music. Slow — [onProgress]
  /// reports 0.0 to 1.0 so the screen can show it.
  Future<DataState<VideoAsset>> removeMusic(
    VideoAsset source, {
    required void Function(double progress) onProgress,
  });
}
