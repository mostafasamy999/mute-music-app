import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/src/domain/entities/app_language.dart';
import 'package:mute_music_app/src/domain/use_cases/get_language_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/set_language_use_case.dart';

/// App-wide language choice. Lives above MaterialApp, so switching it keeps
/// every open screen and running job.
class LanguageCubit extends Cubit<AppLanguage> {
  LanguageCubit(GetLanguageUseCase getLanguage, this._setLanguage)
    : super(getLanguage());

  final SetLanguageUseCase _setLanguage;

  /// Switches at once, then saves. A failed save only means the choice is
  /// forgotten on the next launch, so it isn't worth interrupting the user.
  Future<void> select(AppLanguage language) async {
    if (language == state) return;
    emit(language);
    await _setLanguage(language);
  }
}
