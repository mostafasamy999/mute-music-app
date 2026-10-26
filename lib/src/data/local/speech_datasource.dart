import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:whisper_cpp_flutter_plus/whisper_cpp_flutter_plus.dart';

/// The model size shown before the download, in MB.
final String speechModelMegabytes =
    (SpeechDatasource.model.approximateBytes / 1000000).round().toString();

/// Offline speech to text with whisper.cpp (spec 006 F8, S14): the model
/// file and the transcription. Everything heavy runs off the UI isolate
/// inside the plugin.
class SpeechDatasource {
  SpeechDatasource({WhisperModelManager? models})
    : _models = models ?? WhisperModelManager();

  /// Multilingual `base` (about 148 MB): Arabic and English. `tiny` reads
  /// Arabic poorly; the catalog pins the file's revision and SHA-256.
  static const WhisperModelDescriptor model = WhisperModelCatalog.base;

  final WhisperModelManager _models;

  /// Metal on phones. The iOS simulator's Metal driver can't hold the model's
  /// 148 MB buffer and crashes the app, so the simulator runs on the CPU. The
  /// simulator passes no SIMULATOR_* variables to the app; its executable
  /// path (under CoreSimulator/Devices) is what gives it away.
  static WhisperBackend get _backend =>
      Platform.isIOS && Platform.resolvedExecutable.contains('/CoreSimulator/')
      ? WhisperBackend.cpu
      : WhisperBackend.automatic;

  /// The checked model file this session, so the SHA-256 (a few hundred ms
  /// on 148 MB) runs once.
  File? _verified;

  /// The model's path when it is downloaded and its SHA-256 matches; null
  /// otherwise. A file that doesn't match is deleted, so it downloads again.
  Future<String?> readyModelPath() async {
    final File? known = _verified;
    if (known != null && known.existsSync()) return known.path;
    try {
      final File? file = await _models.findCatalogModel(model);
      _verified = file;
      return file?.path;
    } on FormatException {
      await _models.delete(model.fileName);
      return null;
    }
  }

  /// Downloads the model once, resumable, checked against its SHA-256.
  Future<void> download({required void Function(double) onProgress}) async {
    await for (final ModelDownloadProgress progress
        in _models.downloadCatalogModel(model)) {
      final double? fraction = progress.fraction;
      if (fraction != null) onProgress(fraction);
    }
  }

  /// The text spoken in [pcm16k] (mono, 16 kHz). The language is detected.
  Future<String> transcribe(
    String modelPath,
    Float32List pcm16k, {
    required void Function(double) onProgress,
  }) async {
    final WhisperEngine engine = await WhisperEngine.load(
      modelPath,
      config: WhisperConfig(backend: _backend),
    );
    try {
      final WhisperTask task = engine.transcribe(pcm16k);
      final StreamSubscription<int> updates = task.progress.listen(
        (int percent) => onProgress(percent / 100),
      );
      try {
        return (await task.result).text;
      } finally {
        await updates.cancel();
      }
    } finally {
      engine.dispose();
    }
  }
}
