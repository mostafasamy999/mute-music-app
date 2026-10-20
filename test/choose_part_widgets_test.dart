import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mute_music_app/generated/l10n.dart';
import 'package:mute_music_app/src/core/extensions/duration_extensions.dart';
import 'package:mute_music_app/src/domain/entities/clip_range.dart';
import 'package:mute_music_app/src/presentation/screens/choose_part_screen.dart';
import 'package:mute_music_app/src/presentation/widgets/choose_part/part_length_hint.dart';
import 'package:mute_music_app/src/presentation/widgets/choose_part/part_range_slider.dart';
import 'package:mute_music_app/src/presentation/widgets/choose_part/part_time_labels.dart';

/// Spec 003 §4: the Choose a part screen.
void main() {
  Widget app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
    locale: locale,
    localizationsDelegates: const <LocalizationsDelegate<Object>>[
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: home,
  );

  ClipRange range(int startS, int endS) => ClipRange(
    start: Duration(seconds: startS),
    end: Duration(seconds: endS),
  );

  test('times read m:ss, and h:mm:ss from one hour up', () {
    expect(const Duration(seconds: 5).clock, '0:05');
    expect(const Duration(minutes: 1, seconds: 45).clock, '1:45');
    expect(const Duration(hours: 1, minutes: 2, seconds: 3).clock, '1:02:03');
  });

  group('slider', () {
    late ValueNotifier<ClipRange> value;
    late List<ClipRange> changes;

    Future<RangeSlider> pump(WidgetTester tester) async {
      value = ValueNotifier<ClipRange>(range(10, 20));
      changes = <ClipRange>[];
      await tester.pumpWidget(
        app(
          Scaffold(
            body: PartRangeSlider(
              range: value,
              duration: const Duration(seconds: 60),
              onChanged: changes.add,
            ),
          ),
        ),
      );
      return tester.widget<RangeSlider>(find.byType(RangeSlider));
    }

    testWidgets('the start handle stops 1 s before the end', (
      WidgetTester tester,
    ) async {
      final RangeSlider slider = await pump(tester);
      slider.onChanged!(const RangeValues(19800, 20000));
      expect(changes.single, range(19, 20));
    });

    testWidgets('the end handle stops 1 s after the start', (
      WidgetTester tester,
    ) async {
      final RangeSlider slider = await pump(tester);
      slider.onChanged!(const RangeValues(10000, 10200));
      expect(changes.single, range(10, 11));
    });

    testWidgets('stays left to right in Arabic', (WidgetTester tester) async {
      value = ValueNotifier<ClipRange>(range(10, 20));
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Column(
              children: <Widget>[
                PartRangeSlider(
                  range: value,
                  duration: const Duration(seconds: 60),
                  onChanged: (_) {},
                ),
                PartTimeLabels(range: value),
              ],
            ),
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pump();

      expect(
        Directionality.of(tester.element(find.byType(RangeSlider))),
        TextDirection.ltr,
      );
      final double start = tester.getCenter(find.textContaining('البداية')).dx;
      final double end = tester.getCenter(find.textContaining('النهاية')).dx;
      expect(start, lessThan(end));
    });
  });

  testWidgets('the hint shows only above the Remove music limit', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<ClipRange> value = ValueNotifier<ClipRange>(
      range(0, 300),
    );
    await tester.pumpWidget(app(Scaffold(body: PartLengthHint(range: value))));
    expect(find.byType(Text), findsNothing);

    value.value = range(0, 301);
    await tester.pump();
    expect(find.textContaining('5:00'), findsOneWidget);
  });

  testWidgets('going back returns no range', (WidgetTester tester) async {
    ClipRange? popped = range(1, 2);
    await tester.pumpWidget(
      app(
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async {
              popped = await Navigator.of(context).push<ClipRange>(
                MaterialPageRoute<ClipRange>(
                  builder: (_) => const ChoosePartScreen(
                    args: ChoosePartArgs(path: '/tmp/missing.mp4'),
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    // The spinner never settles, so pump past the page transition instead.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ChoosePartScreen), findsOneWidget);

    // No player in tests, so the video can't load and Use this part stays off.
    final FilledButton use = tester.widget<FilledButton>(
      find.byWidgetPredicate((Widget w) => w is FilledButton),
    );
    expect(use.onPressed, isNull);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(popped, isNull);
  });
}
