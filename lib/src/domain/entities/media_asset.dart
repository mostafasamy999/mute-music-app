import 'package:mute_music_app/src/domain/entities/clip_range.dart';

/// What kind of file the user added (spec 006 §6).
enum MediaKind { image, audio, video }

/// A media file on disk: an image, a sound or a video. Pure Dart — no Flutter
/// imports.
class MediaAsset {
  const MediaAsset({
    required this.path,
    this.kind = MediaKind.video,
    this.sizeInBytes,
    this.duration,
    this.range,
  });

  final String path;

  /// Video by default, so every place that made a video asset before 006
  /// still makes one without change.
  final MediaKind kind;

  final int? sizeInBytes;

  /// Null for an image, or when the platform could not read it.
  final Duration? duration;

  /// Set only on a part: the range of the original it really covers.
  final ClipRange? range;

  bool get isImage => kind == MediaKind.image;
  bool get isAudio => kind == MediaKind.audio;
  bool get isVideo => kind == MediaKind.video;

  @override
  bool operator ==(Object other) =>
      other is MediaAsset &&
      other.path == path &&
      other.kind == kind &&
      other.sizeInBytes == sizeInBytes &&
      other.duration == duration &&
      other.range == range;

  @override
  int get hashCode => Object.hash(path, kind, sizeInBytes, duration, range);
}
