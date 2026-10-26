import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/domain/entities/clip_range.dart';
import 'package:mute_music_app/src/domain/entities/video_asset.dart';
import 'package:mute_music_app/src/domain/use_cases/convert_to_audio_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/cut_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/discard_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/ensure_model_ready_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/mute_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/pick_media_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/remove_music_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/save_video_use_case.dart';

class _MockPick extends Mock implements PickMediaUseCase {}

class _MockMute extends Mock implements MuteVideoUseCase {}

class _MockSave extends Mock implements SaveVideoUseCase {}

class _MockEnsureModel extends Mock implements EnsureModelReadyUseCase {}

class _MockRemoveMusic extends Mock implements RemoveMusicUseCase {}

class _MockDiscard extends Mock implements DiscardVideoUseCase {}

class _MockCut extends Mock implements CutVideoUseCase {}

class _MockConvert extends Mock implements ConvertToAudioUseCase {}

/// Spec 003: choosing a part, and the Remove music length limit.
void main() {
  const VideoAsset original = VideoAsset(
    path: '/tmp/big.mp4',
    duration: Duration(minutes: 20),
  );
  final ClipRange asked = ClipRange(
    start: const Duration(minutes: 1),
    end: const Duration(minutes: 2),
  );
  final ClipRange real = ClipRange(
    start: const Duration(seconds: 59),
    end: const Duration(minutes: 2),
  );
  final VideoAsset part = VideoAsset(
    path: '/tmp/part_1.mp4',
    duration: real.length,
    range: real,
  );
  const VideoAsset result = VideoAsset(path: '/tmp/result.mp4');

  late _MockPick pick;
  late _MockMute mute;
  late _MockEnsureModel ensureModel;
  late _MockRemoveMusic removeMusic;
  late _MockDiscard discard;
  late _MockCut cut;
  late _MockSave save;
  late _MockConvert convert;

  setUpAll(() {
    registerFallbackValue(original);
    registerFallbackValue(asked);
  });

  setUp(() {
    pick = _MockPick();
    mute = _MockMute();
    ensureModel = _MockEnsureModel();
    removeMusic = _MockRemoveMusic();
    discard = _MockDiscard();
    cut = _MockCut();
    save = _MockSave();
    convert = _MockConvert();
    when(() => discard(any())).thenAnswer((_) async {});
  });

  MuteVideoCubit build() => MuteVideoCubit(
    pick,
    mute,
    save,
    ensureModel,
    removeMusic,
    discard,
    cut,
    convert,
  );

  const MuteVideoState picked = MuteVideoState(
    source: original,
    original: original,
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'using a part cuts the original and makes the part the source',
    setUp: () => when(
      () => cut(original, asked),
    ).thenAnswer((_) async => DataSuccess<VideoAsset>(part)),
    build: build,
    seed: () => picked,
    act: (MuteVideoCubit cubit) => cubit.usePart(asked),
    expect: () => <Matcher>[
      isA<MuteVideoState>()
          .having(
            (MuteVideoState s) => s.status,
            'status',
            MuteVideoStatus.cutting,
          )
          .having((MuteVideoState s) => s.isBusy, 'isBusy', isTrue),
      isA<MuteVideoState>()
          .having(
            (MuteVideoState s) => s.status,
            'status',
            MuteVideoStatus.initial,
          )
          .having((MuteVideoState s) => s.source, 'source', part)
          .having((MuteVideoState s) => s.original, 'original', original)
          .having((MuteVideoState s) => s.hasPart, 'hasPart', isTrue),
    ],
    // The original is the user's video: it is never deleted for a part.
    verify: (_) => verifyNever(() => discard(any())),
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'a new part is cut from the original and replaces the old part and result',
    setUp: () => when(
      () => cut(original, asked),
    ).thenAnswer((_) async => DataSuccess<VideoAsset>(part)),
    build: build,
    seed: () => const MuteVideoState(
      status: MuteVideoStatus.muted,
      source: VideoAsset(path: '/tmp/part_0.mp4'),
      original: original,
      muted: result,
    ),
    act: (MuteVideoCubit cubit) => cubit.usePart(asked),
    verify: (MuteVideoCubit cubit) {
      expect(cubit.state.source, part);
      expect(cubit.state.muted, isNull);
      verify(() => cut(original, asked)).called(1);
      verify(
        () => discard(const VideoAsset(path: '/tmp/part_0.mp4')),
      ).called(1);
      verify(() => discard(result)).called(1);
      verifyNever(() => discard(original));
    },
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'choosing the whole video cuts nothing',
    build: build,
    seed: () => picked,
    act: (MuteVideoCubit cubit) => cubit.usePart(
      ClipRange(
        start: const Duration(milliseconds: 200),
        end: const Duration(minutes: 20),
      ),
    ),
    expect: () => <MuteVideoState>[],
    verify: (_) => verifyNever(() => cut(any(), any())),
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'choosing the whole video after a part goes back to the original',
    build: build,
    seed: () => MuteVideoState(source: part, original: original),
    act: (MuteVideoCubit cubit) => cubit.usePart(
      ClipRange(start: Duration.zero, end: const Duration(minutes: 20)),
    ),
    verify: (MuteVideoCubit cubit) {
      expect(cubit.state.source, original);
      expect(cubit.state.hasPart, isFalse);
      verify(() => discard(part)).called(1);
      verifyNever(() => cut(any(), any()));
    },
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'a failed cut keeps the earlier source and frees the buttons',
    setUp: () => when(() => cut(original, asked)).thenAnswer(
      (_) async => const DataFailed<VideoAsset>(AppFailure.cutFailed),
    ),
    build: build,
    seed: () => picked,
    act: (MuteVideoCubit cubit) => cubit.usePart(asked),
    skip: 1,
    expect: () => <Matcher>[
      isA<MuteVideoState>()
          .having(
            (MuteVideoState s) => s.failure,
            'failure',
            AppFailure.cutFailed,
          )
          .having((MuteVideoState s) => s.source, 'source', original)
          .having((MuteVideoState s) => s.isBusy, 'isBusy', isFalse),
    ],
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'a cut that throws ends in cutFailed, not busy',
    setUp: () => when(() => cut(any(), any())).thenThrow(StateError('boom')),
    build: build,
    seed: () => picked,
    act: (MuteVideoCubit cubit) => cubit.usePart(asked),
    skip: 1,
    expect: () => <Matcher>[
      isA<MuteVideoState>()
          .having(
            (MuteVideoState s) => s.failure,
            'failure',
            AppFailure.cutFailed,
          )
          .having((MuteVideoState s) => s.isBusy, 'isBusy', isFalse),
    ],
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'a new pick drops the part and deletes it, and the old original',
    setUp: () => when(() => pick()).thenAnswer(
      (_) async =>
          const DataSuccess<VideoAsset?>(VideoAsset(path: '/tmp/next.mp4')),
    ),
    build: build,
    seed: () => MuteVideoState(source: part, original: original, muted: result),
    act: (MuteVideoCubit cubit) => cubit.pickVideo(),
    verify: (MuteVideoCubit cubit) {
      expect(cubit.state.hasPart, isFalse);
      expect(cubit.state.original, const VideoAsset(path: '/tmp/next.mp4'));
      verify(() => discard(part)).called(1);
      verify(() => discard(original)).called(1);
      verify(() => discard(result)).called(1);
    },
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'remove music on a source over the limit fails before any work starts',
    build: build,
    seed: () => picked,
    act: (MuteVideoCubit cubit) => cubit.removeMusic(),
    expect: () => <Matcher>[
      isA<MuteVideoState>()
          .having(
            (MuteVideoState s) => s.failure,
            'failure',
            AppFailure.tooLongForMusic,
          )
          .having((MuteVideoState s) => s.isBusy, 'isBusy', isFalse),
    ],
    verify: (_) {
      verifyNever(() => ensureModel(onProgress: any(named: 'onProgress')));
      verifyNever(
        () => removeMusic(any(), onProgress: any(named: 'onProgress')),
      );
    },
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'remove music after choosing a part runs on the part, not the original',
    setUp: () {
      when(
        () => ensureModel(onProgress: any(named: 'onProgress')),
      ).thenAnswer((_) async => const DataSuccess<void>(null));
      when(
        () => removeMusic(any(), onProgress: any(named: 'onProgress')),
      ).thenAnswer((_) async => const DataSuccess<VideoAsset>(result));
    },
    build: build,
    seed: () => MuteVideoState(source: part, original: original),
    act: (MuteVideoCubit cubit) => cubit.removeMusic(),
    verify: (MuteVideoCubit cubit) {
      expect(cubit.state.muted, result);
      verify(
        () => removeMusic(part, onProgress: any(named: 'onProgress')),
      ).called(1);
    },
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'remove sound has no length limit and runs on the part',
    setUp: () => when(
      () => mute(part),
    ).thenAnswer((_) async => const DataSuccess<VideoAsset>(result)),
    build: build,
    seed: () => MuteVideoState(source: part, original: original),
    act: (MuteVideoCubit cubit) => cubit.removeSound(),
    verify: (MuteVideoCubit cubit) => expect(cubit.state.muted, result),
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'remove sound on a long original is allowed',
    setUp: () => when(
      () => mute(original),
    ).thenAnswer((_) async => const DataSuccess<VideoAsset>(result)),
    build: build,
    seed: () => picked,
    act: (MuteVideoCubit cubit) => cubit.removeSound(),
    verify: (MuteVideoCubit cubit) => expect(cubit.state.muted, result),
  );

  // Spec 006 S2: the original, the part and the result are separate files.
  // Later features (View original, compare) rely on these rules.

  blocTest<MuteVideoCubit, MuteVideoState>(
    'pick, part, then remove sound keeps all three files apart',
    setUp: () {
      when(
        () => pick(),
      ).thenAnswer((_) async => const DataSuccess<VideoAsset?>(original));
      when(
        () => cut(original, asked),
      ).thenAnswer((_) async => DataSuccess<VideoAsset>(part));
      when(
        () => mute(part),
      ).thenAnswer((_) async => const DataSuccess<VideoAsset>(result));
    },
    build: build,
    act: (MuteVideoCubit cubit) async {
      await cubit.pickVideo();
      await cubit.usePart(asked);
      await cubit.removeSound();
    },
    verify: (MuteVideoCubit cubit) {
      expect(cubit.state.original, original);
      expect(cubit.state.source, part);
      expect(cubit.state.muted, result);
      verifyNever(() => discard(any()));
    },
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'a failed cut keeps the current part and result, and deletes nothing',
    setUp: () => when(() => cut(original, asked)).thenAnswer(
      (_) async => const DataFailed<VideoAsset>(AppFailure.cutFailed),
    ),
    build: build,
    seed: () => MuteVideoState(
      status: MuteVideoStatus.muted,
      source: part,
      original: original,
      muted: result,
    ),
    act: (MuteVideoCubit cubit) => cubit.usePart(asked),
    verify: (MuteVideoCubit cubit) {
      expect(cubit.state.source, part);
      expect(cubit.state.original, original);
      expect(cubit.state.muted, result);
      expect(cubit.state.isBusy, isFalse);
      verifyNever(() => discard(any()));
    },
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'a second result on a part runs on the first and keeps it as the file '
    'before',
    setUp: () {
      when(
        () => ensureModel(onProgress: any(named: 'onProgress')),
      ).thenAnswer((_) async => const DataSuccess<void>(null));
      when(
        () => removeMusic(result, onProgress: any(named: 'onProgress')),
      ).thenAnswer(
        (_) async =>
            const DataSuccess<VideoAsset>(VideoAsset(path: '/tmp/second.mp4')),
      );
    },
    build: build,
    seed: () => MuteVideoState(
      status: MuteVideoStatus.muted,
      source: part,
      original: original,
      muted: result,
    ),
    act: (MuteVideoCubit cubit) => cubit.removeMusic(),
    verify: (MuteVideoCubit cubit) {
      expect(cubit.state.muted, const VideoAsset(path: '/tmp/second.mp4'));
      expect(cubit.state.source, part);
      expect(cubit.state.original, original);
      expect(cubit.state.lastInput, result);
      // The part is still the source, and the first result is the "before".
      verifyNever(() => discard(any()));
    },
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'the old part is deleted only after the new part is ready',
    setUp: () => when(
      () => cut(original, asked),
    ).thenAnswer((_) async => DataSuccess<VideoAsset>(part)),
    build: build,
    seed: () => const MuteVideoState(
      source: VideoAsset(path: '/tmp/part_0.mp4'),
      original: original,
    ),
    act: (MuteVideoCubit cubit) => cubit.usePart(asked),
    verify: (_) => verifyInOrder(<void Function()>[
      () => cut(original, asked),
      () => discard(const VideoAsset(path: '/tmp/part_0.mp4')),
    ]),
  );

  // Spec 006 S7 / Q12: after only a cut, Save saves the part.

  blocTest<MuteVideoCubit, MuteVideoState>(
    'save after only a cut saves the part',
    setUp: () => when(
      () => save(part),
    ).thenAnswer((_) async => const DataSuccess<void>(null)),
    build: build,
    seed: () => MuteVideoState(source: part, original: original),
    act: (MuteVideoCubit cubit) => cubit.saveToGallery(),
    verify: (MuteVideoCubit cubit) {
      expect(cubit.state.status, MuteVideoStatus.saved);
      verify(() => save(part)).called(1);
      verifyNever(() => save(original));
    },
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'save on the untouched added file does nothing',
    build: build,
    seed: () => picked,
    act: (MuteVideoCubit cubit) => cubit.saveToGallery(),
    expect: () => <MuteVideoState>[],
    verify: (_) => verifyNever(() => save(any())),
  );

  // Spec 006 S10: Convert to audio runs on the current video.

  const MediaAsset audio = MediaAsset(
    path: '/tmp/export_1.m4a',
    kind: MediaKind.audio,
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'convert makes a sound file and keeps the video as the file before',
    setUp: () => when(
      () => convert(part),
    ).thenAnswer((_) async => const DataSuccess<MediaAsset>(audio)),
    build: build,
    seed: () => MuteVideoState(source: part, original: original),
    act: (MuteVideoCubit cubit) => cubit.convertToAudio(),
    verify: (MuteVideoCubit cubit) {
      expect(cubit.state.status, MuteVideoStatus.muted);
      expect(cubit.state.current, audio);
      expect(cubit.state.lastInput, part);
      expect(cubit.state.applied, <MediaOperation>{
        MediaOperation.convertToAudio,
      });
      verifyNever(() => discard(any()));
    },
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'convert after Remove music works on the music-free video (Q8)',
    setUp: () => when(
      () => convert(result),
    ).thenAnswer((_) async => const DataSuccess<MediaAsset>(audio)),
    build: build,
    seed: () => MuteVideoState(
      status: MuteVideoStatus.muted,
      source: part,
      original: original,
      muted: result,
      musicOnly: true,
      applied: const <MediaOperation>{MediaOperation.removeMusic},
      lastInput: part,
    ),
    act: (MuteVideoCubit cubit) => cubit.convertToAudio(),
    verify: (MuteVideoCubit cubit) {
      expect(cubit.state.lastInput, result);
      expect(cubit.state.applied, <MediaOperation>{
        MediaOperation.removeMusic,
        MediaOperation.convertToAudio,
      });
      // Rule A1 on the sound file: Remove music already ran.
      expect(cubit.state.actions, <MediaAction>[
        MediaAction.extractText,
        MediaAction.saveToMusic,
      ]);
      verify(() => convert(result)).called(1);
    },
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'a failed convert keeps everything and frees the buttons',
    setUp: () => when(() => convert(any())).thenAnswer(
      (_) async => const DataFailed<MediaAsset>(AppFailure.convertFailed),
    ),
    build: build,
    seed: () => picked,
    act: (MuteVideoCubit cubit) => cubit.convertToAudio(),
    skip: 1,
    expect: () => <Matcher>[
      isA<MuteVideoState>()
          .having(
            (MuteVideoState s) => s.failure,
            'failure',
            AppFailure.convertFailed,
          )
          .having((MuteVideoState s) => s.source, 'source', original)
          .having((MuteVideoState s) => s.isBusy, 'isBusy', isFalse),
    ],
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'a convert that throws ends in convertFailed, not busy',
    setUp: () => when(() => convert(any())).thenThrow(StateError('boom')),
    build: build,
    seed: () => picked,
    act: (MuteVideoCubit cubit) => cubit.convertToAudio(),
    verify: (MuteVideoCubit cubit) {
      expect(cubit.state.failure, AppFailure.convertFailed);
      expect(cubit.state.isBusy, isFalse);
    },
  );

  blocTest<MuteVideoCubit, MuteVideoState>(
    'convert does nothing on a sound file',
    build: build,
    seed: () => const MuteVideoState(source: audio, original: audio),
    act: (MuteVideoCubit cubit) => cubit.convertToAudio(),
    expect: () => <MuteVideoState>[],
    verify: (_) => verifyNever(() => convert(any())),
  );
}
