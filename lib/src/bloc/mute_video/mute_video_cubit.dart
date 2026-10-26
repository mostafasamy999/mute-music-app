import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/core/constants/clip_limits.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/clip_range.dart';
import 'package:mute_music_app/src/domain/entities/removal_progress.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/domain/use_cases/convert_to_audio_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/cut_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/discard_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/ensure_model_ready_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/extract_text_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/mute_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/pick_media_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/remove_music_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/save_audio_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/save_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/speech_model_use_case.dart';

class MuteVideoCubit extends Cubit<MuteVideoState> {
  MuteVideoCubit(
    this._pickMedia,
    this._muteVideo,
    this._saveVideo,
    this._ensureModel,
    this._removeMusic,
    this._discardVideo,
    this._cutVideo,
    this._convertToAudio,
    this._saveAudio,
    this._extractText,
    this._speechModel,
  ) : super(const MuteVideoState());

  final PickMediaUseCase _pickMedia;
  final MuteVideoUseCase _muteVideo;
  final SaveVideoUseCase _saveVideo;
  final EnsureModelReadyUseCase _ensureModel;
  final RemoveMusicUseCase _removeMusic;
  final DiscardVideoUseCase _discardVideo;
  final CutVideoUseCase _cutVideo;
  final ConvertToAudioUseCase _convertToAudio;
  final SaveAudioUseCase _saveAudio;
  final ExtractTextUseCase _extractText;
  final SpeechModelUseCase _speechModel;

  /// Adds an image, a sound or a video (spec 006 F1). It replaces the current
  /// file, its part and its outputs.
  Future<void> addMedia(MediaKind kind) =>
      _guard(AppFailure.pickFailed, () => _pick(kind));

  /// The pre-006 entry point, kept for the tests that add a video.
  Future<void> pickVideo() => addMedia(MediaKind.video);

  /// Drops the file, its part and every output, deletes the app's copies, and
  /// goes back to the empty screen (spec 006 F2). Does nothing while a job
  /// runs, so a job never finishes on a file that is gone.
  Future<void> clear() async {
    if (state.isBusy) return;
    await _moveTo(const MuteVideoState());
  }

  /// Makes [range] of the original the new source (spec 003 F6).
  Future<void> usePart(ClipRange range) =>
      _guard(AppFailure.cutFailed, () => _usePart(range));

  Future<void> removeSound() => _guard(AppFailure.muteFailed, _mute);

  Future<void> removeMusic() =>
      _guard(AppFailure.musicRemovalFailed, _separate);

  /// Writes the current video's audio into a sound file (spec 006 F7).
  Future<void> convertToAudio() => _guard(AppFailure.convertFailed, _convert);

  Future<void> saveToGallery() => _guard(AppFailure.saveFailed, _save);

  /// Reads the text in the current file and opens the Text screen (spec 006
  /// F8). The last edited text is shown again instead of reading again,
  /// unless [again] (Q10).
  Future<void> extractText({bool again = false}) =>
      _guard(AppFailure.extractFailed, () => _extract(again: again));

  /// The user agreed to the one-time speech model download (spec 006 S14);
  /// the text is read right after it.
  Future<void> downloadSpeechModel() =>
      _guard(AppFailure.speechModelDownloadFailed, _downloadSpeech);

  /// The user said no to the download: back to the file, nothing changes.
  void declineSpeechDownload() {
    if (state.status == MuteVideoStatus.confirmSpeechDownload) {
      _set(state.copyWith(status: _idleStatus));
    }
  }

  /// The user's edits on the Text screen.
  void updateText(String text) => _set(state.copyWith(text: text));

  /// The Text screen closed: back to the file's own status.
  void closeText() {
    if (state.status == MuteVideoStatus.textReady) {
      _set(state.copyWith(status: _idleStatus));
    }
  }

  /// Saves the current sound file to the phone's music storage (spec 006
  /// F10).
  Future<void> saveToMusic() => _guard(AppFailure.saveFailed, _saveMusic);

  Future<void> _pick(MediaKind kind) async {
    _set(state.copyWith(status: MuteVideoStatus.picking));
    switch (await _pickMedia(kind)) {
      case DataSuccess<VideoAsset?>(:final VideoAsset? data):
        if (data == null) {
          _set(state.copyWith(status: _idleStatus));
          return;
        }
        await _moveTo(state.withNewSource(data));
      case DataFailed<VideoAsset?>(:final AppFailure failure):
        _fail(failure);
    }
  }

