import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/media_asset.dart';
import 'package:mute_music_app/src/domain/repositories/text_repository.dart';

class ExtractTextUseCase {
  const ExtractTextUseCase(this._repository);

  final TextRepository _repository;

  Future<DataState<String>> call(
    MediaAsset file, {
    void Function(double progress)? onProgress,
  }) => _repository.extractText(file, onProgress: onProgress);
}
