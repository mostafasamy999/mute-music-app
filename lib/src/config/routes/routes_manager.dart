import 'package:flutter/material.dart';
import 'package:mute_music_app/src/presentation/screens/mute_video_screen.dart';

abstract final class Routes {
  static const String muteVideo = '/';
}

/// Every navigation in the app goes through here.
abstract final class RoutesManager {
  static Route<void> onGenerateRoute(RouteSettings settings) =>
      switch (settings.name) {
        Routes.muteVideo => _page(const MuteVideoScreen(), settings),
        _ => _page(const MuteVideoScreen(), settings),
      };

  static MaterialPageRoute<void> _page(Widget child, RouteSettings settings) =>
      MaterialPageRoute<void>(builder: (_) => child, settings: settings);
}
