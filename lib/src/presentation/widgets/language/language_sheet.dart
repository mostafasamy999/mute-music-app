import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/language/language_cubit.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:mute_music_app/src/domain/entities/app_language.dart';

/// Phone language, English or Arabic. Picking one closes the sheet; the app
/// has already switched by then.
class LanguageSheet extends StatelessWidget {
  const LanguageSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const LanguageSheet(),
  );

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, AppLanguage>(
        builder: (BuildContext context, AppLanguage current) => SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
            child: RadioGroup<AppLanguage>(
              groupValue: current,
              onChanged: (AppLanguage? language) => _pick(context, language),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final AppLanguage language in AppLanguage.values)
                    RadioListTile<AppLanguage>(
                      value: language,
                      title: Text(_name(context, language)),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

  void _pick(BuildContext context, AppLanguage? language) {
    if (language == null) return;
    context.read<LanguageCubit>().select(language);
    Navigator.of(context).pop();
  }

  /// Language names stay in their own language, so someone stuck in the
  /// wrong one can still find theirs.
  String _name(BuildContext context, AppLanguage language) =>
      switch (language) {
        AppLanguage.system => S.of(context).languageSystem,
        AppLanguage.english => 'English',
        AppLanguage.arabic => 'العربية',
      };
}
