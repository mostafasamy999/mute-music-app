import 'package:mute_music_app/src/core/resources/data_state.dart';

abstract interface class SeparationModelRepository {
  Future<bool> isReady();

  /// Downloads the model if it is missing. [onProgress] gets 0.0 to 1.0.
  Future<DataState<void>> ensureDownloaded({
    required void Function(double progress) onProgress,
  });
}
