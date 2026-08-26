import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/domain/use_cases/mute_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/pick_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/save_video_use_case.dart';

class MuteVideoCubit extends Cubit<MuteVideoState> {
  MuteVideoCubit(this._pickVideo, this._muteVideo, this._saveVideo)
    : super(const MuteVideoState());

  final PickVideoUseCase _pickVideo;
  final MuteVideoUseCase _muteVideo;
  final SaveVideoUseCase _saveVideo;

  Future<void> pickVideo() async {
    emit(state.copyWith(status: MuteVideoStatus.picking));
    switch (await _pickVideo()) {
      case DataSuccess<VideoAsset?>(:final VideoAsset? data):
        emit(data == null ? state.copyWith(status: _idleStatus) : state.withNewSource(data));
      case DataFailed<VideoAsset?>(:final AppFailure failure):
        _emitFailure(failure);
    }
  }

  Future<void> removeSound() async {
    final VideoAsset? source = state.source;
    if (source == null) return;
    emit(state.copyWith(status: MuteVideoStatus.muting));
    switch (await _muteVideo(source)) {
      case DataSuccess<VideoAsset>(:final VideoAsset data):
        emit(state.copyWith(status: MuteVideoStatus.muted, muted: data));
      case DataFailed<VideoAsset>(:final AppFailure failure):
        _emitFailure(failure);
    }
  }

  Future<void> saveToGallery() async {
    final VideoAsset? muted = state.muted;
    if (muted == null) return;
    emit(state.copyWith(status: MuteVideoStatus.saving));
    switch (await _saveVideo(muted)) {
      case DataSuccess<void>():
        emit(state.copyWith(status: MuteVideoStatus.saved));
      case DataFailed<void>(:final AppFailure failure):
        _emitFailure(failure);
    }
  }

  MuteVideoStatus get _idleStatus =>
      state.muted == null ? MuteVideoStatus.initial : MuteVideoStatus.muted;

  void _emitFailure(AppFailure failure) =>
      emit(state.copyWith(status: MuteVideoStatus.failure, failure: failure));
}
