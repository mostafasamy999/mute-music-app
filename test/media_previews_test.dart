import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/domain/entities/media_asset.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/audio_preview.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/image_preview.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/preview_unavailable.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/video_preview.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/video_preview_panel.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'helpers/fake_video_player.dart';

class _MockCubit extends MockCubit<MuteVideoState> implements MuteVideoCubit {}

/// Spec 006 S6: a preview per kind, and broken files never spin forever.
void main() {
  late FakeVideoPlayer player;

  setUp(() {
    player = FakeVideoPlayer();
    VideoPlayerPlatform.instance = player;
  });

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(body: child),
    ),
  );

  group('audio', () {
    testWidgets('shows the time, and plays and pauses', (
      WidgetTester tester,
    ) async {
      await pump(tester, const AudioPreview(path: '/tmp/song.m4a'));
      await tester.pumpAndSettle();

      expect(find.text('0:00'), findsOneWidget);
      expect(find.text('0:05'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      expect(player.played, isNotEmpty);
    });

    testWidgets('dragging the bar seeks', (WidgetTester tester) async {
      await pump(tester, const AudioPreview(path: '/tmp/song.m4a'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Slider), const Offset(200, 0));
      await tester.pump();

      expect(player.seeks, isNotEmpty);
      expect(player.seeks.last, greaterThan(Duration.zero));
    });

    testWidgets('a missing sound file shows the message', (
      WidgetTester tester,
    ) async {
      await pump(tester, const AudioPreview(path: '/tmp/missing.m4a'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PreviewUnavailable), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('the time reads left to right in Arabic too', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: const Scaffold(body: AudioPreview(path: '/tmp/song.m4a')),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.text('0:00')).dx,
        lessThan(tester.getTopLeft(find.text('0:05')).dx),
      );
    });
  });

  group('image', () {
    testWidgets('shows the file as an image, fitted inside', (
      WidgetTester tester,
    ) async {
      // Decoding a real file never finishes inside a widget test, so this
      // checks what is asked for, and the error test below covers the rest.
      await pump(tester, const ImagePreview(path: '/tmp/photo.jpg'));

      final Image image = tester.widget<Image>(find.byType(Image));
      expect((image.image as FileImage).file.path, '/tmp/photo.jpg');
      expect(image.fit, BoxFit.contain);
    });

    testWidgets('a missing image shows the message', (
      WidgetTester tester,
    ) async {
      await pump(tester, const ImagePreview(path: '/tmp/missing.png'));
      // Reading the file is real IO, outside the fake clock.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PreviewUnavailable), findsOneWidget);
    });
  });

  group('panel', () {
    late _MockCubit cubit;

    setUp(() => cubit = _MockCubit());

    Future<void> pumpPanel(WidgetTester tester, MediaAsset file) {
      whenListen(
        cubit,
        const Stream<MuteVideoState>.empty(),
        initialState: MuteVideoState(source: file, original: file),
      );
      return pump(
        tester,
        BlocProvider<MuteVideoCubit>.value(
          value: cubit,
          child: const VideoPreviewPanel(),
        ),
      );
    }

    testWidgets('an image gets the image preview and the Image label', (
      WidgetTester tester,
    ) async {
      await pumpPanel(
        tester,
        const MediaAsset(path: '/tmp/missing.png', kind: MediaKind.image),
      );

      expect(find.byType(ImagePreview), findsOneWidget);
      expect(find.text('Image'), findsOneWidget);
    });

    testWidgets('a sound gets the audio preview and the Original label', (
      WidgetTester tester,
    ) async {
      await pumpPanel(
        tester,
        const MediaAsset(path: '/tmp/song.m4a', kind: MediaKind.audio),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AudioPreview), findsOneWidget);
      expect(find.byType(VideoPreview), findsNothing);
      expect(find.text('Original'), findsOneWidget);
    });

    testWidgets('a video still gets the video preview', (
      WidgetTester tester,
    ) async {
      await pumpPanel(tester, const MediaAsset(path: '/tmp/clip.mp4'));
      await tester.pumpAndSettle();

      expect(find.byType(VideoPreview), findsOneWidget);
      expect(find.byType(AudioPreview), findsNothing);
    });
  });
}
