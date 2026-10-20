import 'package:flutter/material.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/presentation/widgets/language/language_sheet.dart';

/// App bar entry to the language picker.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.language),
    tooltip: S.of(context).language,
    onPressed: () => LanguageSheet.show(context),
  );
}
