import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/presentation/screens/mute_video_screen.dart';

class _MockCubit extends MockCubit<MuteVideoState> implements MuteVideoCubit {}

/// Spec 006 S7: with no Choose a part button any more, the "too long for
/// Remove music" snackbar still offers the way to the cut screen.
void main() {
  // The kind keeps a real video player out of the test; the snackbar only
  // depends on the failure.
  const VideoAsset long = VideoAsset(
    path: '/tmp/long.mp4',
    kind: MediaKind.image,
  );

  tearDown(() => GetIt.instance.reset());

  testWidgets('too long for Remove music offers Choose a part', (
    WidgetTester tester,
  ) async {
    final _MockCubit cubit = _MockCubit();
    whenListen(
      cubit,
      Stream<MuteVideoState>.value(
        const MuteVideoState(
          status: MuteVideoStatus.failure,
          failure: AppFailure.tooLongForMusic,
          source: long,
          original: long,
        ),
      ),
      initialState: const MuteVideoState(source: long, original: long),
    );
    GetIt.instance.registerFactory<MuteVideoCubit>(() => cubit);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: const MuteVideoScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(
      find.widgetWithText(SnackBarAction, 'Choose a part'),
      findsOneWidget,
    );
  });
}
