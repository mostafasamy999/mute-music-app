import 'package:mute_music_app/src/domain/entities/app_language.dart';
import 'package:mute_music_app/src/domain/repositories/language_repository.dart';

class GetLanguageUseCase {
  const GetLanguageUseCase(this._repository);

  final LanguageRepository _repository;

  AppLanguage call() => _repository.current();
}
