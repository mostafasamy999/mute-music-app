import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show Bidi;
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';

/// What the user picked on the Text screen besides going back.
enum TextScreenResult { readAgain }

/// The extracted text, editable, with Copy (spec 006 §5). Edits go back to
/// the cubit, so opening the text again shows them (Q10).
///
/// Owns the text controller, so it is stateful, but the build reads only the
/// controller (no setState).
class TextScreen extends StatefulWidget {
  const TextScreen({super.key});

  /// Opens the screen over [context]'s cubit. Pops with
  /// [TextScreenResult.readAgain] when the user asks to read the file again.
  static Future<TextScreenResult?> open(BuildContext context) {
    final MuteVideoCubit cubit = context.read<MuteVideoCubit>();
    return Navigator.of(context).push<TextScreenResult>(
      MaterialPageRoute<TextScreenResult>(
        builder: (_) => BlocProvider<MuteVideoCubit>.value(
          value: cubit,
          child: const TextScreen(),
        ),
      ),
    );
  }

  @override
  State<TextScreen> createState() => _TextScreenState();
}

class _TextScreenState extends State<TextScreen> {
  late final TextEditingController _text = TextEditingController(
    text: context.read<MuteVideoCubit>().state.text ?? '',
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String copied = S.of(context).copied;
    await Clipboard.setData(ClipboardData(text: _text.text));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(copied)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(S.of(context).textTitle),
      actions: <Widget>[
        IconButton(
          tooltip: S.of(context).readAgain,
          icon: const Icon(Icons.refresh),
          onPressed: () =>
              Navigator.of(context).pop(TextScreenResult.readAgain),
        ),
        TextButton.icon(
          onPressed: _copy,
          icon: const Icon(Icons.copy),
          label: Text(S.of(context).copyText),
        ),
      ],
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _text,
          builder: (BuildContext context, TextEditingValue value, _) =>
              TextField(
                controller: _text,
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                // The text's own direction, not the app's: Arabic text reads
                // right to left even in the English UI (spec 006 §5).
                textDirection: Bidi.detectRtlDirectionality(value.text)
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                onChanged: context.read<MuteVideoCubit>().updateText,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
        ),
      ),
    ),
  );
}
