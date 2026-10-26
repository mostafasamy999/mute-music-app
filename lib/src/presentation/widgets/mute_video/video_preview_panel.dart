import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/config/routes/routes_manager.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:mute_music_app/src/core/extensions/duration_extensions.dart';
import 'package:mute_music_app/src/domain/entities/clip_range.dart';
import 'package:mute_music_app/src/domain/entities/media_asset.dart';
import 'package:mute_music_app/src/presentation/screens/original_screen.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/audio_preview.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/image_preview.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/video_preview.dart';

typedef _Data = ({
  String? path,
  MediaKind? kind,
  bool muted,
  bool musicOnly,
  ClipRange? part,
  MediaAsset? before,
  bool converted,
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
          before: state.lastInput,
          converted: state.applied.contains(MediaOperation.convertToAudio),
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
        Expanded(child: Center(child: _preview(context, path, data))),
      ],
    );
  }

  /// One preview per kind (spec 006 §2.2). An edited file also gets the
  /// original icon (§3.2).
  Widget _preview(BuildContext context, String path, _Data data) {
    final ValueChanged<Duration>? onOriginal = _openOriginal(
      context,
      data.before,
    );
    return switch (data.kind) {
      MediaKind.image => ImagePreview(path: path),
      MediaKind.audio => AudioPreview(path: path, onOriginal: onOriginal),
      MediaKind.video ||
      null => VideoPreview(path: path, onOriginal: onOriginal),
    };
  }

  /// Null hides the icon: there is no file before, or it is gone.
  ValueChanged<Duration>? _openOriginal(
    BuildContext context,
    MediaAsset? before,
  ) {
    if (before == null || !File(before.path).existsSync()) return null;
    return (Duration at) => Navigator.of(context).pushNamed(
      Routes.original,
      arguments: OriginalArgs(file: before, startAt: at),
    );
  }

  String _label(BuildContext context, _Data data) {
    if (data.kind == MediaKind.image) return S.of(context).labelImage;
    final ClipRange? part = data.part;
    if (!data.muted && part != null) {
      return S.of(context).partLabel(part.start.clock, part.end.clock);
    }
    if (!data.muted) return S.of(context).labelOriginal;
    if (data.converted && data.kind == MediaKind.audio) {
      return S.of(context).labelAudio;
    }
    return data.musicOnly
        ? S.of(context).labelNoMusic
        : S.of(context).labelMuted;
  }
}
