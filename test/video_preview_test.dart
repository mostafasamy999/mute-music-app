import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/video_preview.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'helpers/fake_video_player.dart';

/// Spec 006 S3 / W11: a missing or broken file never spins forever.
void main() {
  late FakeVideoPlayer player;

  setUp(() {
    player = FakeVideoPlayer();
    VideoPlayerPlatform.instance = player;
  });

  Future<void> pump(
    WidgetTester tester,
    String path, {
    Locale locale = const Locale('en'),
  }) => tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(body: VideoPreview(path: path)),
    ),
  );

  Finder playerFor(String path) =>
      find.byKey(ValueKey<String>('player:file://$path'));

  testWidgets('a missing file shows a message instead of spinning', (
    WidgetTester tester,
  ) async {
    await pump(tester, '/tmp/missing.mp4');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.text(
        "This file can't be played. It may have been moved or deleted.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('a good file after a missing one plays', (
    WidgetTester tester,
  ) async {
    await pump(tester, '/tmp/missing.mp4');
    await tester.pumpAndSettle();

    await pump(tester, '/tmp/good.mp4');
    await tester.pumpAndSettle();

    expect(playerFor('/tmp/good.mp4'), findsOneWidget);
    expect(
      find.text(
        "This file can't be played. It may have been moved or deleted.",
      ),
      findsNothing,
    );
  });

  testWidgets('a slow load that finishes late never replaces a newer file', (
    WidgetTester tester,
  ) async {
    await pump(tester, '/tmp/slow.mp4');
    await tester.pump();

    await pump(tester, '/tmp/good.mp4');
    await tester.pumpAndSettle();
    expect(playerFor('/tmp/good.mp4'), findsOneWidget);

    player.releaseSlow();
    await tester.pumpAndSettle();
    // The player's own dispose finishes on real async work.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(playerFor('/tmp/good.mp4'), findsOneWidget);
    expect(playerFor('/tmp/slow.mp4'), findsNothing);
    final int slowId = player.pathOf.entries
        .firstWhere((MapEntry<int, String> e) => e.value.contains('slow'))
        .key;
    expect(player.disposed, contains(slowId));
  });

  testWidgets('the message is in Arabic on an Arabic screen', (
    WidgetTester tester,
  ) async {
    await pump(tester, '/tmp/missing.mp4', locale: const Locale('ar'));
    await tester.pumpAndSettle();

    expect(
      find.text('لا يمكن تشغيل هذا الملف. ربما نُقل أو حُذف.'),
      findsOneWidget,
    );
  });
}
