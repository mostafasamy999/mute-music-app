import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mute_music_app/src/data/local/video_mute_datasource.dart';

/// Spec 006 S12 on a real device or simulator: offline text recognition
/// (Tesseract on Android, Vision on iOS). The image is drawn here with the
/// system fonts, so nothing has to be staged on the device.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final VideoMuteDatasource native = VideoMuteDatasource();

  Future<String> drawText(String name, String text, TextDirection dir) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Size size = Size(1200, 300);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.black, fontSize: 96),
      ),
      textDirection: dir,
    )..layout(maxWidth: size.width - 80);
    painter.paint(canvas, const Offset(40, 80));
    final ui.Image image = await recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final ByteData? png = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final File file = File('${Directory.systemTemp.path}/$name.png')
      ..writeAsBytesSync(png!.buffer.asUint8List());
    return file.path;
  }

  testWidgets('reads English text', (_) async {
    final String path = await drawText(
      'ocr_en',
      'Hello World',
      TextDirection.ltr,
    );

    final String text = await native.recognizeText(path);

    expect(text.toLowerCase(), contains('hello'));
    expect(text.toLowerCase(), contains('world'));
  });

  testWidgets('reads Arabic text', (_) async {
    if (Platform.isIOS) {
      const MethodChannel channel = MethodChannel(
        'com.mostafasamy.mutemusic/video',
      );
      final bool? arabic = await channel.invokeMethod<bool>(
        'ocrSupportsArabic',
      );
      expect(arabic, isTrue, reason: 'This iOS version has no Arabic OCR');
    }
    final String path = await drawText(
      'ocr_ar',
      'مرحبا بالعالم',
      TextDirection.rtl,
    );

    final String text = await native.recognizeText(path);

    expect(text, contains('مرحبا'));
  });

  testWidgets('an unreadable file fails with unreadable_image', (_) async {
    final File junk = File('${Directory.systemTemp.path}/not_an_image.png')
      ..writeAsStringSync('nope');

    await expectLater(
      native.recognizeText(junk.path),
      throwsA(
        isA<PlatformException>().having(
          (PlatformException e) => e.code,
          'code',
          'unreadable_image',
        ),
      ),
    );
  });
}
