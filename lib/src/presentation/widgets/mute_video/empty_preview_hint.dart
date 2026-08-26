import 'package:flutter/material.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';

class EmptyPreviewHint extends StatelessWidget {
  const EmptyPreviewHint({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: 64,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
