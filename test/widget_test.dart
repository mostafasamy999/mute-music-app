import 'package:flutter_test/flutter_test.dart';
import 'package:mute_music_app/main.dart';
import 'package:mute_music_app/src/core/di/injector.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/mute_video_content.dart';
import 'package:mute_music_app/src/presentation/widgets/mute_video/pick_video_button.dart';

void main() {
  setUpAll(setupInjector);

  testWidgets('opens on the mute video screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MuteMusicApp());
    await tester.pumpAndSettle();

    expect(find.byType(MuteVideoContent), findsOneWidget);
    expect(find.byType(PickVideoButton), findsOneWidget);
  });
}
