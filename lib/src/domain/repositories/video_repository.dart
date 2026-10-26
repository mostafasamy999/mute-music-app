import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/clip_range.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';

abstract interface class VideoRepository {
  /// Picks one file of [kind] (spec 006 F1). Success with `null` means the
  /// user closed the picker without choosing.
  Future<DataState<MediaAsset?>> pick(MediaKind kind);

  Future<DataState<VideoAsset>> removeSound(VideoAsset source);

  /// Copies [range] of [original] into a new file. The part's [VideoAsset.range]
  /// is the range it really covers, which can start a little earlier (it has
  /// to start on a keyframe).
  Future<DataState<VideoAsset>> cut(VideoAsset original, ClipRange range);

  /// Writes the audio of [video] into a new .m4a sound file (spec 006 F7).
  Future<DataState<MediaAsset>> convertToAudio(MediaAsset video);

  Future<DataState<void>> saveToGallery(VideoAsset video);

  /// Frees a file the app made and no longer shows. Best effort: never throws,
  /// and leaves files the app did not make alone.
  Future<void> discard(VideoAsset video);

  /// Frees files an earlier launch left behind, made before [before].
  /// Best effort: never throws.
  Future<void> discardLeftovers({required DateTime before});
}
