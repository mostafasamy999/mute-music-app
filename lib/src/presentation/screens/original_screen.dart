import 'package:flutter/material.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:mute_music_app/src/domain/entities/media_asset.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/audio_preview.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/video_preview.dart';

/// What the original screen shows.
class OriginalArgs {
  const OriginalArgs({required this.file, this.startAt = Duration.zero});

  /// The file before the last operation.
  final MediaAsset file;

  /// The edited file's position, so both are compared at the same moment.
  final Duration startAt;
}

/// View only: plays the file before the last operation (spec 006 §3.2).
/// Back returns to the edited file, unchanged.
class OriginalScreen extends StatelessWidget {
  const OriginalScreen({required this.args, super.key});

  final OriginalArgs args;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(S.of(context).originalTitle)),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Center(
          child: args.file.isAudio
              ? AudioPreview(path: args.file.path, startAt: args.startAt)
              : VideoPreview(path: args.file.path, startAt: args.startAt),
        ),
      ),
    ),
  );
}
