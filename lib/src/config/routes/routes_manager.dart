import 'package:flutter/material.dart';
import 'package:mute_music_app/src/core/constants/app_flags.dart';
import 'package:mute_music_app/src/domain/entities/clip_range.dart';
import 'package:mute_music_app/src/presentation/screens/choose_part_screen.dart';
import 'package:mute_music_app/src/presentation/screens/memory_probe_screen.dart';
import 'package:mute_music_app/src/presentation/screens/mute_video_screen.dart';

abstract final class Routes {
  static const String muteVideo = '/';

  /// Takes [ChoosePartArgs] and pops with a [ClipRange], or null.
  static const String choosePart = '/choose-part';

  /// TEMPORARY: on-device diagnostics. Debug and profile builds only.
  static const String memoryProbe = '/memory-probe';
}

/// Every navigation in the app goes through here.
abstract final class RoutesManager {
  static Route<Object?> onGenerateRoute(RouteSettings settings) =>
      switch (settings.name) {
        Routes.muteVideo => _page(const MuteVideoScreen(), settings),
        Routes.choosePart when settings.arguments is ChoosePartArgs =>
          MaterialPageRoute<ClipRange>(
            builder: (_) =>
                ChoosePartScreen(args: settings.arguments! as ChoosePartArgs),
            settings: settings,
          ),
        Routes.memoryProbe when AppFlags.diagnostics => _page(
          const MemoryProbeScreen(),
          settings,
        ),
        _ => _page(const MuteVideoScreen(), settings),
      };

  static MaterialPageRoute<void> _page(Widget child, RouteSettings settings) =>
      MaterialPageRoute<void>(builder: (_) => child, settings: settings);
}
