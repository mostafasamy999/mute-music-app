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

/// What the user can do next with the current file (spec 006 §3, §3.1).
enum MediaAction {
  removeSound,
  removeMusic,
  convertToAudio,
  extractText,
  saveToGallery,
  saveToMusic,
}

/// An operation already run on the current file since it was added or cut.
/// Rule A1: an operation is never offered again once it ran.
enum MediaOperation { removeSound, removeMusic }

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

  /// The file the actions apply to and Save saves: the latest result, else
  /// the part or the added file.
  VideoAsset? get current => muted ?? source;

  /// A part or a result exists. The untouched added file is never saved.
  bool get isChanged => muted != null || hasPart;

  bool get canSave => isChanged && !isBusy;

  /// Every action on a result is offered on that result, and a new cut starts
  /// again from the added file, so the result is the only operation so far.
  Set<MediaOperation> get applied => muted == null
      ? const <MediaOperation>{}
      : <MediaOperation>{
          musicOnly ? MediaOperation.removeMusic : MediaOperation.removeSound,
        };

  /// The actions under the file, in order (spec 006 §3 and §3.1). From the
  /// data only, not the busy status, so the buttons don't jump during a job.
  List<MediaAction> get actions {
    final VideoAsset? file = current;
    if (file == null) return const <MediaAction>[];
    final Set<MediaOperation> done = applied;
    return switch (file.kind) {
      MediaKind.image => const <MediaAction>[MediaAction.extractText],
      MediaKind.audio => <MediaAction>[
        if (!done.contains(MediaOperation.removeMusic)) MediaAction.removeMusic,
        MediaAction.extractText,
        if (isChanged) MediaAction.saveToMusic,
      ],
      // No sound is left, so nothing but Save can work on it.
      MediaKind.video when done.contains(MediaOperation.removeSound) =>
        const <MediaAction>[MediaAction.saveToGallery],
      MediaKind.video => <MediaAction>[
        if (done.isEmpty) MediaAction.removeSound,
        if (!done.contains(MediaOperation.removeMusic)) MediaAction.removeMusic,
        MediaAction.convertToAudio,
        MediaAction.extractText,
        if (isChanged) MediaAction.saveToGallery,
      ],
    };
  }

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
