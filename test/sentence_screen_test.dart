import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edubuddy/providers/app_provider.dart';
import 'package:edubuddy/screens/games/sentence_screen.dart';

Widget _wrap() => ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const MaterialApp(home: SentenceScreen()),
    );

void _mockPlugins() {
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'), (_) async => 1);
  messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'), (_) async => 1);
  messenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (_) async => 1);
  messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'), (_) async => '/tmp');
  messenger.setMockStreamHandler(const EventChannel('xyz.luan/audioplayers.global/events'),
      MockStreamHandler.inline(onListen: (_, _) {}));
  for (final id in ['bgm', 'song', 'sfx0', 'sfx1', 'sfx2']) {
    messenger.setMockStreamHandler(EventChannel('xyz.luan/audioplayers/events/$id'),
        MockStreamHandler.inline(onListen: (_, _) {}));
  }
}

Future<void> _until(WidgetTester tester, Finder finder,
    {Duration max = const Duration(seconds: 20)}) async {
  var waited = Duration.zero;
  while (finder.evaluate().isEmpty && waited < max) {
    await tester.pump(const Duration(milliseconds: 100));
    waited += const Duration(milliseconds: 100);
  }
}

Future<void> _drag(WidgetTester tester, int piece, int slot) async {
  final from = tester.getCenter(find.byKey(ValueKey('reader-piece-$piece')));
  final to = tester.getCenter(find.byKey(ValueKey('reader-slot-$slot')));
  final gesture = await tester.startGesture(from);
  await tester.pump(const Duration(milliseconds: 30));
  for (var s = 1; s <= 8; s++) {
    await gesture.moveTo(Offset.lerp(from, to, s / 8)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Finder _heart(int i, String state) => find.byKey(ValueKey('reader-heart-$i-$state'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _mockPlugins();
  });

  testWidgets('build, fill and match take turns and roll on by themselves',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Chapter'), findsOneWidget);

    // 1 — Build: "The cat sleeps on the bed." (six words to place)
    await _until(tester, find.text('Put the words in order!'));
    for (var i = 0; i < 6; i++) {
      await _drag(tester, i, i);
    }

    // 2 — Fill: "The sun is ___ today." (outline 3). Piece 0 is "hot"; 1 and 2 are wrong.
    await _until(tester, find.text('Which word fits?'));
    await _drag(tester, 1, 3);
    expect(_heart(2, 'empty'), findsOneWidget, reason: 'a wrong word costs a heart');
    await _drag(tester, 0, 3);

    // 3 — Match: "We ride the yellow bus." against a bus and two decoys.
    await _until(tester, find.text('Which picture is it?'));
    expect(find.text('We ride the yellow bus.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('match-ant')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_heart(1, 'empty'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('match-bus')));

    // 4 — Back to building, with no menu in between.
    await _until(tester, find.text('Put the words in order!'));
    expect(find.text('Put the words in order!'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
