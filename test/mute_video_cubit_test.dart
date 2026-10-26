import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/removal_progress.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/domain/use_cases/cut_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/convert_to_audio_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/discard_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/ensure_model_ready_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/mute_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/pick_media_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/remove_music_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/save_video_use_case.dart';

class _MockPick extends Mock implements PickMediaUseCase {}

class _MockConvert extends Mock implements ConvertToAudioUseCase {}

class _MockMute extends Mock implements MuteVideoUseCase {}

class _MockSave extends Mock implements SaveVideoUseCase {}

class _MockEnsureModel extends Mock implements EnsureModelReadyUseCase {}

class _MockRemoveMusic extends Mock implements RemoveMusicUseCase {}

class _MockDiscard extends Mock implements DiscardVideoUseCase {}

class _MockCut extends Mock implements CutVideoUseCase {}

void main() {
  const VideoAsset source = VideoAsset(path: '/tmp/source.mp4');
  const VideoAsset result = VideoAsset(path: '/tmp/result.mp4');

  late _MockPick pick;
  late _MockMute mute;
  late _MockSave save;
  late _MockEnsureModel ensureModel;
  late _MockRemoveMusic removeMusic;
  late _MockDiscard discard;

  setUpAll(() => registerFallbackValue(source));

  setUp(() {
    pick = _MockPick();
    mute = _MockMute();
    save = _MockSave();
    ensureModel = _MockEnsureModel();
    removeMusic = _MockRemoveMusic();
    discard = _MockDiscard();
    when(() => discard(any())).thenAnswer((_) async {});
  });

  MuteVideoCubit build() => MuteVideoCubit(
    pick,
    mute,
    save,
    ensureModel,
    removeMusic,
    discard,
    _MockCut(),
    _MockConvert(),
  );

  Matcher failedWith(AppFailure failure) => isA<MuteVideoState>()
      .having((MuteVideoState s) => s.status, 'status', MuteVideoStatus.failure)
      .having((MuteVideoState s) => s.failure, 'failure', failure)
      .having((MuteVideoState s) => s.isBusy, 'isBusy', isFalse);

  // Every action must end in failure, not stay busy, when a use case throws
  // something the repositories did not turn into a DataFailed.

  blocTest<MuteVideoCubit, MuteVideoState>(
    'pick that throws ends in pickFailed',
    setUp: () => when(() => pick()).thenThrow(StateError('boom')),
    build: build,
    act: (MuteVideoCubit cubit) => cubit.pickVideo(),
    expect: () => <Matcher>[
      isA<MuteVideoState>().having(
        (MuteVideoState s) => s.status,
        'status',
        MuteVideoStatus.picking,
      ),
      failedWith(AppFailure.pickFailed),
    ],
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'remove sound that throws ends in muteFailed and keeps the source',
    setUp: () => when(() => mute(any())).thenThrow(StateError('boom')),
    build: build,
    seed: () => const MuteVideoState(source: source),
    act: (MuteVideoCubit cubit) => cubit.removeSound(),
    verify: (MuteVideoCubit cubit) => expect(cubit.state.source, source),
    expect: () => <Matcher>[
      isA<MuteVideoState>().having(
        (MuteVideoState s) => s.status,
        'status',
        MuteVideoStatus.muting,
      ),
      failedWith(AppFailure.muteFailed),
    ],
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'a model download that throws ends in musicRemovalFailed',
    setUp: () => when(
      () => ensureModel(onProgress: any(named: 'onProgress')),
    ).thenThrow(StateError('boom')),
    build: build,
    seed: () => const MuteVideoState(source: source),
    act: (MuteVideoCubit cubit) => cubit.removeMusic(),
    skip: 1,
    expect: () => <Matcher>[failedWith(AppFailure.musicRemovalFailed)],
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'a separation that throws ends in musicRemovalFailed',
    setUp: () {
      when(
        () => ensureModel(onProgress: any(named: 'onProgress')),
      ).thenAnswer((_) async => const DataSuccess<void>(null));
      when(
        () => removeMusic(any(), onProgress: any(named: 'onProgress')),
      ).thenThrow(StateError('boom'));
    },
    build: build,
    seed: () => const MuteVideoState(source: source),
    act: (MuteVideoCubit cubit) => cubit.removeMusic(),
    skip: 2,
    expect: () => <Matcher>[failedWith(AppFailure.musicRemovalFailed)],
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'remove music walks the steps in order, then clears them on success',
    setUp: () {
      when(() => ensureModel(onProgress: any(named: 'onProgress'))).thenAnswer((
        Invocation call,
      ) async {
        (call.namedArguments[#onProgress] as void Function(double))(0.5);
        return const DataSuccess<void>(null);
      });
      when(
        () => removeMusic(any(), onProgress: any(named: 'onProgress')),
      ).thenAnswer((Invocation call) async {
        final void Function(RemovalProgress) report =
            call.namedArguments[#onProgress] as void Function(RemovalProgress);
        report(const RemovalProgress(RemovalStep.extract));
        report(const RemovalProgress(RemovalStep.separate, done: 1, total: 2));
        report(const RemovalProgress(RemovalStep.build));
        return const DataSuccess<VideoAsset>(result);
      });
    },
    build: build,
    seed: () => const MuteVideoState(source: source),
    act: (MuteVideoCubit cubit) => cubit.removeMusic(),
    expect: () => <Matcher>[
      isA<MuteVideoState>()
          .having(
            (MuteVideoState s) => s.removal,
            'removal',
            const RemovalProgress(RemovalStep.model),
          )
          .having((MuteVideoState s) => s.showsSteps, 'showsSteps', isTrue),
      isA<MuteVideoState>().having(
        (MuteVideoState s) => s.removal,
        'removal',
        const RemovalProgress(RemovalStep.model, done: 50, total: 100),
      ),
      isA<MuteVideoState>()
          .having(
            (MuteVideoState s) => s.status,
            'status',
            MuteVideoStatus.removingMusic,
          )
          .having(
            (MuteVideoState s) => s.removal,
            'removal',
            const RemovalProgress(RemovalStep.extract),
          ),
      isA<MuteVideoState>()
          .having(
            (MuteVideoState s) => s.removal,
            'removal',
            const RemovalProgress(RemovalStep.separate, done: 1, total: 2),
          )
          .having((MuteVideoState s) => s.progress, 'progress', 0.5),
      isA<MuteVideoState>().having(
        (MuteVideoState s) => s.removal,
        'removal',
        const RemovalProgress(RemovalStep.build),
      ),
      isA<MuteVideoState>()
          .having(
            (MuteVideoState s) => s.status,
            'status',
            MuteVideoStatus.muted,
          )
          .having((MuteVideoState s) => s.removal, 'removal', isNull)
          .having((MuteVideoState s) => s.showsSteps, 'showsSteps', isFalse),
    ],
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'a failed removal drops the steps so the screen is not left mid-job',
    setUp: () {
      when(
        () => ensureModel(onProgress: any(named: 'onProgress')),
      ).thenAnswer((_) async => const DataSuccess<void>(null));
      when(
        () => removeMusic(any(), onProgress: any(named: 'onProgress')),
      ).thenAnswer(
        (_) async =>
            const DataFailed<VideoAsset>(AppFailure.musicRemovalFailed),
      );
    },
    build: build,
    seed: () => const MuteVideoState(source: source),
    act: (MuteVideoCubit cubit) => cubit.removeMusic(),
    skip: 2,
    expect: () => <Matcher>[
      allOf(
        failedWith(AppFailure.musicRemovalFailed),
        isA<MuteVideoState>().having(
          (MuteVideoState s) => s.removal,
          'removal',
          isNull,
        ),
      ),
    ],
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'save that throws ends in saveFailed and keeps the result',
    setUp: () => when(() => save(any())).thenThrow(StateError('boom')),
    build: build,
    seed: () => const MuteVideoState(
      status: MuteVideoStatus.muted,
      source: source,
      muted: result,
    ),
    act: (MuteVideoCubit cubit) => cubit.saveToGallery(),
    skip: 1,
    verify: (MuteVideoCubit cubit) => expect(cubit.state.canSave, isTrue),
    expect: () => <Matcher>[failedWith(AppFailure.saveFailed)],
  );

  // Replaced files are discarded, and only once nothing shows them.

  const VideoAsset next = VideoAsset(path: '/tmp/next.mp4');

  blocTest<MuteVideoCubit, MuteVideoState>(
    'a new pick discards the old source and result',
    setUp: () => when(
      () => pick(),
    ).thenAnswer((_) async => const DataSuccess<VideoAsset?>(next)),
    build: build,
    seed: () => const MuteVideoState(
      status: MuteVideoStatus.muted,
      source: source,
      muted: result,
    ),
    act: (MuteVideoCubit cubit) => cubit.pickVideo(),
    verify: (MuteVideoCubit cubit) {
      expect(cubit.state.source, next);
      verify(() => discard(source)).called(1);
      verify(() => discard(result)).called(1);
    },
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'a cancelled pick discards nothing',
    setUp: () => when(
      () => pick(),
    ).thenAnswer((_) async => const DataSuccess<VideoAsset?>(null)),
    build: build,
    seed: () => const MuteVideoState(source: source, muted: result),
    act: (MuteVideoCubit cubit) => cubit.pickVideo(),
    verify: (_) => verifyNever(() => discard(any())),
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'picking the same path again does not delete it',
    setUp: () => when(
      () => pick(),
    ).thenAnswer((_) async => const DataSuccess<VideoAsset?>(source)),
    build: build,
    seed: () => const MuteVideoState(source: source),
    act: (MuteVideoCubit cubit) => cubit.pickVideo(),
    verify: (_) => verifyNever(() => discard(any())),
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'a new result runs on the result, keeps it as the file before, and '
    'deletes the older one (spec 006 Q8, §3.2)',
    setUp: () => when(
      () => mute(result),
    ).thenAnswer((_) async => const DataSuccess<VideoAsset>(next)),
    build: build,
    seed: () => const MuteVideoState(
      status: MuteVideoStatus.muted,
      source: source,
      muted: result,
      lastInput: VideoAsset(path: '/tmp/older.mp4'),
    ),
    act: (MuteVideoCubit cubit) => cubit.removeSound(),
    verify: (MuteVideoCubit cubit) {
      expect(cubit.state.muted, next);
      expect(cubit.state.lastInput, result);
      verify(() => discard(const VideoAsset(path: '/tmp/older.mp4'))).called(1);
      verifyNever(() => discard(result));
      verifyNever(() => discard(source));
    },
  );
}
