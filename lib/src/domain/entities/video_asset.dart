import 'package:mute_music_app/src/domain/entities/media_asset.dart';

export 'package:mute_music_app/src/domain/entities/media_asset.dart';

/// The name every pre-006 file uses. It is the same class as [MediaAsset], so
/// those files (including the Remove music pipeline) keep compiling and
/// behaving exactly as before. A `VideoAsset(...)` is a video by default.
typedef VideoAsset = MediaAsset;
