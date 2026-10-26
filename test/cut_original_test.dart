import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/domain/entities/clip_range.dart';
import 'package:mute_music_app/src/domain/entities/media_asset.dart';
import 'package:mute_music_app/src/presentation/screens/choose_part_screen.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'helpers/fake_video_player.dart';

/// Spec 006 S8: the cut screen shows the original, resets to its full length,
/// and works for a sound file. The fake player's files are 5 s long.
void main() {
  setUp(() => VideoPlayerPlatform.instance = FakeVideoPlayer());

  Future<ClipRange? Function()> open(
    WidgetTester tester,
    ChoosePartArgs args,
  ) async {
    ClipRange? popped;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async {
              popped = await Navigator.of(context).push<ClipRange>(
                MaterialPageRoute<ClipRange>(
                  builder: (_) => ChoosePartScreen(args: args),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => popped;
  }

  final ClipRange oneToThree = ClipRange(
    start: const Duration(seconds: 1),
    end: const Duration(seconds: 3),
  );

  testWidgets('says it shows the original, with its length', (
    WidgetTester tester,
  ) async {
    await open(tester, const ChoosePartArgs(path: '/tmp/video.mp4'));

    expect(find.text('Original · 0:05'), findsOneWidget);
    // Already the whole file: nothing to reset.
    expect(find.text('Full length'), findsNothing);
  });

  testWidgets('Full length resets an earlier part to the whole original', (
    WidgetTester tester,
  ) async {
    final ClipRange? Function() popped = await open(
      tester,
      ChoosePartArgs(path: '/tmp/video.mp4', initial: oneToThree),
    );
    expect(find.text('Full length'), findsOneWidget);

    await tester.tap(find.text('Full length'));
    await tester.pump();
    expect(find.text('Full length'), findsNothing);

    await tester.tap(find.text('Use this part'));
    await tester.pumpAndSettle();
    expect(
      popped(),
      ClipRange(start: Duration.zero, end: const Duration(seconds: 5)),
    );
  });

  testWidgets('a sound shows a sound mark instead of a picture', (
    WidgetTester tester,
  ) async {
    await open(
      tester,
      const ChoosePartArgs(path: '/tmp/song.m4a', kind: MediaKind.audio),
    );

    expect(find.byIcon(Icons.graphic_eq), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('player:file:///tmp/song.m4a')),
      findsNothing,
    );
    expect(find.text('Original · 0:05'), findsOneWidget);
  });
}
