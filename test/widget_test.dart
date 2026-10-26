import 'package:flutter_test/flutter_test.dart';
import 'package:mute_music_app/main.dart';
import 'package:mute_music_app/src/core/di/injector.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/mute_video_content.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/add_media_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    setupInjector(await SharedPreferences.getInstance());
  });

  testWidgets('opens on the mute video screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MuteMusicApp());
    await tester.pumpAndSettle();

    expect(find.byType(MuteVideoContent), findsOneWidget);
    // Spec 006 §2.1: the empty screen shows only the add widget.
    expect(find.byType(AddMediaButton), findsOneWidget);
  });
}
