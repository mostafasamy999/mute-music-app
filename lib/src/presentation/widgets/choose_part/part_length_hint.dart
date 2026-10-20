import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:mute_music_app/src/core/constants/clip_limits.dart';
import 'package:mute_music_app/src/core/extensions/duration_extensions.dart';
import 'package:mute_music_app/src/domain/entities/clip_range.dart';

/// Shown only while the part is too long for Remove music.
class PartLengthHint extends StatelessWidget {
  const PartLengthHint({required this.range, super.key});

  final ValueListenable<ClipRange> range;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ClipRange>(
    valueListenable: range,
    builder: (BuildContext context, ClipRange current, _) {
      if (current.length <= ClipLimits.maxMusicDuration) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
        child: Text(
          S.of(context).partTooLongForMusic(ClipLimits.maxMusicDuration.clock),
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    },
  );
}
