import 'package:mute_music_app/src/core/resources/app_failure.dart';

/// Result of an operation that can fail. Repositories return this to use cases.
sealed class DataState<T> {
  const DataState();
}

final class DataSuccess<T> extends DataState<T> {
  const DataSuccess(this.data);

  final T data;
}

final class DataFailed<T> extends DataState<T> {
  const DataFailed(this.failure);

  final AppFailure failure;
}
