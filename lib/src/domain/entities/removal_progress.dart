/// The stages of "Remove music only", in the order they run.
enum RemovalStep { model, extract, separate, build }

/// Where a music removal job is. Pure Dart — no Flutter imports.
class RemovalProgress {
  const RemovalProgress(this.step, {this.done = 0, this.total = 0});

  final RemovalStep step;

  /// Finished units of [step]: chunks while separating, percent while
  /// downloading the model.
  final int done;

  /// 0 when the step can't tell how long it will take.
  final int total;

  /// Null for an indeterminate step.
  double? get fraction => total == 0 ? null : (done / total).clamp(0, 1);

  @override
  bool operator ==(Object other) =>
      other is RemovalProgress &&
      other.step == step &&
      other.done == done &&
      other.total == total;

  @override
  int get hashCode => Object.hash(step, done, total);

  @override
  String toString() => 'RemovalProgress($step, $done/$total)';
}
