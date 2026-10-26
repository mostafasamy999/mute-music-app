import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/domain/entities/clip_range.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/cut_file_button.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/mute_video_actions.dart';

class _MockCubit extends MockCubit<MuteVideoState> implements MuteVideoCubit {}

const VideoAsset _video = VideoAsset(path: '/tmp/video.mp4');
final VideoAsset _part = VideoAsset(
  path: '/tmp/part_1.mp4',
  range: ClipRange(start: Duration.zero, end: const Duration(seconds: 3)),
);
const VideoAsset _result = VideoAsset(path: '/tmp/result.mp4');
const MediaAsset _image = MediaAsset(path: '/tmp/i.jpg', kind: MediaKind.image);
const MediaAsset _sound = MediaAsset(path: '/tmp/s.mp3', kind: MediaKind.audio);
final MediaAsset _soundPart = MediaAsset(
  path: '/tmp/part_2.m4a',
  kind: MediaKind.audio,
  range: ClipRange(start: Duration.zero, end: const Duration(seconds: 3)),
);
const MediaAsset _soundResult = MediaAsset(
  path: '/tmp/nomusic_2.m4a',
  kind: MediaKind.audio,
);

/// Spec 006 S7: the actions per file type and after edits (§3, §3.1).
void main() {
  group('actions table', () {
    test('nothing added: no actions', () {
      expect(const MuteVideoState().actions, isEmpty);
    });

    test('image: Extract text only', () {
      expect(
        const MuteVideoState(source: _image, original: _image).actions,
        <MediaAction>[MediaAction.extractText],
      );
    });

    test('sound: Remove music only and Extract text, no save yet', () {
      expect(
        const MuteVideoState(source: _sound, original: _sound).actions,
        <MediaAction>[MediaAction.removeMusic, MediaAction.extractText],
      );
    });

    test('video: the four actions, no save yet', () {
      expect(
        const MuteVideoState(source: _video, original: _video).actions,
        <MediaAction>[
          MediaAction.removeSound,
          MediaAction.removeMusic,
          MediaAction.convertToAudio,
          MediaAction.extractText,
        ],
      );
    });

    test('video part (only a cut): the four actions plus Save (Q12)', () {
      expect(
        MuteVideoState(source: _part, original: _video).actions,
        <MediaAction>[
          MediaAction.removeSound,
          MediaAction.removeMusic,
          MediaAction.convertToAudio,
          MediaAction.extractText,
          MediaAction.saveToGallery,
        ],
      );
    });

    test('video with music removed: no Remove sound or music again (A1)', () {
      expect(
        MuteVideoState(
          source: _part,
          original: _video,
          muted: _result,
          musicOnly: true,
        ).actions,
        <MediaAction>[
          MediaAction.convertToAudio,
          MediaAction.extractText,
          MediaAction.saveToGallery,
        ],
      );
    });

    test('video with sound removed: Save to gallery only', () {
      expect(
        const MuteVideoState(
          source: _video,
          original: _video,
          muted: _result,
        ).actions,
        <MediaAction>[MediaAction.saveToGallery],
      );
    });

    test('sound part: Remove music, Extract text, Save to Music', () {
      expect(
        MuteVideoState(source: _soundPart, original: _sound).actions,
        <MediaAction>[
          MediaAction.removeMusic,
          MediaAction.extractText,
          MediaAction.saveToMusic,
        ],
      );
    });

    test('sound with music removed: Extract text and Save to Music', () {
      expect(
        const MuteVideoState(
          source: _sound,
          original: _sound,
          muted: _soundResult,
          musicOnly: true,
        ).actions,
        <MediaAction>[MediaAction.extractText, MediaAction.saveToMusic],
      );
    });

    test('a running job keeps the same actions (no jumping buttons)', () {
      const MuteVideoState idle = MuteVideoState(
        source: _video,
        original: _video,
      );
      const MuteVideoState running = MuteVideoState(
        status: MuteVideoStatus.removingMusic,
        source: _video,
        original: _video,
      );
      expect(running.actions, idle.actions);
    });

    test('Save works on a part, never on the untouched file', () {
      expect(
        const MuteVideoState(source: _video, original: _video).canSave,
        isFalse,
      );
      expect(MuteVideoState(source: _part, original: _video).canSave, isTrue);
      expect(MuteVideoState(source: _part, original: _video).current, _part);
      expect(
        MuteVideoState(source: _part, original: _video, muted: _result).current,
        _result,
      );
    });
  });

  group('widget', () {
    late _MockCubit cubit;

    setUp(() => cubit = _MockCubit());

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
          home: Scaffold(
            body: BlocProvider<MuteVideoCubit>.value(
              value: cubit,
              child: const Column(
                children: <Widget>[CutFileButton(), MuteVideoActions()],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('a video shows only the built actions, in order', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const MuteVideoState(source: _video, original: _video),
      );

      expect(find.text('Remove sound'), findsOneWidget);
      expect(find.text('Remove music only'), findsOneWidget);
      expect(find.text('Save to gallery'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Remove sound')).dy,
        lessThan(tester.getTopLeft(find.text('Remove music only')).dy),
      );
    });

    testWidgets('after Remove sound only Save to gallery shows', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const MuteVideoState(
          status: MuteVideoStatus.muted,
          source: _video,
          original: _video,
          muted: _result,
        ),
      );

      expect(find.text('Save to gallery'), findsOneWidget);
      expect(find.text('Remove sound'), findsNothing);
      expect(find.text('Remove music only'), findsNothing);
    });

    testWidgets('an image shows no built action yet (Extract text is S12)', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const MuteVideoState(source: _image, original: _image),
      );

      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(CutFileButton), findsOneWidget);
      expect(find.byTooltip('Choose a part'), findsNothing);
    });

    testWidgets('a sound hides Remove music only until S13', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const MuteVideoState(source: _sound, original: _sound),
      );

      expect(find.text('Remove music only'), findsNothing);
    });

    testWidgets('a video has the cut icon; it is off during a job', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const MuteVideoState(
          status: MuteVideoStatus.muting,
          source: _video,
          original: _video,
        ),
      );

      final IconButton cut = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.content_cut),
          matching: find.byType(IconButton),
        ),
      );
      expect(cut.onPressed, isNull);
    });

    testWidgets('there is no More actions toggle (005 removed)', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const MuteVideoState(source: _video, original: _video),
      );

      expect(find.textContaining('actions'), findsNothing);
    });
  });
}
