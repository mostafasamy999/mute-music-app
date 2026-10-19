import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/domain/entities/removal_progress.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/removal_step_tile.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/status_message.dart';

class _MockCubit extends MockCubit<MuteVideoState> implements MuteVideoCubit {}

void main() {
  Future<void> pump(
    WidgetTester tester,
    MuteVideoState state, {
    Locale locale = const Locale('en'),
  }) async {
    final _MockCubit cubit = _MockCubit();
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
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
            child: const StatusMessage(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  RemovalStepLook lookOf(WidgetTester tester, String label) => tester
      .widget<RemovalStepTile>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(RemovalStepTile),
        ),
      )
      .look;

  testWidgets('separating shows the part being worked on and a bar', (
    WidgetTester tester,
  ) async {
    await pump(
      tester,
      const MuteVideoState(
        status: MuteVideoStatus.removingMusic,
        removal: RemovalProgress(RemovalStep.separate, done: 1, total: 4),
      ),
    );

    expect(lookOf(tester, 'Get the AI model'), RemovalStepLook.done);
    expect(lookOf(tester, 'Read the audio'), RemovalStepLook.done);
    expect(lookOf(tester, 'Separate the voices'), RemovalStepLook.active);
    expect(lookOf(tester, 'Build the video'), RemovalStepLook.waiting);
    expect(find.text('Part 2 of 4'), findsOneWidget);
    final LinearProgressIndicator bar = tester.widget(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 0.25);
    // The old single line is replaced, not shown as well.
    expect(find.textContaining('Removing the music'), findsNothing);
  });

  testWidgets('the model download shows its percent', (
    WidgetTester tester,
  ) async {
    await pump(
      tester,
      const MuteVideoState(
        status: MuteVideoStatus.preparingModel,
        removal: RemovalProgress(RemovalStep.model, done: 42, total: 100),
      ),
    );

    expect(find.text('42%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('the steps are localized in Arabic', (WidgetTester tester) async {
    await pump(
      tester,
      const MuteVideoState(
        status: MuteVideoStatus.removingMusic,
        removal: RemovalProgress(RemovalStep.separate, done: 0, total: 3),
      ),
      locale: const Locale('ar'),
    );

    expect(find.text('فصل الأصوات'), findsOneWidget);
    expect(find.text('الجزء 1 من 3'), findsOneWidget);
  });

  testWidgets('a finished job shows the ready line, not the steps', (
    WidgetTester tester,
  ) async {
    await pump(
      tester,
      const MuteVideoState(status: MuteVideoStatus.muted, musicOnly: true),
    );

    expect(find.byType(RemovalStepTile), findsNothing);
    expect(find.text('Music removed. You can save it now.'), findsOneWidget);
  });
}
