import 'dart:io';

import 'package:mute_music_app/src/core/constants/model_constants.dart';
import 'package:path_provider/path_provider.dart';

/// Owns where the model file lives on disk and whether it is usable.
class ModelStorage {
  Future<File> modelFile() async {
    final Directory directory = await getApplicationSupportDirectory();
    return File('${directory.path}/${ModelConstants.vocalsModelFileName}');
  }

  Future<File> partialFile() async {
    final File target = await modelFile();
    return File('${target.path}${ModelConstants.partialSuffix}');
  }

  /// Ready means present and the exact expected size — a half-finished file
  /// would crash the runtime later with a much less obvious error.
  Future<bool> isReady() async {
    final File target = await modelFile();
    if (!target.existsSync()) return false;
    return target.lengthSync() == ModelConstants.vocalsModelSizeInBytes;
  }

  Future<void> deleteBrokenFiles() async {
    final File target = await modelFile();
    final File partial = await partialFile();
    if (partial.existsSync()) await partial.delete();
    if (target.existsSync() &&
        target.lengthSync() != ModelConstants.vocalsModelSizeInBytes) {
      await target.delete();
    }
  }
}
