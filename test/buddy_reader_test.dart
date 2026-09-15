import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edubuddy/providers/app_provider.dart';
import 'package:edubuddy/screens/games/buddy_reader_screen.dart';

Widget _wrap() => ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const MaterialApp(home: BuddyReaderScreen()),
    );

void _mockPlugins() {
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'), (_) async => 1);
  messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'), (_) async => 1);
  messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'), (_) async => 1);
  messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => '/tmp');
  messenger.setMockStreamHandler(
      const EventChannel('xyz.luan/audioplayers.global/events'),
      MockStreamHandler.inline(onListen: (_, _) {}));
  for (final id in ['bgm', 'song', 'sfx0', 'sfx1', 'sfx2']) {
    messenger.setMockStreamHandler(
        EventChannel('xyz.luan/audioplayers/events/$id'),
        MockStreamHandler.inline(onListen: (_, _) {}));
  }
}

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_wrap());
  await tester.pump(const Duration(milliseconds: 300));
}

/// Pumps in small steps until [finder] shows up (or [max] passes).
Future<void> _until(WidgetTester tester, Finder finder,
    {Duration max = const Duration(seconds: 20)}) async {
  var waited = Duration.zero;
  while (finder.evaluate().isEmpty && waited < max) {
    await tester.pump(const Duration(milliseconds: 100));
    waited += const Duration(milliseconds: 100);
  }
}

Future<void> _drag(WidgetTester tester, Offset from, Offset to) async {
  final gesture = await tester.startGesture(from);
  await tester.pump(const Duration(milliseconds: 30));
  // Several moves so the pan recogniser wins the arena before the drop.
  for (var s = 1; s <= 8; s++) {
    await gesture.moveTo(Offset.lerp(from, to, s / 8)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  // One frame starts the spring back or snap, the next lets it settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _solveBoard(WidgetTester tester, int pieces) async {
  for (var i = 0; i < pieces; i++) {
    await _drag(
      tester,
      tester.getCenter(find.byKey(ValueKey('reader-piece-$i'))),
      tester.getCenter(find.byKey(ValueKey('reader-slot-$i'))),
    );
  }
}

/// Drops "c" (piece 0 of "cat") on the "t" outline.
Future<void> _wrongDrop(WidgetTester tester) => _drag(
      tester,
      tester.getCenter(find.byKey(const ValueKey('reader-piece-0'))),
      tester.getCenter(find.byKey(const ValueKey('reader-slot-2'))),
    );

/// Unmounts the screen so its timers are cancelled before the test ends.
Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _mockPlugins();
  });

  testWidgets('opens on a chapter card, then straight into the first word',
      (tester) async {
    await _open(tester);

    expect(find.text('Chapter'), findsOneWidget);
    await _until(tester, find.byKey(const ValueKey('reader-piece-0')));

    // Chapter 1, word 1 is "cat": three letters to drag.
    expect(find.byKey(const ValueKey('reader-piece-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-piece-3')), findsNothing);
    await _close(tester);
  });

  testWidgets('finishing a word rolls straight on to the next word', (tester) async {
    await _open(tester);
    await _until(tester, find.byKey(const ValueKey('reader-piece-0')));

    await _solveBoard(tester, 3); // c-a-t
    // No sentence and no menu: the next word ("sun") starts by itself.
    await _until(tester, find.textContaining('"sun"'));
    expect(find.textContaining('"sun"'), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-slot-3')), findsNothing);
    await _close(tester);
  });

  testWidgets('five words end in a sticker chest, then chapter 2 begins',
      (tester) async {
    await _open(tester);
    // Chapter 1: cat, sun, bus, hat, bee — each three letters.
    for (final word in ['cat', 'sun', 'bus', 'hat', 'bee']) {
      await _until(tester, find.textContaining('"$word"'));
      await _solveBoard(tester, 3);
    }

    await _until(tester, find.byKey(const ValueKey('reader-chest')));
    expect(find.text('Chapter 1 done!'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reader-chest')));
    await _until(tester, find.text('New sticker!'));
    expect(find.text('Unicorn'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1)); // let the card finish popping in
    await tester.tap(find.text('Next chapter'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Chapter'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Tap the chest!'), findsNothing,
        reason: 'the last chapter\'s hint must not follow the child into the next');
    await _close(tester);
  });

  testWidgets('a wrong drop costs a heart and the letter springs home',
      (tester) async {
    await _open(tester);
    await _until(tester, find.byKey(const ValueKey('reader-piece-0')));

    final piece = find.byKey(const ValueKey('reader-piece-0'));
    final home = tester.getCenter(piece);
    await _wrongDrop(tester);

    expect((tester.getCenter(piece) - home).distance, lessThan(2));
    expect(find.byKey(const ValueKey('reader-heart-2-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-heart-1-full')), findsOneWidget);
    await _close(tester);
  });

  testWidgets('losing every heart offers a retry of the chapter', (tester) async {
    await _open(tester);
    await _until(tester, find.byKey(const ValueKey('reader-piece-0')));

    for (var i = 0; i < 3; i++) {
      await _wrongDrop(tester);
    }
    expect(find.text('Out of hearts!'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Chapter'), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-heart-2-full')), findsOneWidget);
    await _close(tester);
  });
}
