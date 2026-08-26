import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';

class StatusMessage extends StatelessWidget {
  const StatusMessage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<MuteVideoCubit, MuteVideoState, MuteVideoStatus>(
        selector: (MuteVideoState state) => state.status,
        builder: (BuildContext context, MuteVideoStatus status) =>
            _row(context, status),
      );

  Widget _row(BuildContext context, MuteVideoStatus status) {
    final String? text = _text(context, status);
    if (text == null) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (_isBusy(status)) ...<Widget>[
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(child: Text(text, textAlign: TextAlign.center)),
      ],
    );
  }

  bool _isBusy(MuteVideoStatus status) =>
      status == MuteVideoStatus.muting || status == MuteVideoStatus.saving;

  String? _text(BuildContext context, MuteVideoStatus status) =>
      switch (status) {
        MuteVideoStatus.initial => S.of(context).emptyHint,
        MuteVideoStatus.muting => S.of(context).working,
        MuteVideoStatus.saving => S.of(context).saving,
        MuteVideoStatus.muted => S.of(context).readyToSave,
        MuteVideoStatus.saved => S.of(context).savedToGallery,
        MuteVideoStatus.picking || MuteVideoStatus.failure => null,
      };
}
