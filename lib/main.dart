import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/config/routes/routes_manager.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:mute_music_app/src/core/constants/app_flags.dart';
import 'package:mute_music_app/src/core/diagnostics/memory_bloc_observer.dart';
import 'package:mute_music_app/src/core/diagnostics/memory_logger.dart';
import 'package:mute_music_app/src/core/di/injector.dart';
import 'package:mute_music_app/src/domain/use_cases/discard_leftovers_use_case.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupInjector();
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
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (BuildContext context) => S.of(context).appTitle,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
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
  );
}
