import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/app_language.dart';
import 'package:mute_music_app/src/domain/repositories/language_repository.dart';

class SetLanguageUseCase {
  const SetLanguageUseCase(this._repository);

  final LanguageRepository _repository;

  Future<DataState<void>> call(AppLanguage language) =>
      _repository.save(language);
}
