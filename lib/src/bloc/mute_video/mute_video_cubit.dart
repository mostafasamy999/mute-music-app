import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
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
  ) : super(const MuteVideoState());

  final PickVideoUseCase _pickVideo;
  final MuteVideoUseCase _muteVideo;
  final SaveVideoUseCase _saveVideo;
  final EnsureModelReadyUseCase _ensureModel;
  final RemoveMusicUseCase _removeMusic;

  Future<void> pickVideo() async {
    _set(state.copyWith(status: MuteVideoStatus.picking));
    switch (await _pickVideo()) {
      case DataSuccess<VideoAsset?>(:final VideoAsset? data):
        _set(
          data == null
              ? state.copyWith(status: _idleStatus)
              : state.withNewSource(data),
        );
      case DataFailed<VideoAsset?>(:final AppFailure failure):
        _fail(failure);
    }
  }

  Future<void> removeSound() async {
    final VideoAsset? source = state.source;
    if (source == null) return;
    _set(state.copyWith(status: MuteVideoStatus.muting));
    switch (await _muteVideo(source)) {
      case DataSuccess<VideoAsset>(:final VideoAsset data):
        _set(
          state.copyWith(
            status: MuteVideoStatus.muted,
            muted: data,
            musicOnly: false,
          ),
        );
      case DataFailed<VideoAsset>(:final AppFailure failure):
        _fail(failure);
    }
  }

  Future<void> removeMusic() async {
    final VideoAsset? source = state.source;
    if (source == null) return;
    if (!await _prepareModel()) return;
    _set(state.copyWith(status: MuteVideoStatus.removingMusic, progress: 0));
    switch (await _removeMusic(source, onProgress: _reportProgress)) {
      case DataSuccess<VideoAsset>(:final VideoAsset data):
        _set(
          state.copyWith(
            status: MuteVideoStatus.muted,
            muted: data,
            musicOnly: true,
          ),
        );
      case DataFailed<VideoAsset>(:final AppFailure failure):
        _fail(failure);
    }
  }

  Future<void> saveToGallery() async {
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

  Future<bool> _prepareModel() async {
    _set(state.copyWith(status: MuteVideoStatus.preparingModel, progress: 0));
    final DataState<void> result = await _ensureModel(
      onProgress: _reportProgress,
    );
    if (result is DataFailed<void>) {
      _fail(result.failure);
      return false;
    }
    return true;
  }

  void _reportProgress(double value) =>
      _set(state.copyWith(progress: value.clamp(0, 1)));

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
