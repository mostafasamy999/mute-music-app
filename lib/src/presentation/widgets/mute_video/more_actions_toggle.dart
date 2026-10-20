import 'package:flutter/material.dart';
import 'package:mute_music_app/generated/l10n.dart';

/// Shows or hides the actions that aren't the obvious next step.
class MoreActionsToggle extends StatelessWidget {
  const MoreActionsToggle({
    required this.expanded,
    required this.onPressed,
    super.key,
  });

  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
    label: Text(
      expanded ? S.of(context).fewerActions : S.of(context).moreActions,
    ),
  );
}
