import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/config/routes/routes_manager.dart';
import 'package:mute_music_app/src/domain/entities/media_asset.dart';
import 'package:mute_music_app/src/presentation/screens/original_screen.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/video_preview_panel.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'helpers/fake_video_player.dart';

class _MockCubit extends MockCubit<MuteVideoState> implements MuteVideoCubit {}

/// Spec 006 S9: the file before the last operation, and the screen that
/// shows it.
void main() {
  const MediaAsset added = MediaAsset(path: '/tmp/video.mp4');
  const MediaAsset part = MediaAsset(path: '/tmp/part_1.mp4');
  const MediaAsset result = MediaAsset(path: '/tmp/nomusic_1.mp4');

  group('state', () {
    test('a part remembers the added file as the file before', () {
      const MuteVideoState picked = MuteVideoState(
        source: added,
        original: added,
      );
      expect(picked.lastInput, isNull);
      expect(picked.withPart(part).lastInput, added);
    });

    test('going back to the whole file has no file before', () {
      const MuteVideoState cut = MuteVideoState(
        source: part,
        original: added,
        lastInput: added,
      );
      expect(cut.withPart(added).lastInput, isNull);
    });

    test('a result remembers its input and adds its operation', () {
      const MuteVideoState cut = MuteVideoState(
        source: part,
        original: added,
        lastInput: added,
      );
      final MuteVideoState done = cut.withResult(
        result,
        input: part,
        operation: MediaOperation.removeMusic,
      );
      expect(done.lastInput, part);
      expect(done.applied, <MediaOperation>{MediaOperation.removeMusic});
      expect(done.musicOnly, isTrue);
      expect(done.current, result);
    });

    test('a new cut forgets earlier operations (A1 starts again)', () {
      const MuteVideoState done = MuteVideoState(
        source: part,
        original: added,
        muted: result,
        applied: <MediaOperation>{MediaOperation.removeMusic},
        lastInput: part,
      );
      expect(done.withPart(part).applied, isEmpty);
    });
  });

  group('panel', () {
    late FakeVideoPlayer player;
    late _MockCubit cubit;
    late Directory dir;

    setUp(() {
      player = FakeVideoPlayer();
      VideoPlayerPlatform.instance = player;
      cubit = _MockCubit();
      dir = Directory.systemTemp.createTempSync('original');
    });

    tearDown(() => dir.deleteSync(recursive: true));

    Future<void> pump(WidgetTester tester, MuteVideoState state) async {
      whenListen(
        cubit,
        const Stream<MuteVideoState>.empty(),
        initialState: state,
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          onGenerateRoute: RoutesManager.onGenerateRoute,
          home: Scaffold(
            body: BlocProvider<MuteVideoCubit>.value(
              value: cubit,
              child: const VideoPreviewPanel(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    MediaAsset existing(String name) {
      final File file = File('${dir.path}/$name')..writeAsBytesSync(<int>[0]);
      return MediaAsset(path: file.path);
    }

    testWidgets('an edited file opens the file before, at the same moment', (
      WidgetTester tester,
    ) async {
      final MediaAsset before = existing('part_1.mp4');
      await pump(
        tester,
        MuteVideoState(
          status: MuteVideoStatus.muted,
          source: before,
          original: added,
          muted: result,
          musicOnly: true,
          applied: const <MediaOperation>{MediaOperation.removeMusic},
          lastInput: before,
        ),
      );

      await tester.tap(find.byTooltip('Show the file before this change'));
      await tester.pumpAndSettle();

      expect(find.byType(OriginalScreen), findsOneWidget);
      expect(find.text('Before the last change'), findsOneWidget);
      expect(
        find.byKey(ValueKey<String>('player:file://${before.path}')),
        findsOneWidget,
      );
    });

    testWidgets('the added file alone has no original icon', (
      WidgetTester tester,
    ) async {
      final MediaAsset file = existing('video.mp4');
      await pump(tester, MuteVideoState(source: file, original: file));

      expect(find.byTooltip('Show the file before this change'), findsNothing);
    });

    testWidgets('the icon hides when the file before is gone', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const MuteVideoState(
          source: part,
          original: added,
          lastInput: MediaAsset(path: '/tmp/gone/video.mp4'),
        ),
      );

      expect(find.byTooltip('Show the file before this change'), findsNothing);
    });
  });

  testWidgets('the original screen starts at the handed-over moment', (
    WidgetTester tester,
  ) async {
    final FakeVideoPlayer player = FakeVideoPlayer();
    VideoPlayerPlatform.instance = player;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: const OriginalScreen(
          args: OriginalArgs(file: part, startAt: Duration(seconds: 2)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(player.seeks, contains(const Duration(seconds: 2)));
  });
}
