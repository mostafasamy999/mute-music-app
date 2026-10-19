import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';

abstract interface class VideoRepository {
  /// Success with `null` means the user closed the picker without choosing.
  Future<DataState<VideoAsset?>> pickFromGallery();

  Future<DataState<VideoAsset>> removeSound(VideoAsset source);

  Future<DataState<void>> saveToGallery(VideoAsset video);

  /// Frees a file the app made and no longer shows. Best effort: never throws,
  /// and leaves files the app did not make alone.
  Future<void> discard(VideoAsset video);

  /// Frees files an earlier launch left behind, made before [before].
  /// Best effort: never throws.
  Future<void> discardLeftovers({required DateTime before});
}
