import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';

typedef _Data = ({bool busy, bool hasSource});

class PickVideoButton extends StatelessWidget {
  const PickVideoButton({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<MuteVideoCubit, MuteVideoState, _Data>(
        selector: (MuteVideoState state) =>
            (busy: state.isBusy, hasSource: state.source != null),
        builder: (BuildContext context, _Data data) => OutlinedButton.icon(
          onPressed: data.busy
              ? null
              : context.read<MuteVideoCubit>().pickVideo,
          icon: const Icon(Icons.video_library_outlined),
          label: Text(
            data.hasSource
                ? S.of(context).pickAnotherVideo
                : S.of(context).pickVideo,
          ),
        ),
      );
}
