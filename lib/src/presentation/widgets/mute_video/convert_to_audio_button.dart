import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';

/// Spec 006 F7: the current video's audio into an .m4a sound file.
class ConvertToAudioButton extends StatelessWidget {
  const ConvertToAudioButton({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<MuteVideoCubit, MuteVideoState, bool>(
        selector: (MuteVideoState state) =>
            (state.current?.isVideo ?? false) && !state.isBusy,
        builder: (BuildContext context, bool enabled) => FilledButton.icon(
          onPressed: enabled
              ? context.read<MuteVideoCubit>().convertToAudio
              : null,
          icon: const Icon(Icons.audiotrack_outlined),
          label: Text(S.of(context).convertToAudio),
        ),
      );
}
