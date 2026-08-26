import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';

class SaveVideoButton extends StatelessWidget {
  const SaveVideoButton({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<MuteVideoCubit, MuteVideoState, bool>(
        selector: (MuteVideoState state) => state.canSave,
        builder: (BuildContext context, bool enabled) => FilledButton.tonalIcon(
          onPressed: enabled
              ? context.read<MuteVideoCubit>().saveToGallery
              : null,
          icon: const Icon(Icons.save_alt_outlined),
          label: Text(S.of(context).saveToGallery),
        ),
      );
}
