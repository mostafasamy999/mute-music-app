import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/language/language_cubit.dart';
import 'package:mute_music_app/src/config/routes/routes_manager.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:mute_music_app/src/core/constants/app_flags.dart';
import 'package:mute_music_app/src/core/diagnostics/memory_bloc_observer.dart';
import 'package:mute_music_app/src/core/diagnostics/memory_logger.dart';
import 'package:mute_music_app/src/core/di/injector.dart';
import 'package:mute_music_app/src/domain/entities/app_language.dart';
import 'package:mute_music_app/src/domain/use_cases/discard_leftovers_use_case.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupInjector(await SharedPreferences.getInstance());
  unawaited(injector<DiscardLeftoversUseCase>()());
  if (AppFlags.diagnostics) _logMemory();
  runApp(const MuteMusicApp());
}

/// TEMPORARY: prints free RAM to the console while the app runs.
void _logMemory() {
  final MemoryLogger logger = injector<MemoryLogger>()..start();
  Bloc.observer = MemoryBlocObserver(logger);
}

class MuteMusicApp extends StatelessWidget {
  const MuteMusicApp({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<LanguageCubit>.value(
    value: injector<LanguageCubit>(),
    child: BlocBuilder<LanguageCubit, AppLanguage>(
      builder: (BuildContext context, AppLanguage language) => MaterialApp(
        onGenerateTitle: (BuildContext context) => S.of(context).appTitle,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        // Null follows the phone; Flutter falls back to English (the first
        // supported locale) for any language the app doesn't have.
        locale: switch (language.languageCode) {
          final String code => Locale(code),
          null => null,
        },
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        debugShowCheckedModeBanner: false,
        supportedLocales: S.delegate.supportedLocales,
        initialRoute: Routes.muteVideo,
        onGenerateRoute: RoutesManager.onGenerateRoute,
      ),
    ),
  );
}
