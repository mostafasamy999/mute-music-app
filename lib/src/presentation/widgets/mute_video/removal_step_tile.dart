import 'package:flutter/material.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';

enum RemovalStepLook { done, active, waiting }

/// One row of the music removal steps. Only the active row shows a bar and a
/// detail, so the list stays short enough to leave room for the preview.
class RemovalStepTile extends StatelessWidget {
  const RemovalStepTile({
    required this.label,
    required this.look,
    this.detail,
    this.fraction,
    super.key,
  });

  final String label;
  final RemovalStepLook look;

  /// Shown at the end of the active row, e.g. "Part 2 of 4".
  final String? detail;

  /// Null draws an indeterminate bar.
  final double? fraction;

  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool active = look == RemovalStepLook.active;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox.square(dimension: _iconSize, child: _icon(theme)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: active ? FontWeight.w600 : null,
                    color: look == RemovalStepLook.waiting
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                  ),
                ),
              ),
              if (active && detail != null)
                Text(detail!, style: theme.textTheme.bodySmall),
            ],
          ),
          if (active)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: _iconSize + AppSpacing.sm,
                top: 4,
              ),
              child: LinearProgressIndicator(value: fraction),
            ),
        ],
      ),
    );
  }

  Widget _icon(ThemeData theme) => switch (look) {
    RemovalStepLook.done => Icon(
      Icons.check_circle,
      size: _iconSize,
      color: theme.colorScheme.primary,
    ),
    RemovalStepLook.active => const Padding(
      padding: EdgeInsetsDirectional.all(2),
      child: CircularProgressIndicator(strokeWidth: 2.5),
    ),
    RemovalStepLook.waiting => Icon(
      Icons.radio_button_unchecked,
      size: _iconSize,
      color: theme.colorScheme.outline,
    ),
  };
}
