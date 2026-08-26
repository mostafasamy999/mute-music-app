import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';

class RemoveMusicButton extends StatelessWidget {
  const RemoveMusicButton({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<MuteVideoCubit, MuteVideoState, bool>(
        selector: (MuteVideoState state) =>
            state.source != null && !state.isBusy,
        builder: (BuildContext context, bool enabled) => FilledButton.icon(
          onPressed: enabled
              ? context.read<MuteVideoCubit>().removeMusic
              : null,
          icon: const Icon(Icons.music_off_outlined),
          label: Text(S.of(context).removeMusic),
        ),
      );
}
