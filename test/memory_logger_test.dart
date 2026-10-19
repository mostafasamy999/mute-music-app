import 'package:flutter_test/flutter_test.dart';
import 'package:mute_music_app/src/core/diagnostics/memory_logger.dart';
import 'package:mute_music_app/src/data/local/device_memory_datasource.dart';

void main() {
  test('an Android line shows free, total, kill threshold and app use', () {
    const MemoryReport report = MemoryReport(
      footprintMb: 812.4,
      nativeHeapMb: 410,
      deviceTotalMb: 5625,
      heapLimitMb: 512,
      deviceAvailableMb: 2034.6,
      lowMemoryThresholdMb: 1228.8,
      lowMemory: true,
    );

    expect(
      MemoryLogger.format('removingMusic', report),
      '[MEM] removingMusic          free 2035 MB / 5625 MB  killAt 1229 MB'
      '  app 812 MB  native 410 MB  LOW-MEMORY',
    );
  });

  test('values the platform does not report are left out or shown as ?', () {
    const MemoryReport report = MemoryReport(
      footprintMb: 300,
      nativeHeapMb: -1,
      deviceTotalMb: 6144,
      heapLimitMb: -1,
      deviceAvailableMb: -1,
      lowMemoryThresholdMb: -1,
      lowMemory: false,
    );

    expect(
      MemoryLogger.format('tick', report),
      '[MEM] tick                   free ? / 6144 MB  app 300 MB',
    );
  });
}
