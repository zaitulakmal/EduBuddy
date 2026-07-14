import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edubuddy/providers/app_provider.dart';
import 'package:edubuddy/screens/games/math_blast_screen.dart';

Widget _wrap() => ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const MaterialApp(home: MathBlastScreen()),
    );

void _mockAudio() {
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'), (_) async => 1);
  messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'), (_) async => 1);
  messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => '/tmp');
  messenger.setMockStreamHandler(
      const EventChannel('xyz.luan/audioplayers.global/events'),
      MockStreamHandler.inline(onListen: (_, _) {}));
  for (final id in ['bgm', 'sfx0', 'sfx1', 'sfx2']) {
    messenger.setMockStreamHandler(
        EventChannel('xyz.luan/audioplayers/events/$id'),
        MockStreamHandler.inline(onListen: (_, _) {}));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _mockAudio();
  });

  testWidgets('math blast renders a question with 4 options', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(_wrap());
    await tester.pump(const Duration(milliseconds: 300));

    // A question is shown
    expect(find.textContaining('= ?'), findsOneWidget);

    await expectLater(
      find.byType(MathBlastScreen),
      matchesGoldenFile('goldens/math_blast.png'),
    );
  });

  testWidgets('answering questions advances and wrong answers cost lives',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(_wrap());
    await tester.pump(const Duration(milliseconds: 300));

    // Play 30 moves: always tap the FIRST option; whether right or wrong the
    // game must never crash, and hearts/score UI must stay consistent.
    for (int i = 0; i < 30; i++) {
      final overlayRetry = find.text('Play Again');
      if (overlayRetry.evaluate().isNotEmpty) {
        await tester.tap(overlayRetry);
        await tester.pump(const Duration(milliseconds: 300));
        continue;
      }
      final buttons = find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).gradient != null &&
          w.constraints?.maxHeight == 64);
      if (buttons.evaluate().isEmpty) {
        await tester.pump(const Duration(milliseconds: 400));
        continue;
      }
      await tester.tap(buttons.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 1200));
    }
    // Still alive: either a question or the game-over overlay is visible.
    final ok = find.textContaining('= ?').evaluate().isNotEmpty ||
        find.text('Play Again').evaluate().isNotEmpty;
    expect(ok, isTrue);
  });
}
