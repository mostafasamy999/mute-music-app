import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/config/routes/routes_manager.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:mute_music_app/src/core/constants/app_flags.dart';
import 'package:mute_music_app/src/presentation/widgets/language/language_button.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/add_media_button.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/clear_file_button.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/cut_file_button.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/mute_video_actions.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/status_message.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/video_preview_panel.dart';

/// Ordering only. Every child owns its own BlocSelector.
class MuteVideoContent extends StatelessWidget {
  const MuteVideoContent({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(S.of(context).appTitle),
      // TEMPORARY: entry to the on-device memory probe. Remove with it.
      actions: <Widget>[
        const LanguageButton(),
        if (AppFlags.diagnostics)
          IconButton(
            icon: const Icon(Icons.memory),
            onPressed: () =>
                Navigator.of(context).pushNamed(Routes.memoryProbe),
          ),
      ],
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        // Empty: only the add widget under the app bar (spec 006 §2.1).
        child: BlocSelector<MuteVideoCubit, MuteVideoState, bool>(
          selector: (MuteVideoState state) => state.source == null,
          builder: (_, bool empty) =>
              empty ? const AddMediaButton() : const _FileLayout(),
        ),
      ),
    ),
  );
}

class _FileLayout extends StatelessWidget {
  const _FileLayout();

  @override
  Widget build(BuildContext context) => const Column(
    children: <Widget>[
      Expanded(
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: VideoPreviewPanel()),
            PositionedDirectional(top: 0, end: 0, child: ClearFileButton()),
            PositionedDirectional(top: 0, start: 0, child: CutFileButton()),
          ],
        ),
      ),
      SizedBox(height: AppSpacing.md),
      StatusMessage(),
      SizedBox(height: AppSpacing.md),
      MuteVideoActions(),
    ],
  );
}
