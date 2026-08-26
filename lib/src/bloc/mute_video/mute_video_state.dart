import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';

enum MuteVideoStatus {
  initial,
  picking,
  muting,
  preparingModel,
  removingMusic,
  muted,
  saving,
  saved,
  failure,
}

class MuteVideoState {
  const MuteVideoState({
    this.status = MuteVideoStatus.initial,
    this.source,
    this.muted,
    this.failure,
    this.progress = 0,
    this.musicOnly = false,
  });

  final MuteVideoStatus status;
  final VideoAsset? source;
  final VideoAsset? muted;
  final AppFailure? failure;

  /// 0.0 to 1.0 while a long job runs. Only meaningful for the model steps.
  final double progress;

  /// True when the result kept the voices instead of dropping all sound.
  final bool musicOnly;

  bool get isBusy => const <MuteVideoStatus>{
    MuteVideoStatus.picking,
    MuteVideoStatus.muting,
    MuteVideoStatus.preparingModel,
    MuteVideoStatus.removingMusic,
    MuteVideoStatus.saving,
  }.contains(status);

  bool get canSave => muted != null && !isBusy;

  bool get showsProgress =>
      status == MuteVideoStatus.preparingModel ||
      status == MuteVideoStatus.removingMusic;

  /// [failure] is not carried over — it clears on every transition unless the
  /// caller passes a new one.
  MuteVideoState copyWith({
    MuteVideoStatus? status,
    VideoAsset? source,
    VideoAsset? muted,
    AppFailure? failure,
    double? progress,
    bool? musicOnly,
  }) => MuteVideoState(
    status: status ?? this.status,
    source: source ?? this.source,
    muted: muted ?? this.muted,
    failure: failure,
    progress: progress ?? this.progress,
    musicOnly: musicOnly ?? this.musicOnly,
  );

  /// A fresh pick drops any previously produced result.
  MuteVideoState withNewSource(VideoAsset source) =>
      MuteVideoState(status: MuteVideoStatus.initial, source: source);

  @override
  bool operator ==(Object other) =>
      other is MuteVideoState &&
      other.status == status &&
      other.source == source &&
      other.muted == muted &&
      other.failure == failure &&
      other.progress == progress &&
      other.musicOnly == musicOnly;

  @override
  int get hashCode =>
      Object.hash(status, source, muted, failure, progress, musicOnly);
}
