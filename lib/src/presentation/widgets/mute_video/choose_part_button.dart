import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/config/routes/routes_manager.dart';
import 'package:mute_music_app/src/domain/entities/clip_range.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/presentation/screens/choose_part_screen.dart';

class ChoosePartButton extends StatelessWidget {
  const ChoosePartButton({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<MuteVideoCubit, MuteVideoState, bool>(
        selector: (MuteVideoState state) =>
            state.source != null && !state.isBusy,
        builder: (BuildContext context, bool enabled) => OutlinedButton.icon(
          onPressed: enabled ? () => openChoosePart(context) : null,
          icon: const Icon(Icons.content_cut),
          label: Text(S.of(context).choosePart),
        ),
      );
}

/// Opens the Choose a part screen on the original, with the last range set,
/// and hands the chosen range to the cubit. Also used by the snackbar action
/// when a video is too long for Remove music.
Future<void> openChoosePart(BuildContext context) async {
  final MuteVideoCubit cubit = context.read<MuteVideoCubit>();
  final MuteVideoState state = cubit.state;
  final VideoAsset? original = state.original ?? state.source;
  if (original == null || state.isBusy) return;
  final ClipRange? range = await Navigator.of(context).pushNamed<ClipRange>(
    Routes.choosePart,
    arguments: ChoosePartArgs(
      path: original.path,
      initial: state.hasPart ? state.source?.range : null,
    ),
  );
  if (range != null) await cubit.usePart(range);
}
