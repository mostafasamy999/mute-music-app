import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mute_music_app/src/data/local/device_memory_datasource.dart';

/// TEMPORARY. Prints free RAM to the console (logcat `I/flutter`) every few
/// seconds and on every job step, so a killed app leaves a trail showing
/// whether memory was the reason. Filter with: `adb logcat | grep '\[MEM\]'`.
class MemoryLogger {
  MemoryLogger(this._memory, {this.every = const Duration(seconds: 2)});

  final DeviceMemoryDatasource _memory;
  final Duration every;

  /// Time since this logger was made, printed on every line so steps can be
  /// timed from the log alone.
  final Stopwatch _clock = Stopwatch()..start();

  Timer? _timer;
  AppLifecycleListener? _lifecycle;

  void start() {
    if (_timer != null) return;
    unawaited(mark('start'));
    _timer = Timer.periodic(every, (_) => unawaited(mark('tick')));
    // Being sent to the background is when the OS is most likely to kill us.
    _lifecycle = AppLifecycleListener(
      onStateChange: (AppLifecycleState state) =>
          unawaited(mark('app ${state.name}')),
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _lifecycle?.dispose();
    _lifecycle = null;
  }

  /// Logs one line now, tagged with [label].
  Future<void> mark(String label) async {
    try {
      final String at = (_clock.elapsedMilliseconds / 1000).toStringAsFixed(1);
      debugPrint('${format(label, await _memory.read())}  +${at}s');
    } on Object catch (error) {
      debugPrint('[MEM] $label  read failed: $error');
    }
  }

  static String format(String label, MemoryReport report) {
    final StringBuffer line = StringBuffer('[MEM] ${label.padRight(22)}')
      ..write(' free ${_mb(report.deviceAvailableMb)}')
      ..write(' / ${_mb(report.deviceTotalMb)}');
    if (report.lowMemoryThresholdMb >= 0) {
      line.write('  killAt ${_mb(report.lowMemoryThresholdMb)}');
    }
    line.write('  app ${_mb(report.footprintMb)}');
    if (report.nativeHeapMb >= 0) {
      line.write('  native ${_mb(report.nativeHeapMb)}');
    }
    if (report.lowMemory) line.write('  LOW-MEMORY');
    return line.toString();
  }

  static String _mb(double value) =>
      value < 0 ? '?' : '${value.toStringAsFixed(0)} MB';
}
