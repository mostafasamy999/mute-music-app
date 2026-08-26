import 'package:flutter/material.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/pick_video_button.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/remove_sound_button.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/save_video_button.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/status_message.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/video_preview_panel.dart';

/// Ordering only. Every child owns its own BlocSelector.
class MuteVideoContent extends StatelessWidget {
  const MuteVideoContent({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(S.of(context).appTitle)),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: const Column(
          children: <Widget>[
            Expanded(child: VideoPreviewPanel()),
            SizedBox(height: AppSpacing.md),
            StatusMessage(),
            SizedBox(height: AppSpacing.md),
            PickVideoButton(),
            SizedBox(height: AppSpacing.sm),
            RemoveSoundButton(),
            SizedBox(height: AppSpacing.sm),
            SaveVideoButton(),
          ],
        ),
      ),
    ),
  );
}
