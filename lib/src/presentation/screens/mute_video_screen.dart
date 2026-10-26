import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/core/di/injector.dart';
import 'package:mute_music_app/src/core/extensions/failure_extensions.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/data/local/speech_datasource.dart';
import 'package:mute_music_app/src/presentation/screens/text_screen.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/cut_file_button.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/mute_video_content.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/save_to_music_button.dart';

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
      case MuteVideoStatus.savedToMusic:
        _showToast(context, savedToMusicText(context));
      case MuteVideoStatus.textReady:
        _openText(context);
      case MuteVideoStatus.confirmSpeechDownload:
        _askSpeechDownload(context);
      case MuteVideoStatus.failure:
        final String? text = state.failure?.message(context);
        if (text == null) return;
        _showToast(
          context,
          text,
          // Too long for Remove music or for reading: offer the way out.
          action:
              state.failure == AppFailure.tooLongForMusic ||
                  state.failure == AppFailure.tooLongForText
              ? SnackBarAction(
                  label: S.of(context).choosePart,
                  onPressed: () => openChoosePart(context),
                )
              : null,
        );
      case MuteVideoStatus.initial:
      case MuteVideoStatus.picking:
      case MuteVideoStatus.cutting:
      case MuteVideoStatus.muting:
      case MuteVideoStatus.converting:
      case MuteVideoStatus.extracting:
      case MuteVideoStatus.downloadingSpeech:
      case MuteVideoStatus.preparingModel:
      case MuteVideoStatus.removingMusic:
      case MuteVideoStatus.muted:
      case MuteVideoStatus.saving:
        break;
    }
  }

  Future<void> _openText(BuildContext context) async {
    final MuteVideoCubit cubit = context.read<MuteVideoCubit>();
    final TextScreenResult? result = await TextScreen.open(context);
    cubit.closeText();
    if (result == TextScreenResult.readAgain) {
      await cubit.extractText(again: true);
    }
  }

  /// Spec 006 S14: the speech model is a one-time ~148 MB download, so the
  /// user decides (Wi-Fi is recommended).
  Future<void> _askSpeechDownload(BuildContext context) async {
    final MuteVideoCubit cubit = context.read<MuteVideoCubit>();
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialog) => AlertDialog(
        title: Text(S.of(dialog).speechModelTitle),
        content: Text(S.of(dialog).speechModelBody(speechModelMegabytes)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(S.of(dialog).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(S.of(dialog).download),
          ),
        ],
      ),
    );
    if (yes ?? false) {
      await cubit.downloadSpeechModel();
    } else {
      cubit.declineSpeechDownload();
    }
  }

  void _showToast(BuildContext context, String text, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), action: action));
  }
}
