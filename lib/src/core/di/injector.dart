import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/data/local/video_mute_datasource.dart';
import 'package:mute_music_app/src/data/repositories/video_repository_impl.dart';
import 'package:mute_music_app/src/domain/repositories/video_repository.dart';
import 'package:mute_music_app/src/domain/use_cases/mute_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/pick_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/save_video_use_case.dart';

final GetIt injector = GetIt.instance;

void setupInjector() {
  injector
    ..registerLazySingleton<ImagePicker>(ImagePicker.new)
    ..registerLazySingleton<VideoMuteDatasource>(VideoMuteDatasource.new)
    ..registerLazySingleton<VideoRepository>(
      () => VideoRepositoryImpl(injector(), injector()),
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
    ..registerFactory<MuteVideoCubit>(
      () => MuteVideoCubit(injector(), injector(), injector()),
    );
}
