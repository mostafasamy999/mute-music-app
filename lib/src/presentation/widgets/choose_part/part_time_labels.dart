import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/core/extensions/duration_extensions.dart';
import 'package:mute_music_app/src/domain/entities/clip_range.dart';

/// Start on the left, length in the middle, end on the right, under the
/// matching handles. LTR like the slider; only the words are translated.
class PartTimeLabels extends StatelessWidget {
  const PartTimeLabels({required this.range, super.key});

  final ValueListenable<ClipRange> range;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: ValueListenableBuilder<ClipRange>(
      valueListenable: range,
      builder: (BuildContext context, ClipRange current, _) {
        final TextStyle? style = Theme.of(context).textTheme.bodySmall;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(S.of(context).partStart(current.start.clock), style: style),
            Text(
              S.of(context).partLength(current.length.clock),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(S.of(context).partEnd(current.end.clock), style: style),
          ],
        );
      },
    ),
  );
}
