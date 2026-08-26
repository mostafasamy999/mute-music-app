import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mute_music_app/src/core/audio/pcm_io.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('pcm_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  /// The interchange format between Dart and the platform is little-endian
  /// float32, interleaved. Getting this wrong sounds like loud noise rather
  /// than throwing, so it is pinned down here.
  test('write produces interleaved float32, 4 bytes per sample', () {
    final File file = File('${dir.path}/a.pcm');
    PcmIo.write(
      file,
      Float64List.fromList(<double>[0, 0.5, -0.5]),
      Float64List.fromList(<double>[1, -1, 0.25]),
    );

    expect(file.lengthSync(), 3 * 2 * 4);
    final Uint8List bytes = file.readAsBytesSync();
    final Float32List raw = Float32List.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.lengthInBytes ~/ 4,
    );
    expect(raw[0], closeTo(0, 1e-6));
    expect(raw[1], closeTo(1, 1e-6));
    expect(raw[2], closeTo(0.5, 1e-6));
    expect(raw[3], closeTo(-1, 1e-6));
  });

  test('read splits channels back out unchanged at 44.1 kHz', () {
    final File file = File('${dir.path}/b.pcm');
    final Float64List left = Float64List.fromList(<double>[0, 0.25, -0.75, 1]);
    final Float64List right = Float64List.fromList(<double>[1, -0.5, 0.5, 0]);
    PcmIo.write(file, left, right);

    final StereoAudio audio = PcmIo.read(file, PcmIo.targetRate, 2);
    expect(audio.length, 4);
    for (int i = 0; i < 4; i++) {
      expect(audio.left[i], closeTo(left[i], 1e-6));
      expect(audio.right[i], closeTo(right[i], 1e-6));
    }
  });

  test('mono is duplicated into both channels', () {
    final File file = File('${dir.path}/c.pcm');
    final Float32List mono = Float32List.fromList(<double>[0.1, 0.2, 0.3]);
    file.writeAsBytesSync(mono.buffer.asUint8List());

    final StereoAudio audio = PcmIo.read(file, PcmIo.targetRate, 1);
    expect(audio.length, 3);
    expect(audio.left, audio.right);
    expect(audio.left[1], closeTo(0.2, 1e-6));
  });

  test('a different source rate is resampled to 44.1 kHz', () {
    final File file = File('${dir.path}/d.pcm');
    final Float64List ramp = Float64List(48000);
    for (int i = 0; i < ramp.length; i++) {
      ramp[i] = i / ramp.length;
    }
    PcmIo.write(file, ramp, ramp);

    final StereoAudio audio = PcmIo.read(file, 48000, 2);
    expect(audio.length, closeTo(44100, 2));
    // A ramp stays a ramp; only the sample count changes.
    expect(audio.left.first, closeTo(0, 1e-3));
    expect(audio.left.last, closeTo(1, 1e-2));
  });
}
