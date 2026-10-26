import 'package:file_picker/file_picker.dart';

/// Picks one sound file. `image_picker` can't pick audio, so this uses the
/// system document picker. The picker hands back a copy in the app's temp
/// folder (Android cacheDir, iOS tmp/), so later steps never touch the user's
/// own file, and [TempFilesDatasource] can delete it.
class AudioFileDatasource {
  /// A fixed list instead of [FileType.audio]: on iOS that type opens the
  /// Apple Music library (DRM files, extra permission) instead of Files.
  static const List<String> extensions = <String>[
    'mp3',
    'm4a',
    'aac',
    'wav',
    'ogg',
    'opus',
    'flac',
    'amr',
  ];

  /// The picked file's path, or null when the user closed the picker.
  Future<String?> pick() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    return result?.files.single.path;
  }
}
