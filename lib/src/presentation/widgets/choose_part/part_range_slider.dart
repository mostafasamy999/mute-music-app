import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mute_music_app/src/core/constants/clip_limits.dart';
import 'package:mute_music_app/src/domain/entities/clip_range.dart';

/// Two handles over the whole video. Time runs left to right in every
/// language, so the slider stays LTR in Arabic too.
class PartRangeSlider extends StatelessWidget {
  const PartRangeSlider({
    required this.range,
    required this.duration,
    required this.onChanged,
    super.key,
  });

  final ValueListenable<ClipRange> range;
  final Duration duration;
  final ValueChanged<ClipRange> onChanged;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: ValueListenableBuilder<ClipRange>(
      valueListenable: range,
      builder: (BuildContext context, ClipRange current, _) => RangeSlider(
        max: _ms(duration),
        values: RangeValues(_ms(current.start), _ms(current.end)),
        onChanged: (RangeValues values) {
          final ClipRange? next = _fit(values, current);
          if (next != null) onChanged(next);
        },
      ),
    ),
  );

  /// Keeps the handles at least [ClipLimits.minPartLength] apart by holding
  /// back the handle that moved.
  ClipRange? _fit(RangeValues values, ClipRange current) {
    final Duration gap = duration < ClipLimits.minPartLength
        ? duration
        : ClipLimits.minPartLength;
    Duration start = Duration(milliseconds: values.start.round());
    Duration end = Duration(milliseconds: values.end.round());
    if (start != current.start) {
      if (start > end - gap) start = end - gap;
    } else if (end < start + gap) {
      end = start + gap;
    }
    if (start < Duration.zero || end > duration || start >= end) return null;
    final ClipRange next = ClipRange(start: start, end: end);
    return next == current ? null : next;
  }

  double _ms(Duration value) => value.inMilliseconds.toDouble();
}