  Future<void> _usePart(ClipRange range) async {
    final VideoAsset? original = state.original ?? state.source;
    if (original == null) return;
    if (_isWholeVideo(original, range)) {
      // Nothing to cut. Going back to the whole video drops an earlier part.
      if (state.hasPart) await _replaceSource(original);
      return;
    }
    _set(state.copyWith(status: MuteVideoStatus.cutting));
    switch (await _cutVideo(original, range)) {
      case DataSuccess<VideoAsset>(:final VideoAsset data):
        await _replaceSource(data);
      case DataFailed<VideoAsset>(:final AppFailure failure):
        _fail(failure);
    }
  }

  /// Drops the old part and results, but never the original: the user can
  /// still choose another part of it.
  Future<void> _replaceSource(VideoAsset next) => _moveTo(state.withPart(next));

  bool _isWholeVideo(VideoAsset original, ClipRange range) {
    final Duration? duration = original.duration;
    if (duration == null) return false;
    return range.start <= ClipLimits.wholeVideoTolerance &&
        range.end >= duration - ClipLimits.wholeVideoTolerance;
  }

  /// Runs on the current file: the latest result, else the part or the added
  /// file (spec 006 Q8).
  Future<void> _mute() async {
    final VideoAsset? input = state.current;
    if (input == null) return;
    _set(state.copyWith(status: MuteVideoStatus.muting));
    switch (await _muteVideo(input)) {
      case DataSuccess<VideoAsset>(:final VideoAsset data):
        await _showResult(
          data,
          input: input,
          operation: MediaOperation.removeSound,
        );
      case DataFailed<VideoAsset>(:final AppFailure failure):
        _fail(failure);
    }
  }

  Future<void> _separate() async {
    final VideoAsset? source = state.current;
    if (source == null) return;
    // The whole track is kept in memory, so a long source would be killed.
    // Fail before any download or extraction starts (spec 003 F3).
    final Duration? duration = source.duration;
    if (duration != null && duration > ClipLimits.maxMusicDuration) {
      return _fail(AppFailure.tooLongForMusic);
    }
    if (!await _prepareModel()) return;
    _set(
      state.copyWith(
        status: MuteVideoStatus.removingMusic,
        progress: 0,
        removal: const RemovalProgress(RemovalStep.extract),
      ),
    );
    switch (await _removeMusic(source, onProgress: _reportStep)) {
      case DataSuccess<VideoAsset>(:final VideoAsset data):
        await _showResult(
          data,
          input: source,
          operation: MediaOperation.removeMusic,
        );
      case DataFailed<VideoAsset>(:final AppFailure failure):
        _fail(failure);
    }
  }

  Future<void> _convert() async {
    final VideoAsset? input = state.current;
    if (input == null || !input.isVideo) return;
    _set(state.copyWith(status: MuteVideoStatus.converting));
    switch (await _convertToAudio(input)) {
      case DataSuccess<MediaAsset>(:final MediaAsset data):
        await _showResult(
          data,
          input: input,
          operation: MediaOperation.convertToAudio,
        );
      case DataFailed<MediaAsset>(:final AppFailure failure):
        _fail(failure);
    }
  }

  /// Saves the result, or the part when only a cut was made (spec 006 Q12).
  Future<void> _save() async {
    final VideoAsset? file = state.current;
    if (file == null || !state.isChanged) return;
    _set(state.copyWith(status: MuteVideoStatus.saving));
    switch (await _saveVideo(file)) {
      case DataSuccess<void>():
        _set(state.copyWith(status: MuteVideoStatus.saved));
      case DataFailed<void>(:final AppFailure failure):
        _fail(failure);
    }
  }

  Future<void> _saveMusic() async {
    final VideoAsset? file = state.current;
    if (file == null || !file.isAudio || !state.isChanged) return;
    _set(state.copyWith(status: MuteVideoStatus.saving));
    switch (await _saveAudio(file)) {
      case DataSuccess<void>():
        _set(state.copyWith(status: MuteVideoStatus.savedToMusic));
      case DataFailed<void>(:final AppFailure failure):
        _fail(failure);
    }
  }

