/// A video file on disk. Pure Dart — no Flutter imports.
class VideoAsset {
  const VideoAsset({required this.path, this.sizeInBytes});

  final String path;
  final int? sizeInBytes;

  @override
  bool operator ==(Object other) =>
      other is VideoAsset &&
      other.path == path &&
      other.sizeInBytes == sizeInBytes;

  @override
  int get hashCode => Object.hash(path, sizeInBytes);
}
