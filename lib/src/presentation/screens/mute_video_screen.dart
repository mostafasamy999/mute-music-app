import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/core/di/injector.dart';
import 'package:mute_music_app/src/core/extensions/failure_extensions.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/mute_video_content.dart';

/// Actions only: provider, listener, toasts. No layout, no data.
class MuteVideoScreen extends StatelessWidget {
  const MuteVideoScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<MuteVideoCubit>(
    create: (_) => injector<MuteVideoCubit>(),
    child: BlocListener<MuteVideoCubit, MuteVideoState>(
      listenWhen: (MuteVideoState previous, MuteVideoState current) =>
          previous.status != current.status,
      listener: _onStatusChanged,
      child: const MuteVideoContent(),
    ),
  );

  void _onStatusChanged(BuildContext context, MuteVideoState state) {
    switch (state.status) {
      case MuteVideoStatus.saved:
        _showToast(context, S.of(context).savedToGallery);
      case MuteVideoStatus.failure:
        final String? text = state.failure?.message(context);
        if (text != null) _showToast(context, text);
      case MuteVideoStatus.initial:
      case MuteVideoStatus.picking:
      case MuteVideoStatus.muting:
      case MuteVideoStatus.muted:
      case MuteVideoStatus.saving:
        break;
    }
  }

  void _showToast(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}
