import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mute_music_app/main.dart';
import 'package:mute_music_app/src/core/di/injector.dart';
import 'package:mute_music_app/src/data/local/language_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The whole app, so the check covers MaterialApp picking up the change.
void main() {
  setUp(() async {
    await GetIt.instance.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    setupInjector(await SharedPreferences.getInstance());
  });

  Future<void> pickLanguage(WidgetTester tester, String name) async {
    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  testWidgets('picking العربية switches the app to Arabic, right to left', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MuteMusicApp());
    await tester.pumpAndSettle();
    expect(find.text('Add an image, a sound or a video'), findsOneWidget);

    await pickLanguage(tester, 'العربية');

    expect(find.text('Add an image, a sound or a video'), findsNothing);
    final BuildContext context = tester.element(find.byType(Scaffold).first);
    expect(Directionality.of(context), TextDirection.rtl);
    expect(injector<SharedPreferences>().getString(LanguageStorage.key), 'ar');
  });

  testWidgets('the sheet shows both language names in their own language', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MuteMusicApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();

    expect(find.text('Phone language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
  });

  testWidgets('phone language goes back to following the device', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MuteMusicApp());
    await tester.pumpAndSettle();
    await pickLanguage(tester, 'العربية');

    await pickLanguage(tester, 'لغة الهاتف');

    // The test device is English.
    expect(find.text('Add an image, a sound or a video'), findsOneWidget);
    expect(
      injector<SharedPreferences>().containsKey(LanguageStorage.key),
      isFalse,
    );
  });
}
