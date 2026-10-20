import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/domain/entities/removal_progress.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';

enum MuteVideoStatus {
  initial,
  picking,
  cutting,
  muting,
  preparingModel,
  removingMusic,
  muted,
  saving,
  saved,
  failure,
}

/// Where the user is in the flow. Decides which actions show by default.
enum ActionStage {
  /// Nothing picked yet.
  empty,

  /// A video is picked, no result yet.
  picked,

  /// A result exists and can be saved.
  done,
}

class MuteVideoState {
  const MuteVideoState({
    this.status = MuteVideoStatus.initial,
    this.source,
    this.original,
    this.muted,
    this.failure,
    this.progress = 0,
    this.musicOnly = false,
    this.removal,
  });

  final MuteVideoStatus status;

  /// What every job runs on: the chosen part, or the original when there is
  /// no part.
  final VideoAsset? source;

  /// The picked video. Kept only so the user can choose another part without
  /// picking again; no job ever runs on it while a part is chosen.
  final VideoAsset? original;

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
    MuteVideoStatus.cutting,
    MuteVideoStatus.muting,
    MuteVideoStatus.preparingModel,
    MuteVideoStatus.removingMusic,
    MuteVideoStatus.saving,
  }.contains(status);

  bool get canSave => muted != null && !isBusy;

  /// From the data only, not the busy status, so the buttons don't change
  /// while a job runs.
  ActionStage get stage => muted != null
      ? ActionStage.done
      : source != null
      ? ActionStage.picked
      : ActionStage.empty;

  bool get hasPart =>
      original != null && source != null && source!.path != original!.path;

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
      original: original,
      muted: muted ?? this.muted,
      failure: failure,
      progress: progress ?? this.progress,
      musicOnly: musicOnly ?? this.musicOnly,
      removal: removing ? removal ?? this.removal : null,
    );
  }

  /// A fresh pick drops any previously produced part and result.
  MuteVideoState withNewSource(VideoAsset source) => MuteVideoState(
    status: MuteVideoStatus.initial,
    source: source,
    original: source,
  );

  /// A new part (or the original again) drops any previously produced result.
  MuteVideoState withPart(VideoAsset part) => MuteVideoState(
    status: MuteVideoStatus.initial,
    source: part,
    original: original ?? source,
  );

  @override
  bool operator ==(Object other) =>
      other is MuteVideoState &&
      other.status == status &&
      other.source == source &&
      other.original == original &&
      other.muted == muted &&
      other.failure == failure &&
      other.progress == progress &&
      other.musicOnly == musicOnly &&
      other.removal == removal;

  @override
  int get hashCode => Object.hash(
    status,
    source,
    original,
    muted,
    failure,
    progress,
    musicOnly,
    removal,
  );
}
