import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/removal_progress.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/domain/use_cases/discard_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/ensure_model_ready_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/mute_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/pick_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/remove_music_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/save_video_use_case.dart';

class MuteVideoCubit extends Cubit<MuteVideoState> {
  MuteVideoCubit(
    this._pickVideo,
    this._muteVideo,
    this._saveVideo,
    this._ensureModel,
    this._removeMusic,
    this._discardVideo,
  ) : super(const MuteVideoState());

  final PickVideoUseCase _pickVideo;
  final MuteVideoUseCase _muteVideo;
  final SaveVideoUseCase _saveVideo;
  final EnsureModelReadyUseCase _ensureModel;
  final RemoveMusicUseCase _removeMusic;
  final DiscardVideoUseCase _discardVideo;

  Future<void> pickVideo() => _guard(AppFailure.pickFailed, _pick);

  Future<void> removeSound() => _guard(AppFailure.muteFailed, _mute);

  Future<void> removeMusic() =>
      _guard(AppFailure.musicRemovalFailed, _separate);

  Future<void> saveToGallery() => _guard(AppFailure.saveFailed, _save);

  Future<void> _pick() async {
    _set(state.copyWith(status: MuteVideoStatus.picking));
    switch (await _pickVideo()) {
      case DataSuccess<VideoAsset?>(:final VideoAsset? data):
        if (data == null) {
          _set(state.copyWith(status: _idleStatus));
          return;
        }
        final MuteVideoState previous = state;
        _set(state.withNewSource(data));
        await _discard(<VideoAsset?>[previous.source, previous.muted], data);
      case DataFailed<VideoAsset?>(:final AppFailure failure):
        _fail(failure);
    }
  }

  Future<void> _mute() async {
    final VideoAsset? source = state.source;
    if (source == null) return;
    _set(state.copyWith(status: MuteVideoStatus.muting));
    switch (await _muteVideo(source)) {
      case DataSuccess<VideoAsset>(:final VideoAsset data):
        await _showResult(data, musicOnly: false);
      case DataFailed<VideoAsset>(:final AppFailure failure):
        _fail(failure);
    }
  }

  Future<void> _separate() async {
    final VideoAsset? source = state.source;
    if (source == null) return;
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
        await _showResult(data, musicOnly: true);
      case DataFailed<VideoAsset>(:final AppFailure failure):
        _fail(failure);
    }
  }

  Future<void> _save() async {
    final VideoAsset? muted = state.muted;
    if (muted == null) return;
    _set(state.copyWith(status: MuteVideoStatus.saving));
    switch (await _saveVideo(muted)) {
      case DataSuccess<void>():
        _set(state.copyWith(status: MuteVideoStatus.saved));
      case DataFailed<void>(:final AppFailure failure):
        _fail(failure);
    }
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

  Future<void> _showResult(VideoAsset result, {required bool musicOnly}) async {
    final VideoAsset? replaced = state.muted;
    _set(
      state.copyWith(
        status: MuteVideoStatus.muted,
        muted: result,
        musicOnly: musicOnly,
      ),
    );
    await _discard(<VideoAsset?>[replaced], result);
  }

  /// Runs only after the state stops pointing at [videos], so the preview
  /// never loses a file it is still showing. [keep] guards against a picker
  /// that hands back the same path twice.
  Future<void> _discard(List<VideoAsset?> videos, VideoAsset keep) async {
    for (final VideoAsset? video in videos) {
      if (video != null && video.path != keep.path) await _discardVideo(video);
    }
  }

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
