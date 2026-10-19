import 'package:flutter/services.dart';

/// One snapshot of how much memory this app is using right now.
class MemoryReport {
  const MemoryReport({
    required this.footprintMb,
    required this.nativeHeapMb,
    required this.deviceTotalMb,
    required this.heapLimitMb,
    required this.deviceAvailableMb,
    required this.lowMemoryThresholdMb,
    required this.lowMemory,
  });

  final double footprintMb;
  final double nativeHeapMb;
  final double deviceTotalMb;
  final double heapLimitMb;

  /// Free RAM on the whole device (Android). On iOS, what this app may still
  /// allocate before jetsam kills it.
  final double deviceAvailableMb;

  /// Android starts killing apps once free RAM drops below this. -1 on iOS.
  final double lowMemoryThresholdMb;

  /// Android already considers the device low on memory.
  final bool lowMemory;
}

class DeviceMemoryDatasource {
  static const MethodChannel _channel = MethodChannel(
    'com.mostafasamy.mutemusic/video',
  );

  Future<MemoryReport> read() async {
    final Map<Object?, Object?>? map = await _channel
        .invokeMethod<Map<Object?, Object?>>('memoryReport');
    double at(String key) => (map?[key] as num?)?.toDouble() ?? -1;
    return MemoryReport(
      footprintMb: at('footprintMb'),
      nativeHeapMb: at('nativeHeapMb'),
      deviceTotalMb: at('deviceTotalMb'),
      heapLimitMb: at('heapLimitMb'),
      deviceAvailableMb: at('deviceAvailableMb'),
      lowMemoryThresholdMb: at('lowMemoryThresholdMb'),
      lowMemory: map?['lowMemory'] == true,
    );
  }
}
