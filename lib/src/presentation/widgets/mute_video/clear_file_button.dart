import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';

/// The x over the file: drops it and goes back to the empty screen
/// (spec 006 F2). Disabled while a job runs.
class ClearFileButton extends StatelessWidget {
  const ClearFileButton({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<MuteVideoCubit, MuteVideoState, bool>(
        selector: (MuteVideoState state) => state.isBusy,
        builder: (BuildContext context, bool busy) => IconButton.filledTonal(
          tooltip: S.of(context).clearFile,
          onPressed: busy ? null : context.read<MuteVideoCubit>().clear,
          icon: const Icon(Icons.close),
        ),
      );
}
