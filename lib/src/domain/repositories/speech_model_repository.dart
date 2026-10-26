import 'package:mute_music_app/src/core/resources/data_state.dart';

/// The offline speech-to-text model (spec 006 S14): about 148 MB, downloaded
/// once after the user agrees, checked against its SHA-256.
abstract interface class SpeechModelRepository {
  Future<bool> isReady();

  /// [onProgress] gets 0.0 to 1.0.
  Future<DataState<void>> download({
    required void Function(double progress) onProgress,
  });
}
