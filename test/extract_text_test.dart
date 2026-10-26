import 'dart:io';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_cubit.dart';
import 'package:mute_music_app/src/bloc/mute_video/mute_video_state.dart';
import 'package:mute_music_app/src/core/resources/app_failure.dart';
import 'package:mute_music_app/src/core/resources/data_state.dart';
import 'package:mute_music_app/src/data/local/audio_pipeline_datasource.dart';
import 'package:mute_music_app/src/data/local/speech_datasource.dart';
import 'package:mute_music_app/src/data/local/video_mute_datasource.dart';
import 'package:mute_music_app/src/data/repositories/text_repository_impl.dart';
import 'package:mute_music_app/src/domain/entities/media_asset.dart';
import 'package:mute_music_app/src/domain/repositories/video_repository.dart';
import 'package:mute_music_app/src/domain/use_cases/convert_to_audio_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/cut_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/discard_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/ensure_model_ready_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/extract_text_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/mute_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/pick_media_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/remove_music_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/save_audio_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/save_video_use_case.dart';
import 'package:mute_music_app/src/domain/use_cases/speech_model_use_case.dart';
import 'package:mute_music_app/src/presentation/screens/text_screen.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/mute_video_actions.dart';

class _MockDatasource extends Mock implements VideoMuteDatasource {}

class _MockPipeline extends Mock implements AudioPipelineDatasource {}

class _MockSpeechData extends Mock implements SpeechDatasource {}

class _MockSpeech extends Mock implements SpeechModelUseCase {}

class _MockExtract extends Mock implements ExtractTextUseCase {}

class _MockPick extends Mock implements PickMediaUseCase {}

class _MockDiscard extends Mock implements DiscardVideoUseCase {}

class _MockEnsureModel extends Mock implements EnsureModelReadyUseCase {}

class _MockRemoveMusic extends Mock implements RemoveMusicUseCase {}

class _MockCubit extends MockCubit<MuteVideoState> implements MuteVideoCubit {}

class _NoRepository extends Fake implements VideoRepository {}

const MediaAsset _image = MediaAsset(path: '/tmp/i.jpg', kind: MediaKind.image);
const MediaAsset _video = MediaAsset(path: '/tmp/v.mp4');

