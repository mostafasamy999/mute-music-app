import 'package:dio/dio.dart';
import 'package:mute_music_app/src/core/constants/model_constants.dart';
import 'package:mute_music_app/src/core/di/injector.dart';

/// A Dio kept only for large downloads. The app has no general API yet; when it
/// gets one, that instance is registered here unnamed and this one stays as is.
void setupNetwork() {
  injector.registerLazySingleton<Dio>(
    () => Dio()
      ..options.connectTimeout = const Duration(seconds: 30)
      // Dio counts this between chunks, not for the whole file.
      ..options.receiveTimeout = const Duration(minutes: 5),
    instanceName: ModelConstants.downloadDioName,
  );
}
