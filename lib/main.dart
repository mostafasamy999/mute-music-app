import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/config/routes/routes_manager.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:mute_music_app/src/core/di/injector.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupInjector();
  runApp(const MuteMusicApp());
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
