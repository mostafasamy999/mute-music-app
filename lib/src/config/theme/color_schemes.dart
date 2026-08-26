import 'package:flutter/material.dart';

/// The single source of colour for the app. Nothing else defines colours.
abstract final class AppColorSchemes {
  static const Color seed = Colors.indigo;

  static final ColorScheme light = ColorScheme.fromSeed(seedColor: seed);

  static final ColorScheme dark = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  );
}
