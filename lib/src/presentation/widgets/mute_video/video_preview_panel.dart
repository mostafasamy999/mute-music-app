import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/empty_preview_hint.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/video_preview.dart';

typedef _Data = ({String? path, bool muted});

class VideoPreviewPanel extends StatelessWidget {
  const VideoPreviewPanel({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<MuteVideoCubit, MuteVideoState, _Data>(
        selector: (MuteVideoState state) => (
          path: state.muted?.path ?? state.source?.path,
          muted: state.muted != null,
        ),
        builder: _builder,
      );

  Widget _builder(BuildContext context, _Data data) {
    final String? path = data.path;
    if (path == null) return const EmptyPreviewHint();
    return Column(
      children: <Widget>[
        Text(
          data.muted ? S.of(context).labelMuted : S.of(context).labelOriginal,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(child: Center(child: VideoPreview(path: path))),
      ],
    );
  }
}
