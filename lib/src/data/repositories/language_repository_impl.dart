import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/data/local/language_storage.dart';
import 'package:mute_music_app/src/domain/entities/app_language.dart';
import 'package:mute_music_app/src/domain/repositories/language_repository.dart';

class LanguageRepositoryImpl implements LanguageRepository {
  const LanguageRepositoryImpl(this._storage);

  final LanguageStorage _storage;

  @override
  AppLanguage current() {
    try {
      return AppLanguage.fromCode(_storage.read());
    } on Object {
      // A value of the wrong type from some older build: follow the phone.
      return AppLanguage.system;
    }
  }

  @override
  Future<DataState<void>> save(AppLanguage language) async {
    try {
      final bool saved = await _storage.write(language.languageCode);
      return saved
          ? const DataSuccess<void>(null)
          : const DataFailed<void>(AppFailure.languageSaveFailed);
    } on Object {
      return const DataFailed<void>(AppFailure.languageSaveFailed);
    }
  }
}
