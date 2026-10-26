import 'package:flutter/foundation.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/domain/entities/removal_progress.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';

enum MuteVideoStatus {
  initial,
  picking,
  cutting,
  muting,
  converting,
  extracting,

  /// The speech model is missing: the screen asks before the download.
  confirmSpeechDownload,
  downloadingSpeech,
  preparingModel,
  removingMusic,
  muted,
  saving,
  saved,
  savedToMusic,

  /// Extracted text is ready to show on the Text screen.
  textReady,
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
enum MediaOperation { removeSound, removeMusic, convertToAudio }

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
    this.applied = const <MediaOperation>{},
    this.lastInput,
    this.text,
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

  /// Operations run since the file was added or last cut (rule A1).
  final Set<MediaOperation> applied;

  /// The file before the last operation: the input of the last result, or
  /// the added file for a part. The original icon opens it (spec 006 §3.2).
  final VideoAsset? lastInput;

  /// The text read from the current file, with the user's edits (spec 006
  /// §5). Dropped whenever the file changes.
  final String? text;

  bool get isBusy => const <MuteVideoStatus>{
    MuteVideoStatus.picking,
    MuteVideoStatus.cutting,
    MuteVideoStatus.muting,
    MuteVideoStatus.converting,
    MuteVideoStatus.extracting,
    MuteVideoStatus.confirmSpeechDownload,
    MuteVideoStatus.downloadingSpeech,
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
      status == MuteVideoStatus.removingMusic ||
      status == MuteVideoStatus.downloadingSpeech ||
      (status == MuteVideoStatus.extracting && !(current?.isImage ?? true));

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
    String? text,
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
      applied: applied,
      lastInput: lastInput,
      text: text ?? this.text,
    );
  }

  /// A fresh pick drops any previously produced part and result.
  MuteVideoState withNewSource(VideoAsset source) => MuteVideoState(
    status: MuteVideoStatus.initial,
    source: source,
    original: source,
  );

  /// A new part (or the original again) drops any previously produced result.
  /// Every operation is offered again, and the part's "before" is the added
  /// file.
  MuteVideoState withPart(VideoAsset part) {
    final VideoAsset? added = original ?? source;
    return MuteVideoState(
      status: MuteVideoStatus.initial,
      source: part,
      original: added,
      lastInput: added != null && added.path != part.path ? added : null,
    );
  }

  /// A new result of [operation] made from [input] (spec 006 §3.1, §3.2).
  MuteVideoState withResult(
    VideoAsset result, {
    required VideoAsset input,
    required MediaOperation operation,
  }) => MuteVideoState(
    status: MuteVideoStatus.muted,
    source: source,
    original: original,
    muted: result,
    musicOnly: operation == MediaOperation.removeMusic,
    applied: <MediaOperation>{...applied, operation},
    lastInput: input,
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
      other.removal == removal &&
      setEquals(other.applied, applied) &&
      other.lastInput == lastInput &&
      other.text == text;

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
    Object.hashAllUnordered(applied),
    lastInput,
    text,
  );
}
