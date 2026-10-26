import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Owns cleanup of the files the app writes. Every intermediate, part and
/// result goes into the platform temp folder: cacheDir on Android, which is
/// what [getTemporaryDirectory] returns, and NSTemporaryDirectory (`tmp/`) on
/// iOS, which is [Directory.systemTemp] — on iOS [getTemporaryDirectory] is
/// `Library/Caches`, so both folders count as ours.
class TempFilesDatasource {
  TempFilesDatasource({Future<List<Directory>> Function()? folders})
    : _folders = folders ?? _platformFolders;

  final Future<List<Directory>> Function() _folders;

  static Future<List<Directory>> _platformFolders() async => <Directory>[
    await getTemporaryDirectory(),
    if (Platform.isIOS) Directory.systemTemp,
  ];

  /// Name prefixes the native side gives the files it writes.
  static const List<String> _prefixes = <String>[
    'muted_',
    'nomusic_',
    'audio_',
    'part_',
    'export_',
  ];

  /// Deletes [path] only when it lives in a temp folder, so a file the user
  /// owns, such as a gallery original, is never touched.
  Future<void> delete(String path) async {
    final File file = File(path);
    if (!file.existsSync()) return;
    // Resolved, because iOS hands out both /var/... and /private/var/... paths.
    final String parent = file.parent.resolveSymbolicLinksSync();
    for (final Directory folder in await _folders()) {
      if (!folder.existsSync()) continue;
      final String temp = folder.resolveSymbolicLinksSync();
      if (parent == temp || parent.startsWith('$temp/')) {
        await file.delete();
        return;
      }
    }
  }

  /// Deletes files left by an earlier launch. Nothing can still use them,
  /// since no state survives a restart. Files newer than [before] are kept, so
  /// a job started while this runs is never hit.
  Future<void> deleteLeftovers({required DateTime before}) async {
    for (final Directory temp in await _folders()) {
      if (!temp.existsSync()) continue;
      for (final FileSystemEntity entity in temp.listSync()) {
        if (entity is! File) continue;
        final String name = entity.uri.pathSegments.last;
        if (!_prefixes.any(name.startsWith)) continue;
        if (entity.lastModifiedSync().isBefore(before)) await entity.delete();
      }
    }
  }
}
