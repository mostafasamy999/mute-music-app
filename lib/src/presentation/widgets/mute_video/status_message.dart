import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/removal_steps.dart';

typedef _Data = ({
  MuteVideoStatus status,
  double progress,
  bool musicOnly,
  bool showsProgress,
  bool showsSteps,
});

class StatusMessage extends StatelessWidget {
  const StatusMessage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<MuteVideoCubit, MuteVideoState, _Data>(
        selector: (MuteVideoState state) => (
          status: state.status,
          progress: state.progress,
          musicOnly: state.musicOnly,
          showsProgress: state.showsProgress,
          showsSteps: state.showsSteps,
        ),
        builder: _builder,
      );

  Widget _builder(BuildContext context, _Data data) {
    if (data.showsSteps) return const RemovalSteps();
    final String? text = _text(context, data);
    if (text == null) return const SizedBox.shrink();
    return Column(
      children: <Widget>[
        Text(text, textAlign: TextAlign.center),
        if (data.showsProgress) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: data.progress > 0 ? data.progress : null,
          ),
        ],
      ],
    );
  }

  String? _text(BuildContext context, _Data data) => switch (data.status) {
    MuteVideoStatus.cutting => S.of(context).cutting,
    MuteVideoStatus.muting => S.of(context).working,
    MuteVideoStatus.preparingModel => S.of(context).downloadingModel,
    MuteVideoStatus.removingMusic => _percent(context, data.progress),
    MuteVideoStatus.saving => S.of(context).saving,
    MuteVideoStatus.muted =>
      data.musicOnly
          ? S.of(context).readyToSaveMusic
          : S.of(context).readyToSave,
    MuteVideoStatus.saved => S.of(context).savedToGallery,
    // A picked file needs no line: the actions under it say what to do.
    MuteVideoStatus.initial ||
    MuteVideoStatus.picking ||
    MuteVideoStatus.failure => null,
  };

  String _percent(BuildContext context, double progress) =>
      '${S.of(context).removingMusic}  ${(progress * 100).round()}%';
}
