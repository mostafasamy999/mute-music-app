import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';

/// Spec 006 F8: reads the text in the current file.
class ExtractTextButton extends StatelessWidget {
  const ExtractTextButton({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<MuteVideoCubit, MuteVideoState, bool>(
        selector: (MuteVideoState state) =>
            state.current != null && !state.isBusy,
        builder: (BuildContext context, bool enabled) => FilledButton.icon(
          onPressed: enabled
              ? () => context.read<MuteVideoCubit>().extractText()
              : null,
          icon: const Icon(Icons.text_snippet_outlined),
          label: Text(S.of(context).extractText),
        ),
      );
}
