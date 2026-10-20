extension DurationX on Duration {
  /// `m:ss`, or `h:mm:ss` from one hour up. Always left to right.
  String get clock {
    final int hours = inHours;
    final String minutes = inMinutes.remainder(60).toString();
    final String seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours == 0) return '$minutes:$seconds';
    return '$hours:${minutes.padLeft(2, '0')}:$seconds';
  }
}
