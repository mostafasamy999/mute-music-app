/// Length rules for choosing a part of a video (spec 003).
abstract final class ClipLimits {
  /// Remove music keeps the whole audio track in memory, so a longer source
  /// has to be cut to a part first. Open question 003 P2 / 001 Q1.
  static const Duration maxMusicDuration = Duration(minutes: 5);

  /// The handles on the range slider can't get closer than this.
  static const Duration minPartLength = Duration(seconds: 1);

  /// A range this close to both ends counts as the whole video.
  static const Duration wholeVideoTolerance = Duration(milliseconds: 500);
}
