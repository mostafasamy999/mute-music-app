import 'package:flutter/material.dart';
import 'package:mute_music_app/src/config/theme/color_schemes.dart';

/// Shared spacing and radius tokens. Add one only when 2+ screens need it.
abstract final class AppSpacing {
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double radius = 16;
}

abstract final class AppTheme {
  static ThemeData get light => _build(AppColorSchemes.light);

  static ThemeData get dark => _build(AppColorSchemes.dark);

  static ThemeData _build(ColorScheme scheme) => ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    filledButtonTheme: FilledButtonThemeData(style: _buttonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: _buttonStyle),
  );

  static final ButtonStyle _buttonStyle = ButtonStyle(
    minimumSize: WidgetStateProperty.all(const Size.fromHeight(52)),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
    ),
  );
}
