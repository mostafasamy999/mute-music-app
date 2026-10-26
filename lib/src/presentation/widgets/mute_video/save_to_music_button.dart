import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';

/// Spec 006 F10: the current sound file to the phone's music storage.
class SaveToMusicButton extends StatelessWidget {
  const SaveToMusicButton({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<MuteVideoCubit, MuteVideoState, bool>(
        selector: (MuteVideoState state) =>
            state.canSave && (state.current?.isAudio ?? false),
        builder: (BuildContext context, bool enabled) => FilledButton.tonalIcon(
          onPressed: enabled
              ? context.read<MuteVideoCubit>().saveToMusic
              : null,
          icon: const Icon(Icons.library_music_outlined),
          label: Text(S.of(context).saveToMusic),
        ),
      );
}

/// Where the file went: the Music folder on Android, Files on iOS (Q5).
String savedToMusicText(BuildContext context) =>
    defaultTargetPlatform == TargetPlatform.iOS
    ? S.of(context).savedToMusicIos
    : S.of(context).savedToMusicAndroid;
