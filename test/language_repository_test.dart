import 'package:flutter_test/flutter_test.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/data/local/language_storage.dart';
import 'package:mute_music_app/src/data/repositories/language_repository_impl.dart';
import 'package:mute_music_app/src/domain/entities/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<(LanguageRepositoryImpl, SharedPreferences)> build(
    Map<String, Object> saved,
  ) async {
    SharedPreferences.setMockInitialValues(saved);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return (LanguageRepositoryImpl(LanguageStorage(prefs)), prefs);
  }

  test('nothing saved follows the phone', () async {
    final (LanguageRepositoryImpl repository, _) = await build(
      <String, Object>{},
    );

    expect(repository.current(), AppLanguage.system);
  });

  test('a saved choice comes back on the next launch', () async {
    final (LanguageRepositoryImpl repository, _) = await build(<String, Object>{
      LanguageStorage.key: 'ar',
    });

    expect(repository.current(), AppLanguage.arabic);
  });

  test('an unknown or wrongly typed value follows the phone', () async {
    final (LanguageRepositoryImpl unknown, _) = await build(<String, Object>{
      LanguageStorage.key: 'fr',
    });
    final (LanguageRepositoryImpl wrongType, _) = await build(<String, Object>{
      LanguageStorage.key: 7,
    });

    expect(unknown.current(), AppLanguage.system);
    expect(wrongType.current(), AppLanguage.system);
  });

  test('saving English stores en; phone language clears the key', () async {
    final (LanguageRepositoryImpl repository, SharedPreferences prefs) =
        await build(<String, Object>{});

    expect(
      await repository.save(AppLanguage.english),
      isA<DataSuccess<void>>(),
    );
    expect(prefs.getString(LanguageStorage.key), 'en');

    expect(await repository.save(AppLanguage.system), isA<DataSuccess<void>>());
    expect(prefs.containsKey(LanguageStorage.key), isFalse);
  });
}
