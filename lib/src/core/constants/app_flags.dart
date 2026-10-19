import 'package:flutter/foundation.dart';

abstract final class AppFlags {
  /// On-device diagnostics (the memory probe). Never reachable in release.
  static const bool diagnostics = kDebugMode || kProfileMode;
}
