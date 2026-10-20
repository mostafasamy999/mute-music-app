import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/app_language.dart';

abstract interface class LanguageRepository {
  /// The saved choice. Synchronous so the first frame already uses it.
  AppLanguage current();

  /// Remembers [language] for the next launch. [AppLanguage.system] clears it.
  Future<DataState<void>> save(AppLanguage language);
}
