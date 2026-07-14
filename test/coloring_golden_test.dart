import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubuddy/screens/coloring/coloring_screen.dart';

void main() {
  testWidgets('coloring pages render', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MaterialApp(home: ColoringScreen()));
    await tester.pump(const Duration(milliseconds: 300));

    final titles = ['Sunshine', 'Happy Cat', 'Big Tree', 'Rainbow', 'Cute Fish', 'Butterfly'];
    for (final t in titles) {
      await tester.scrollUntilVisible(find.text(t), 80,
          scrollable: find.byType(Scrollable).first);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text(t));
      await tester.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byType(ColoringScreen),
        matchesGoldenFile('goldens/coloring_$t.png'),
      );
    }
  });
}