  Future<void> _extract({required bool again}) async {
    final VideoAsset? file = state.current;
    if (file == null) return;
    if (!again && state.text != null) {
      _set(state.copyWith(status: MuteVideoStatus.textReady));
      return;
    }
    if (!file.isImage) {
      // Whisper keeps the whole track in memory, like Remove music.
      final Duration? duration = file.duration;
      if (duration != null && duration > ClipLimits.maxMusicDuration) {
        return _fail(AppFailure.tooLongForText);
      }
      if (!await _speechModel.isReady()) {
        _set(state.copyWith(status: MuteVideoStatus.confirmSpeechDownload));
        return;
      }
    }
    _set(state.copyWith(status: MuteVideoStatus.extracting, progress: 0));
    switch (await _extractText(
      file,
      onProgress: (double p) => _set(state.copyWith(progress: p)),
    )) {
      case DataSuccess<String>(:final String data):
        _set(state.copyWith(status: MuteVideoStatus.textReady, text: data));
      case DataFailed<String>(:final AppFailure failure):
        _fail(failure);
    }
  }

  Future<void> _downloadSpeech() async {
    _set(
      state.copyWith(status: MuteVideoStatus.downloadingSpeech, progress: 0),
    );
    final DataState<void> result = await _speechModel.download(
      onProgress: (double p) => _set(state.copyWith(progress: p)),
    );
    if (result case DataFailed<void>(:final AppFailure failure)) {
      return _fail(failure);
    }
    await _extract(again: true);
  }

  /// Repositories already turn errors into failures. This catches whatever
  /// still slips through, so the screen can never stay busy.
  Future<void> _guard(
    AppFailure fallback,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on Object {
      _fail(fallback);
    }
  }

  /// The result becomes the current file, and its input stays as the file
  /// before the last operation (spec 006 §3.2).
  Future<void> _showResult(
    VideoAsset result, {
    required VideoAsset input,
    required MediaOperation operation,
  }) => _moveTo(state.withResult(result, input: input, operation: operation));

  /// Emits [next], then deletes every file the old state pointed at and the
  /// new one doesn't. Deleting only after the emit means the preview never
  /// loses a file it is still showing; comparing paths keeps a file that is
  /// still used under another role (the original, the part, the result, or
  /// the file before the last operation) and one a picker hands back twice.
  Future<void> _moveTo(MuteVideoState next) async {
    final Map<String, VideoAsset> before = _filesOf(state);
    final Set<String> kept = _filesOf(next).keys.toSet();
    _set(next);
    for (final MapEntry<String, VideoAsset> file in before.entries) {
      if (!kept.contains(file.key)) await _discardVideo(file.value);
    }
  }

  static Map<String, VideoAsset> _filesOf(MuteVideoState state) =>
      <String, VideoAsset>{
        for (final VideoAsset file in <VideoAsset?>[
          state.source,
          state.original,
          state.muted,
          state.lastInput,
        ].nonNulls)
          file.path: file,
      };

  Future<bool> _prepareModel() async {
    _set(
      state.copyWith(
        status: MuteVideoStatus.preparingModel,
        progress: 0,
        removal: const RemovalProgress(RemovalStep.model),
      ),
    );
    final DataState<void> result = await _ensureModel(
      onProgress: _reportDownload,
    );
    if (result is DataFailed<void>) {
      _fail(result.failure);
      return false;
    }
    return true;
  }

  void _reportDownload(double value) {
    final double clamped = value.clamp(0, 1);
    _set(
      state.copyWith(
        progress: clamped,
        removal: RemovalProgress(
          RemovalStep.model,
          done: (clamped * 100).round(),
          total: 100,
        ),
      ),
    );
  }

  void _reportStep(RemovalProgress step) =>
      _set(state.copyWith(progress: step.fraction ?? 0, removal: step));

  MuteVideoStatus get _idleStatus =>
      state.muted == null ? MuteVideoStatus.initial : MuteVideoStatus.muted;

  void _fail(AppFailure failure) =>
      _set(state.copyWith(status: MuteVideoStatus.failure, failure: failure));

  /// The long jobs finish after the screen may already be gone, and emitting
  /// on a closed cubit throws.
  void _set(MuteVideoState next) {
    if (!isClosed) emit(next);
  }
}
