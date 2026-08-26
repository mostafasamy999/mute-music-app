import 'package:flutter/widgets.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';

extension AppFailureX on AppFailure {
  String message(BuildContext context) => switch (this) {
    AppFailure.pickFailed => S.of(context).errorPickFailed,
    AppFailure.muteFailed => S.of(context).errorMuteFailed,
    AppFailure.saveFailed => S.of(context).errorSaveFailed,
    AppFailure.noVideoTrack => S.of(context).errorNoVideoTrack,
    AppFailure.permissionDenied => S.of(context).errorPermission,
  };
}
