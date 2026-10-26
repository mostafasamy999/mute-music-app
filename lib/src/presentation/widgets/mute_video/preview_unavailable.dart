import 'package:flutter/material.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';

/// Shown instead of a preview when the file is missing or can't be opened
/// (spec 006 W11).
class PreviewUnavailable extends StatelessWidget {
  const PreviewUnavailable({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            S.of(context).previewUnavailable,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
