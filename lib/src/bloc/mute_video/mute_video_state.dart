import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/domain/entities/removal_progress.dart';
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
    this.removal,
  });

  final MuteVideoStatus status;
  final VideoAsset? source;
  final VideoAsset? muted;
  final AppFailure? failure;

  /// 0.0 to 1.0 while a long job runs. Only meaningful for the model steps.
  final double progress;

  /// True when the result kept the voices instead of dropping all sound.
  final bool musicOnly;

  /// The current step of "Remove music only". Null when that job isn't running.
  final RemovalProgress? removal;

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

  /// The music removal job shows as a list of steps instead of one line.
  bool get showsSteps => showsProgress && removal != null;

  /// [failure] is not carried over — it clears on every transition unless the
  /// caller passes a new one. [removal] is kept only while the music removal
  /// job runs, so it can't leak into a later status.
  MuteVideoState copyWith({
    MuteVideoStatus? status,
    VideoAsset? source,
    VideoAsset? muted,
    AppFailure? failure,
    double? progress,
    bool? musicOnly,
    RemovalProgress? removal,
  }) {
    final MuteVideoStatus next = status ?? this.status;
    final bool removing =
        next == MuteVideoStatus.preparingModel ||
        next == MuteVideoStatus.removingMusic;
    return MuteVideoState(
      status: next,
      source: source ?? this.source,
      muted: muted ?? this.muted,
      failure: failure,
      progress: progress ?? this.progress,
      musicOnly: musicOnly ?? this.musicOnly,
      removal: removing ? removal ?? this.removal : null,
    );
  }

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
      other.musicOnly == musicOnly &&
      other.removal == removal;

  @override
  int get hashCode =>
      Object.hash(status, source, muted, failure, progress, musicOnly, removal);
}
