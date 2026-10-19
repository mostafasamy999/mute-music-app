import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Owns cleanup of the files the app writes. Every intermediate and result
/// goes into the platform temp folder (cacheDir on Android,
/// NSTemporaryDirectory on iOS), which is what [getTemporaryDirectory] returns.
class TempFilesDatasource {
  /// Name prefixes the native side gives the files it writes.
  static const List<String> _prefixes = <String>[
    'muted_',
    'nomusic_',
    'audio_',
  ];

  /// Deletes [path] only when it lives in the temp folder, so a file the user
  /// owns, such as a gallery original, is never touched.
  Future<void> delete(String path) async {
    final File file = File(path);
    if (!file.existsSync()) return;
    final String temp = (await getTemporaryDirectory())
        .resolveSymbolicLinksSync();
    // Resolved, because iOS hands out both /var/... and /private/var/... paths.
    final String parent = file.parent.resolveSymbolicLinksSync();
    if (parent == temp || parent.startsWith('$temp/')) await file.delete();
  }

  /// Deletes files left by an earlier launch. Nothing can still use them,
  /// since no state survives a restart. Files newer than [before] are kept, so
  /// a job started while this runs is never hit.
  Future<void> deleteLeftovers({required DateTime before}) async {
    final Directory temp = await getTemporaryDirectory();
    if (!temp.existsSync()) return;
    for (final FileSystemEntity entity in temp.listSync()) {
      if (entity is! File) continue;
      final String name = entity.uri.pathSegments.last;
      if (!_prefixes.any(name.startsWith)) continue;
      if (entity.lastModifiedSync().isBefore(before)) await entity.delete();
    }
  }
}
