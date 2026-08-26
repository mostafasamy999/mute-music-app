import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';

enum MuteVideoStatus { initial, picking, muting, muted, saving, saved, failure }

class MuteVideoState {
  const MuteVideoState({
    this.status = MuteVideoStatus.initial,
    this.source,
    this.muted,
    this.failure,
  });

  final MuteVideoStatus status;
  final VideoAsset? source;
  final VideoAsset? muted;
  final AppFailure? failure;

  bool get isBusy =>
      status == MuteVideoStatus.picking ||
      status == MuteVideoStatus.muting ||
      status == MuteVideoStatus.saving;

  bool get canSave => muted != null && !isBusy;

  /// [failure] is not carried over — it clears on every transition unless the
  /// caller passes a new one.
  MuteVideoState copyWith({
    MuteVideoStatus? status,
    VideoAsset? source,
    VideoAsset? muted,
    AppFailure? failure,
  }) => MuteVideoState(
    status: status ?? this.status,
    source: source ?? this.source,
    muted: muted ?? this.muted,
    failure: failure,
  );

  /// A fresh pick drops any previously muted result.
  MuteVideoState withNewSource(VideoAsset source) =>
      MuteVideoState(status: MuteVideoStatus.initial, source: source);

  @override
  bool operator ==(Object other) =>
      other is MuteVideoState &&
      other.status == status &&
      other.source == source &&
      other.muted == muted &&
      other.failure == failure;

  @override
  int get hashCode => Object.hash(status, source, muted, failure);
}
