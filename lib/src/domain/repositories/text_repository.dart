import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/media_asset.dart';

abstract interface class TextRepository {
  /// The text in [file], read offline (spec 006 F8): the words in an image,
  /// or the words spoken in a sound or video. Empty text is a
  /// [AppFailure.noTextFound]. [onProgress] (0.0 to 1.0) reports speech only.
  Future<DataState<String>> extractText(
    MediaAsset file, {
    void Function(double progress)? onProgress,
  });
}
