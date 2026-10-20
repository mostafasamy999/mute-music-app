import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mute_music_app/src/bloc/language/language_cubit.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/app_language.dart';
import 'package:mute_music_app/src/domain/use_cases/get_language_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/set_language_use_case.dart';

class _MockGet extends Mock implements GetLanguageUseCase {}

class _MockSet extends Mock implements SetLanguageUseCase {}

void main() {
  late _MockGet getLanguage;
  late _MockSet setLanguage;

  setUpAll(() => registerFallbackValue(AppLanguage.system));

  setUp(() {
    getLanguage = _MockGet();
    setLanguage = _MockSet();
    when(() => getLanguage()).thenReturn(AppLanguage.arabic);
    when(
      () => setLanguage(any()),
    ).thenAnswer((_) async => const DataSuccess<void>(null));
  });

  LanguageCubit build() => LanguageCubit(getLanguage, setLanguage);

  test('starts from the saved choice', () {
    expect(build().state, AppLanguage.arabic);
  });

  blocTest<LanguageCubit, AppLanguage>(
    'picking a language switches, then saves it',
    build: build,
    act: (LanguageCubit cubit) => cubit.select(AppLanguage.english),
    expect: () => <AppLanguage>[AppLanguage.english],
    verify: (_) => verify(() => setLanguage(AppLanguage.english)).called(1),
  );

  blocTest<LanguageCubit, AppLanguage>(
    'a failed save still switches for this session',
    setUp: () => when(() => setLanguage(any())).thenAnswer(
      (_) async => const DataFailed<void>(AppFailure.languageSaveFailed),
    ),
    build: build,
    act: (LanguageCubit cubit) => cubit.select(AppLanguage.system),
    expect: () => <AppLanguage>[AppLanguage.system],
  );

  blocTest<LanguageCubit, AppLanguage>(
    'picking the current language does nothing',
    build: build,
    act: (LanguageCubit cubit) => cubit.select(AppLanguage.arabic),
    expect: () => <AppLanguage>[],
    verify: (_) => verifyNever(() => setLanguage(any())),
  );
}
