import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/core/constants/app_flags.dart';
import 'package:mute_music_app/src/core/constants/model_constants.dart';
import 'package:mute_music_app/src/core/di/network_module.dart';
import 'package:mute_music_app/src/core/diagnostics/memory_logger.dart';
import 'package:mute_music_app/src/core/diagnostics/memory_probe.dart';
import 'package:mute_music_app/src/data/local/device_memory_datasource.dart';
import 'package:mute_music_app/src/data/local/audio_pipeline_datasource.dart';
import 'package:mute_music_app/src/data/local/model_storage.dart';
import 'package:mute_music_app/src/data/local/separation_worker.dart';
import 'package:mute_music_app/src/data/local/temp_files_datasource.dart';
import 'package:mute_music_app/src/data/local/video_mute_datasource.dart';
import 'package:mute_music_app/src/data/remote/model_download_service.dart';
import 'package:mute_music_app/src/data/repositories/music_removal_repository_impl.dart';
import 'package:mute_music_app/src/data/repositories/separation_model_repository_impl.dart';
import 'package:mute_music_app/src/data/repositories/video_repository_impl.dart';
import 'package:mute_music_app/src/domain/repositories/music_removal_repository.dart';
import 'package:mute_music_app/src/domain/repositories/separation_model_repository.dart';
import 'package:mute_music_app/src/domain/repositories/video_repository.dart';
import 'package:mute_music_app/src/domain/use_cases/cut_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/discard_leftovers_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/discard_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/ensure_model_ready_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/mute_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/pick_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/remove_music_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/save_video_use_case.dart';

final GetIt injector = GetIt.instance;

void setupInjector() {
  setupNetwork();
  injector
    ..registerLazySingleton<ImagePicker>(ImagePicker.new)
    ..registerLazySingleton<VideoMuteDatasource>(VideoMuteDatasource.new)
    ..registerLazySingleton<TempFilesDatasource>(TempFilesDatasource.new)
    ..registerLazySingleton<ModelStorage>(ModelStorage.new)
    ..registerLazySingleton<ModelDownloadService>(
      () => ModelDownloadService(
        injector<Dio>(instanceName: ModelConstants.downloadDioName),
      ),
    )
    ..registerLazySingleton<SeparationModelRepository>(
      () => SeparationModelRepositoryImpl(injector(), injector()),
    )
    ..registerLazySingleton<EnsureModelReadyUseCase>(
      () => EnsureModelReadyUseCase(injector()),
    )
    ..registerLazySingleton<AudioPipelineDatasource>(
      AudioPipelineDatasource.new,
    )
    ..registerLazySingleton<SeparationWorker>(SeparationWorker.new)
    ..registerLazySingleton<MusicRemovalRepository>(
      () => MusicRemovalRepositoryImpl(injector(), injector(), injector()),
    )
    ..registerLazySingleton<RemoveMusicUseCase>(
      () => RemoveMusicUseCase(injector()),
    )
    ..registerLazySingleton<VideoRepository>(
      () => VideoRepositoryImpl(injector(), injector(), injector()),
    )
    ..registerLazySingleton<PickVideoUseCase>(
      () => PickVideoUseCase(injector()),
    )
    ..registerLazySingleton<MuteVideoUseCase>(
      () => MuteVideoUseCase(injector()),
    )
    ..registerLazySingleton<SaveVideoUseCase>(
      () => SaveVideoUseCase(injector()),
    )
    ..registerLazySingleton<CutVideoUseCase>(() => CutVideoUseCase(injector()))
    ..registerLazySingleton<DiscardVideoUseCase>(
      () => DiscardVideoUseCase(injector()),
    )
    ..registerLazySingleton<DiscardLeftoversUseCase>(
      () => DiscardLeftoversUseCase(injector()),
    )
    ..registerFactory<MuteVideoCubit>(
      () => MuteVideoCubit(
        injector(),
        injector(),
        injector(),
        injector(),
        injector(),
        injector(),
        injector(),
      ),
    );
  if (AppFlags.diagnostics) _setupDiagnostics();
}

/// TEMPORARY: remove with MemoryProbeScreen.
void _setupDiagnostics() {
  injector
    ..registerLazySingleton<DeviceMemoryDatasource>(DeviceMemoryDatasource.new)
    ..registerLazySingleton<MemoryProbe>(
      () => MemoryProbe(injector(), injector(), injector()),
    )
    ..registerLazySingleton<MemoryLogger>(() => MemoryLogger(injector()));
}
