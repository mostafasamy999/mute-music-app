import 'package:flutter/widgets.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/core/constants/clip_limits.dart';
import 'package:mute_music_app/src/core/extensions/duration_extensions.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';

extension AppFailureX on AppFailure {
  String message(BuildContext context) => switch (this) {
    AppFailure.pickFailed => S.of(context).errorPickFailed,
    AppFailure.muteFailed => S.of(context).errorMuteFailed,
    AppFailure.saveFailed => S.of(context).errorSaveFailed,
    AppFailure.noVideoTrack => S.of(context).errorNoVideoTrack,
    AppFailure.permissionDenied => S.of(context).errorPermission,
    AppFailure.modelDownloadFailed => S.of(context).errorModelDownload,
    AppFailure.modelMissing => S.of(context).errorModelMissing,
    AppFailure.noAudioTrack => S.of(context).errorNoAudioTrack,
    AppFailure.musicRemovalFailed => S.of(context).errorMusicRemoval,
    AppFailure.cutFailed => S.of(context).errorCutFailed,
    AppFailure.tooLongForMusic =>
      S.of(context).errorTooLongChoosePart(ClipLimits.maxMusicDuration.clock),
    AppFailure.languageSaveFailed => S.of(context).errorLanguageSave,
  };
}
