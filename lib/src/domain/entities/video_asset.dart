import 'package:mute_music_app/src/domain/entities/clip_range.dart';

/// A video file on disk. Pure Dart — no Flutter imports.
class VideoAsset {
  const VideoAsset({
    required this.path,
    this.sizeInBytes,
    this.duration,
    this.range,
  });

  final String path;
  final int? sizeInBytes;

  /// Null when the platform could not read it.
  final Duration? duration;

  /// Set only on a part: the range of the original it really covers.
  final ClipRange? range;

  @override
  bool operator ==(Object other) =>
      other is VideoAsset &&
      other.path == path &&
      other.sizeInBytes == sizeInBytes &&
      other.duration == duration &&
      other.range == range;

  @override
  int get hashCode => Object.hash(path, sizeInBytes, duration, range);
}