/// Spec 006 S12: text from an image, and the Text screen.
void main() {
  setUpAll(() {
    registerFallbackValue(_image);
    registerFallbackValue(Float32List(0));
  });

  group('repository', () {
    late _MockDatasource datasource;
    late _MockPipeline pipeline;
    late _MockSpeechData speech;
    late TextRepositoryImpl repository;

    setUp(() {
      datasource = _MockDatasource();
      pipeline = _MockPipeline();
      speech = _MockSpeechData();
      repository = TextRepositoryImpl(datasource, pipeline, speech);
    });

    test('an image gives its trimmed text', () async {
      when(
        () => datasource.recognizeText(_image.path),
      ).thenAnswer((_) async => '  مرحبا Hello \n');

      expect(
        (await repository.extractText(_image) as DataSuccess<String>).data,
        'مرحبا Hello',
      );
    });

    test('no text is noTextFound', () async {
      when(() => datasource.recognizeText(any())).thenAnswer((_) async => ' ');

      expect(
        (await repository.extractText(_image) as DataFailed<String>).failure,
        AppFailure.noTextFound,
      );
    });

    for (final Object error in <Object>[
      PlatformException(code: 'unreadable_image'),
      PlatformException(code: 'ocr_failed'),
      MissingPluginException(),
    ]) {
      test('$error fails as extractFailed and never throws', () async {
        when(() => datasource.recognizeText(any())).thenThrow(error);

        expect(
          (await repository.extractText(_image) as DataFailed<String>).failure,
          AppFailure.extractFailed,
        );
      });
    }

    // Spec 006 S14: sound and video through the speech model.

    test('a video is extracted, converted, transcribed; PCM deleted', () async {
      final Directory dir = Directory.systemTemp.createTempSync('speech');
      addTearDown(() => dir.deleteSync(recursive: true));
      final File pcm = File('${dir.path}/audio.pcm')
        ..writeAsBytesSync(Float32List(32000).buffer.asUint8List());
      when(speech.readyModelPath).thenAnswer((_) async => '/models/base.bin');
      when(() => pipeline.extract(_video.path)).thenAnswer(
        (_) async =>
            ExtractedAudio(path: pcm.path, sampleRate: 32000, channels: 1),
      );
      when(
        () => speech.transcribe(
          '/models/base.bin',
          any(),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((Invocation call) async {
        final Float32List samples = call.positionalArguments[1] as Float32List;
        // 1 s at 32 kHz → 1 s at 16 kHz.
        expect(samples.length, 16000);
        return ' مرحبا Hello ';
      });

      expect(
        (await repository.extractText(_video) as DataSuccess<String>).data,
        'مرحبا Hello',
      );
      expect(pcm.existsSync(), isFalse);
      verifyNever(() => datasource.recognizeText(any()));
    });

    test(
      'no speech model is speechModelMissing; nothing is extracted',
      () async {
        when(speech.readyModelPath).thenAnswer((_) async => null);

        expect(
          (await repository.extractText(_video) as DataFailed<String>).failure,
          AppFailure.speechModelMissing,
        );
        verifyNever(() => pipeline.extract(any()));
      },
    );

    test('a video with no sound is noAudioTrack', () async {
      when(speech.readyModelPath).thenAnswer((_) async => '/models/base.bin');
      when(
        () => pipeline.extract(any()),
      ).thenThrow(PlatformException(code: 'no_audio_track'));

      expect(
        (await repository.extractText(_video) as DataFailed<String>).failure,
        AppFailure.noAudioTrack,
      );
    });
  });

  group('cubit', () {
    late _MockExtract extract;
    late _MockSpeech speechModel;
    late _MockDiscard discard;

    setUp(() {
      extract = _MockExtract();
      speechModel = _MockSpeech();
      when(speechModel.isReady).thenAnswer((_) async => true);
      discard = _MockDiscard();
      when(() => discard(any())).thenAnswer((_) async {});
    });

    MuteVideoCubit build() => MuteVideoCubit(
      _MockPick(),
      MuteVideoUseCase(_NoRepository()),
      SaveVideoUseCase(_NoRepository()),
      _MockEnsureModel(),
      _MockRemoveMusic(),
      discard,
      CutVideoUseCase(_NoRepository()),
      ConvertToAudioUseCase(_NoRepository()),
      SaveAudioUseCase(_NoRepository()),
      extract,
      speechModel,
    );

    const MuteVideoState picked = MuteVideoState(
      source: _image,
      original: _image,
    );

    blocTest<MuteVideoCubit, MuteVideoState>(
      'reads the text, then opens the Text screen',
      setUp: () => when(
        () => extract(_image, onProgress: any(named: 'onProgress')),
      ).thenAnswer((_) async => const DataSuccess<String>('Hello')),
      build: build,
      seed: () => picked,
      act: (MuteVideoCubit cubit) => cubit.extractText(),
      expect: () => <Matcher>[
        isA<MuteVideoState>()
            .having(
              (MuteVideoState s) => s.status,
              'status',
              MuteVideoStatus.extracting,
            )
            .having((MuteVideoState s) => s.isBusy, 'isBusy', isTrue),
        isA<MuteVideoState>()
            .having(
              (MuteVideoState s) => s.status,
              'status',
              MuteVideoStatus.textReady,
            )
            .having((MuteVideoState s) => s.text, 'text', 'Hello'),
      ],
    );

    blocTest<MuteVideoCubit, MuteVideoState>(
      'opening it again shows the last edit without reading again (Q10)',
      build: build,
      seed: () => picked,
      act: (MuteVideoCubit cubit) async {
        cubit.updateText('edited');
        await cubit.extractText();
      },
      verify: (MuteVideoCubit cubit) {
        expect(cubit.state.text, 'edited');
        expect(cubit.state.status, MuteVideoStatus.textReady);
        verifyNever(() => extract(any(), onProgress: any(named: 'onProgress')));
      },
    );

    blocTest<MuteVideoCubit, MuteVideoState>(
      'read again replaces the edit',
      setUp: () => when(
        () => extract(_image, onProgress: any(named: 'onProgress')),
      ).thenAnswer((_) async => const DataSuccess<String>('fresh')),
      build: build,
      seed: () => const MuteVideoState(
        source: _image,
        original: _image,
        text: 'edited',
      ),
      act: (MuteVideoCubit cubit) => cubit.extractText(again: true),
      verify: (MuteVideoCubit cubit) => expect(cubit.state.text, 'fresh'),
    );

    blocTest<MuteVideoCubit, MuteVideoState>(
      'no text shows noTextFound and frees the buttons',
      setUp: () =>
          when(
            () => extract(any(), onProgress: any(named: 'onProgress')),
          ).thenAnswer(
            (_) async => const DataFailed<String>(AppFailure.noTextFound),
          ),
      build: build,
      seed: () => picked,
      act: (MuteVideoCubit cubit) => cubit.extractText(),
      verify: (MuteVideoCubit cubit) {
        expect(cubit.state.failure, AppFailure.noTextFound);
        expect(cubit.state.isBusy, isFalse);
      },
    );

    blocTest<MuteVideoCubit, MuteVideoState>(
      'closing the Text screen goes back to the file',
      build: build,
      seed: () => const MuteVideoState(
        status: MuteVideoStatus.textReady,
        source: _image,
        original: _image,
        text: 'Hello',
      ),
      act: (MuteVideoCubit cubit) => cubit.closeText(),
      verify: (MuteVideoCubit cubit) {
        expect(cubit.state.status, MuteVideoStatus.initial);
        expect(cubit.state.text, 'Hello');
      },
    );

    const MediaAsset sound = MediaAsset(
      path: '/tmp/s.m4a',
      kind: MediaKind.audio,
      duration: Duration(seconds: 20),
    );
    const MuteVideoState soundPicked = MuteVideoState(
      source: sound,
      original: sound,
    );

    blocTest<MuteVideoCubit, MuteVideoState>(
      'no speech model: asks first, nothing is read (S14)',
      setUp: () => when(speechModel.isReady).thenAnswer((_) async => false),
      build: build,
      seed: () => soundPicked,
      act: (MuteVideoCubit cubit) => cubit.extractText(),
      verify: (MuteVideoCubit cubit) {
        expect(cubit.state.status, MuteVideoStatus.confirmSpeechDownload);
        expect(cubit.state.isBusy, isTrue);
        verifyNever(() => extract(any(), onProgress: any(named: 'onProgress')));
      },
    );

    blocTest<MuteVideoCubit, MuteVideoState>(
      'saying no to the download goes back to the file',
      build: build,
      seed: () => const MuteVideoState(
        status: MuteVideoStatus.confirmSpeechDownload,
        source: sound,
        original: sound,
      ),
      act: (MuteVideoCubit cubit) => cubit.declineSpeechDownload(),
      verify: (MuteVideoCubit cubit) {
        expect(cubit.state.status, MuteVideoStatus.initial);
        verifyNever(
          () => speechModel.download(onProgress: any(named: 'onProgress')),
        );
      },
    );

    blocTest<MuteVideoCubit, MuteVideoState>(
      'yes: downloads with progress, then reads the words',
      setUp: () {
        when(
          () => speechModel.download(onProgress: any(named: 'onProgress')),
        ).thenAnswer((Invocation call) async {
          (call.namedArguments[#onProgress] as void Function(double))(0.5);
          return const DataSuccess<void>(null);
        });
        when(
          () => extract(sound, onProgress: any(named: 'onProgress')),
        ).thenAnswer((Invocation call) async {
          (call.namedArguments[#onProgress] as void Function(double)?)?.call(
            0.4,
          );
          return const DataSuccess<String>('مرحبا');
        });
      },
      build: build,
      seed: () => const MuteVideoState(
        status: MuteVideoStatus.confirmSpeechDownload,
        source: sound,
        original: sound,
      ),
      act: (MuteVideoCubit cubit) => cubit.downloadSpeechModel(),
      expect: () => <Matcher>[
        isA<MuteVideoState>()
            .having(
              (MuteVideoState s) => s.status,
              'status',
              MuteVideoStatus.downloadingSpeech,
            )
            .having((MuteVideoState s) => s.showsProgress, 'bar', isTrue),
        isA<MuteVideoState>().having(
          (MuteVideoState s) => s.progress,
          'progress',
          0.5,
        ),
        isA<MuteVideoState>()
            .having(
              (MuteVideoState s) => s.status,
              'status',
              MuteVideoStatus.extracting,
            )
            .having((MuteVideoState s) => s.showsProgress, 'bar', isTrue),
        isA<MuteVideoState>().having(
          (MuteVideoState s) => s.progress,
          'progress',
          0.4,
        ),
        isA<MuteVideoState>()
            .having(
              (MuteVideoState s) => s.status,
              'status',
              MuteVideoStatus.textReady,
            )
            .having((MuteVideoState s) => s.text, 'text', 'مرحبا'),
      ],
    );

    blocTest<MuteVideoCubit, MuteVideoState>(
      'a failed download shows the message and frees the buttons',
      setUp: () =>
          when(
            () => speechModel.download(onProgress: any(named: 'onProgress')),
          ).thenAnswer(
            (_) async =>
                const DataFailed<void>(AppFailure.speechModelDownloadFailed),
          ),
      build: build,
      seed: () => soundPicked,
      act: (MuteVideoCubit cubit) => cubit.downloadSpeechModel(),
      verify: (MuteVideoCubit cubit) {
        expect(cubit.state.failure, AppFailure.speechModelDownloadFailed);
        expect(cubit.state.isBusy, isFalse);
      },
    );

    blocTest<MuteVideoCubit, MuteVideoState>(
      'a sound over 5 min asks for a part first, no download, no reading',
      build: build,
      seed: () => const MuteVideoState(
        source: MediaAsset(
          path: '/tmp/long.m4a',
          kind: MediaKind.audio,
          duration: Duration(minutes: 9),
        ),
        original: MediaAsset(
          path: '/tmp/long.m4a',
          kind: MediaKind.audio,
          duration: Duration(minutes: 9),
        ),
      ),
      act: (MuteVideoCubit cubit) => cubit.extractText(),
      verify: (MuteVideoCubit cubit) {
        expect(cubit.state.failure, AppFailure.tooLongForText);
        verifyNever(speechModel.isReady);
      },
    );

    test('a new file or a new part drops the text', () {
      const MuteVideoState withText = MuteVideoState(
        source: _video,
        original: _video,
        text: 'old',
      );
      expect(withText.withNewSource(_image).text, isNull);
      expect(
        withText.withPart(const MediaAsset(path: '/tmp/part.mp4')).text,
        isNull,
      );
    });
  });

  group('widgets', () {
    late _MockCubit cubit;
    late List<String> clipboard;

    setUp(() {
      cubit = _MockCubit();
      clipboard = <String>[];
      when(() => cubit.updateText(any())).thenReturn(null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (
            MethodCall call,
          ) async {
            if (call.method == 'Clipboard.setData') {
              clipboard.add(
                (call.arguments as Map<Object?, Object?>)['text']! as String,
              );
            }
            return null;
          });
    });

    Widget app(Widget home) => MaterialApp(
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: BlocProvider<MuteVideoCubit>.value(value: cubit, child: home),
    );

    Future<TextScreenResult? Function()> openText(
      WidgetTester tester,
      String text,
    ) async {
      whenListen(
        cubit,
        const Stream<MuteVideoState>.empty(),
        initialState: MuteVideoState(
          source: _image,
          original: _image,
          text: text,
        ),
      );
      TextScreenResult? popped;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () async => popped = await TextScreen.open(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return () => popped;
    }

    testWidgets('edits go to the cubit, and Copy copies the edited text', (
      WidgetTester tester,
    ) async {
      await openText(tester, 'Hello');

      await tester.enterText(find.byType(TextField), 'Hello world');
      verify(() => cubit.updateText('Hello world')).called(1);

      await tester.tap(find.text('Copy'));
      await tester.pump();
      expect(clipboard.single, 'Hello world');
      expect(find.text('Copied.'), findsOneWidget);
    });

    testWidgets('Arabic text reads right to left in the English UI', (
      WidgetTester tester,
    ) async {
      await openText(tester, 'مرحبا بالعالم');

      final TextField field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textDirection, TextDirection.rtl);
    });

    testWidgets('Read again pops with readAgain', (WidgetTester tester) async {
      final TextScreenResult? Function() popped = await openText(tester, 'x');

      await tester.tap(find.byTooltip('Read again'));
      await tester.pumpAndSettle();
      expect(popped(), TextScreenResult.readAgain);
    });

    testWidgets('Extract text shows for images and videos (S14)', (
      WidgetTester tester,
    ) async {
      whenListen(
        cubit,
        const Stream<MuteVideoState>.empty(),
        initialState: const MuteVideoState(source: _image, original: _image),
      );
      await tester.pumpWidget(app(const MuteVideoActions()));
      expect(find.text('Extract text'), findsOneWidget);

      final _MockCubit videoCubit = _MockCubit();
      whenListen(
        videoCubit,
        const Stream<MuteVideoState>.empty(),
        initialState: const MuteVideoState(source: _video, original: _video),
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
              value: videoCubit,
              child: const MuteVideoActions(),
            ),
          ),
        ),
      );
      expect(find.text('Extract text'), findsOneWidget);
    });
  });
}
