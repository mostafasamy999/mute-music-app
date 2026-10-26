import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:mute_music_app/src/core/extensions/duration_extensions.dart';
import 'package:mute_music_app/src/domain/entities/clip_range.dart';
import 'package:mute_music_app/src/domain/entities/media_asset.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/audio_preview.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/image_preview.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/video_preview.dart';

typedef _Data = ({
  String? path,
  MediaKind? kind,
  bool muted,
  bool musicOnly,
  ClipRange? part,
});

class VideoPreviewPanel extends StatelessWidget {
  const VideoPreviewPanel({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<MuteVideoCubit, MuteVideoState, _Data>(
        selector: (MuteVideoState state) => (
          path: state.muted?.path ?? state.source?.path,
          kind: (state.muted ?? state.source)?.kind,
          muted: state.muted != null,
          musicOnly: state.musicOnly,
          part: state.hasPart ? state.source?.range : null,
        ),
        builder: _builder,
      );

  Widget _builder(BuildContext context, _Data data) {
    final String? path = data.path;
    // The empty screen shows the add widget instead (spec 006 §2.1).
    if (path == null) return const SizedBox.shrink();
    return Column(
      children: <Widget>[
        Text(
          _label(context, data),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(child: Center(child: _preview(path, data.kind))),
      ],
    );
  }

  /// One preview per kind (spec 006 §2.2).
  Widget _preview(String path, MediaKind? kind) => switch (kind) {
    MediaKind.image => ImagePreview(path: path),
    MediaKind.audio => AudioPreview(path: path),
    MediaKind.video || null => VideoPreview(path: path),
  };

  String _label(BuildContext context, _Data data) {
    if (data.kind == MediaKind.image) return S.of(context).labelImage;
    final ClipRange? part = data.part;
    if (!data.muted && part != null) {
      return S.of(context).partLabel(part.start.clock, part.end.clock);
    }
    if (!data.muted) return S.of(context).labelOriginal;
    return data.musicOnly
        ? S.of(context).labelNoMusic
        : S.of(context).labelMuted;
  }
}
