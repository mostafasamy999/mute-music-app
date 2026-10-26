import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/domain/repositories/video_repository.dart';
import 'package:mute_music_app/src/domain/use_cases/cut_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/discard_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/ensure_model_ready_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/mute_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/pick_media_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/remove_music_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/save_video_use_case.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/add_media_button.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/clear_file_button.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/mute_video_actions.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/mute_video_content.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/status_message.dart';

class _MockPick extends Mock implements PickMediaUseCase {}

class _MockDiscard extends Mock implements DiscardVideoUseCase {}

class _MockCubit extends MockCubit<MuteVideoState> implements MuteVideoCubit {}

/// Spec 006 S5: the empty screen, adding a file of any kind, and Clear (x).
void main() {
  setUpAll(() {
    registerFallbackValue(MediaKind.video);
    registerFallbackValue(const VideoAsset(path: '/fallback'));
  });

  group('cubit', () {
    const MediaAsset image = MediaAsset(
      path: '/tmp/photo.jpg',
      kind: MediaKind.image,
    );
    const MediaAsset sound = MediaAsset(
      path: '/tmp/file_picker/song.mp3',
      kind: MediaKind.audio,
      duration: Duration(minutes: 3),
    );
    const VideoAsset original = VideoAsset(path: '/tmp/video.mp4');
    const VideoAsset part = VideoAsset(path: '/tmp/part_1.mp4');
    const VideoAsset result = VideoAsset(path: '/tmp/nomusic_1.mp4');

    late _MockPick pick;
    late _MockDiscard discard;

    setUp(() {
      pick = _MockPick();
      discard = _MockDiscard();
      when(() => discard(any())).thenAnswer((_) async {});
    });

    MuteVideoCubit build() => MuteVideoCubit(
      pick,
      MuteVideoUseCase(_NoRepository()),
      SaveVideoUseCase(_NoRepository()),
      _MockEnsureModel(),
      _MockRemoveMusic(),
      discard,
      CutVideoUseCase(_NoRepository()),
    );

    blocTest<MuteVideoCubit, MuteVideoState>(
      'adding an image asks the picker for an image and makes it the file',
      setUp: () => when(
        () => pick(MediaKind.image),
      ).thenAnswer((_) async => const DataSuccess<MediaAsset?>(image)),
      build: build,
      act: (MuteVideoCubit cubit) => cubit.addMedia(MediaKind.image),
      verify: (MuteVideoCubit cubit) {
        expect(cubit.state.source, image);
        expect(cubit.state.original, image);
        expect(cubit.state.source!.isImage, isTrue);
        expect(cubit.state.isBusy, isFalse);
      },
    );

    blocTest<MuteVideoCubit, MuteVideoState>(
      'adding a sound asks the picker for audio',
      setUp: () => when(
        () => pick(MediaKind.audio),
      ).thenAnswer((_) async => const DataSuccess<MediaAsset?>(sound)),
      build: build,
      act: (MuteVideoCubit cubit) => cubit.addMedia(MediaKind.audio),
      verify: (MuteVideoCubit cubit) {
        expect(cubit.state.source, sound);
        verify(() => pick(MediaKind.audio)).called(1);
      },
    );

    blocTest<MuteVideoCubit, MuteVideoState>(
      'a new file of another kind replaces the old file and its outputs',
      setUp: () => when(
        () => pick(MediaKind.image),
      ).thenAnswer((_) async => const DataSuccess<MediaAsset?>(image)),
      build: build,
      seed: () => const MuteVideoState(
        status: MuteVideoStatus.muted,
        source: part,
        original: original,
        muted: result,
      ),
      act: (MuteVideoCubit cubit) => cubit.addMedia(MediaKind.image),
      verify: (MuteVideoCubit cubit) {
        expect(cubit.state.source, image);
        expect(cubit.state.muted, isNull);
        verify(() => discard(part)).called(1);
        verify(() => discard(original)).called(1);
        verify(() => discard(result)).called(1);
      },
    );

    blocTest<MuteVideoCubit, MuteVideoState>(
      'cancelling the picker keeps the empty screen',
      setUp: () => when(
        () => pick(MediaKind.video),
      ).thenAnswer((_) async => const DataSuccess<MediaAsset?>(null)),
      build: build,
      act: (MuteVideoCubit cubit) => cubit.addMedia(MediaKind.video),
      verify: (MuteVideoCubit cubit) {
        expect(cubit.state.source, isNull);
        expect(cubit.state.isBusy, isFalse);
      },
    );

    blocTest<MuteVideoCubit, MuteVideoState>(
      'clear drops everything and deletes each file once',
      build: build,
      seed: () => const MuteVideoState(
        status: MuteVideoStatus.muted,
        source: part,
        original: original,
        muted: result,
      ),
      act: (MuteVideoCubit cubit) => cubit.clear(),
      expect: () => <MuteVideoState>[const MuteVideoState()],
      verify: (_) {
        verify(() => discard(part)).called(1);
        verify(() => discard(original)).called(1);
        verify(() => discard(result)).called(1);
      },
    );

    blocTest<MuteVideoCubit, MuteVideoState>(
      'clear without a part deletes the single file once',
      build: build,
      seed: () => const MuteVideoState(source: original, original: original),
      act: (MuteVideoCubit cubit) => cubit.clear(),
      verify: (_) => verify(() => discard(original)).called(1),
    );

    blocTest<MuteVideoCubit, MuteVideoState>(
      'clear does nothing while a job runs',
      build: build,
      seed: () => const MuteVideoState(
        status: MuteVideoStatus.removingMusic,
        source: original,
        original: original,
      ),
      act: (MuteVideoCubit cubit) => cubit.clear(),
      expect: () => <MuteVideoState>[],
      verify: (_) => verifyNever(() => discard(any())),
    );
  });

  group('widgets', () {
    late _MockCubit cubit;

    setUp(() {
      cubit = _MockCubit();
      when(() => cubit.addMedia(any())).thenAnswer((_) async {});
      when(() => cubit.clear()).thenAnswer((_) async {});
    });

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
          home: BlocProvider<MuteVideoCubit>.value(
            value: cubit,
            child: const MuteVideoContent(),
          ),
        ),
      );
    }

    testWidgets('the empty screen shows only the add widget', (
      WidgetTester tester,
    ) async {
      await pump(tester, const MuteVideoState());

      expect(find.byType(AddMediaButton), findsOneWidget);
      expect(find.text('Add an image, a sound or a video'), findsOneWidget);
      expect(find.byType(StatusMessage), findsNothing);
      expect(find.byType(MuteVideoActions), findsNothing);
      expect(find.byType(ClearFileButton), findsNothing);
    });

    testWidgets('the add sheet offers image, sound and video', (
      WidgetTester tester,
    ) async {
      await pump(tester, const MuteVideoState());

      await tester.tap(find.byType(AddMediaButton));
      await tester.pumpAndSettle();

      expect(find.text('Image'), findsOneWidget);
      expect(find.text('Sound'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);

      await tester.tap(find.text('Sound'));
      await tester.pumpAndSettle();
      verify(() => cubit.addMedia(MediaKind.audio)).called(1);
    });

    testWidgets('closing the sheet adds nothing', (WidgetTester tester) async {
      await pump(tester, const MuteVideoState());

      await tester.tap(find.byType(AddMediaButton));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      verifyNever(() => cubit.addMedia(any()));
    });

    testWidgets('a file shows the x, and x clears it', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const MuteVideoState(source: _missing, original: _missing),
      );

      expect(find.byType(AddMediaButton), findsNothing);
      await tester.tap(find.byTooltip('Clear this file'));
      verify(() => cubit.clear()).called(1);
    });

    testWidgets('x is disabled while a job runs', (WidgetTester tester) async {
      await pump(
        tester,
        const MuteVideoState(
          status: MuteVideoStatus.muting,
          source: _missing,
          original: _missing,
        ),
      );

      final IconButton x = tester.widget<IconButton>(
        find.descendant(
          of: find.byType(ClearFileButton),
          matching: find.byType(IconButton),
        ),
      );
      expect(x.onPressed, isNull);
    });
  });
}

/// A file that doesn't exist: the preview shows its can't-play state.
const MediaAsset _missing = MediaAsset(
  path: '/tmp/none.jpg',
  kind: MediaKind.image,
);

class _MockEnsureModel extends Mock implements EnsureModelReadyUseCase {}

class _MockRemoveMusic extends Mock implements RemoveMusicUseCase {}

/// The use cases these tests never reach.
class _NoRepository extends Fake implements VideoRepository {}
