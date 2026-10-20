import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/mute_video_actions.dart';

class _MockCubit extends MockCubit<MuteVideoState> implements MuteVideoCubit {}

const VideoAsset _source = VideoAsset(path: '/tmp/source.mp4');
const VideoAsset _result = VideoAsset(path: '/tmp/result.mp4');

const MuteVideoState _empty = MuteVideoState();
const MuteVideoState _picked = MuteVideoState(source: _source);
const MuteVideoState _done = MuteVideoState(
  status: MuteVideoStatus.muted,
  source: _source,
  muted: _result,
  musicOnly: true,
);

void main() {
  group('stage', () {
    test('comes from the data: empty, picked, done', () {
      expect(_empty.stage, ActionStage.empty);
      expect(_picked.stage, ActionStage.picked);
      expect(_done.stage, ActionStage.done);
    });

    test('a running job keeps its stage', () {
      const MuteVideoState removing = MuteVideoState(
        status: MuteVideoStatus.removingMusic,
        source: _source,
      );
      expect(removing.stage, ActionStage.picked);
    });
  });

  late _MockCubit cubit;
  late StreamController<MuteVideoState> states;

  setUp(() {
    cubit = _MockCubit();
    states = StreamController<MuteVideoState>();
  });

  // Not awaited: closing a stream nobody listened to never completes.
  tearDown(() => unawaited(states.close()));

  Future<void> pump(WidgetTester tester, MuteVideoState initial) async {
    whenListen(cubit, states.stream, initialState: initial);
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
          body: SingleChildScrollView(
            child: BlocProvider<MuteVideoCubit>.value(
              value: cubit,
              child: const MuteVideoActions(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Every button label on screen, top to bottom.
  List<String> labels(WidgetTester tester) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byWidgetPredicate((Widget w) => w is ButtonStyleButton),
          matching: find.byType(Text),
        ),
      )
      .map((Text text) => text.data!)
      .toList();

  testWidgets('empty shows only Pick a video', (WidgetTester tester) async {
    await pump(tester, _empty);

    expect(labels(tester), <String>['Pick a video', 'More actions']);
  });

  testWidgets('picked shows Pick another and Remove music only', (
    WidgetTester tester,
  ) async {
    await pump(tester, _picked);

    expect(labels(tester), <String>[
      'Pick another video',
      'Remove music only',
      'More actions',
    ]);
  });

  testWidgets('done shows Pick another and Save', (WidgetTester tester) async {
    await pump(tester, _done);

    expect(labels(tester), <String>[
      'Pick another video',
      'Save to gallery',
      'More actions',
    ]);
  });

  testWidgets('More actions shows all five in order, Fewer hides them', (
    WidgetTester tester,
  ) async {
    await pump(tester, _picked);

    await tester.tap(find.text('More actions'));
    await tester.pumpAndSettle();
    expect(labels(tester), <String>[
      'Pick another video',
      'Choose a part',
      'Remove music only',
      'Remove sound',
      'Save to gallery',
      'Fewer actions',
    ]);

    await tester.tap(find.text('Fewer actions'));
    await tester.pumpAndSettle();
    expect(labels(tester), <String>[
      'Pick another video',
      'Remove music only',
      'More actions',
    ]);
  });

  testWidgets('a new stage folds the extra actions away', (
    WidgetTester tester,
  ) async {
    await pump(tester, _picked);
    await tester.tap(find.text('More actions'));
    await tester.pumpAndSettle();

    states.add(_done);
    await tester.pumpAndSettle();

    expect(labels(tester), <String>[
      'Pick another video',
      'Save to gallery',
      'More actions',
    ]);
  });

  testWidgets('the same stage keeps them open (e.g. after a job ends)', (
    WidgetTester tester,
  ) async {
    await pump(tester, _picked);
    await tester.tap(find.text('More actions'));
    await tester.pumpAndSettle();

    states.add(
      const MuteVideoState(status: MuteVideoStatus.cutting, source: _source),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fewer actions'), findsOneWidget);
  });
}
