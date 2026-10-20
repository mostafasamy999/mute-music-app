/// A time range inside a video. Pure Dart — no Flutter imports.
class ClipRange {
  ClipRange({required this.start, required this.end})
    : assert(start >= Duration.zero && start < end, 'start must be before end');

  final Duration start;
  final Duration end;

  Duration get length => end - start;

  @override
  bool operator ==(Object other) =>
      other is ClipRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}
