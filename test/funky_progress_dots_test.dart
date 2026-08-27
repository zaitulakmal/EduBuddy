// A long quiz used to overrun FunkyProgressDots' row and paint the yellow and
// black debug stripes over the quiz screen. These pin the sizing so it cannot
// come back.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubuddy/widgets/illustrations.dart';

/// The quiz screen gives the dots the screen width minus 24pt of padding each
/// side; 354 is that on the narrowest phone we care about.
const double _availableWidth = 354;

Future<void> _pumpDots(
  WidgetTester tester, {
  required int total,
  required int current,
  double width = _availableWidth,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: FunkyProgressDots(total: total, current: current),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('FunkyProgressDots', () {
    for (final total in [1, 5, 10, 14, 20, 26, 40, 100]) {
      testWidgets('does not overflow with $total questions', (tester) async {
        await _pumpDots(tester, total: total, current: total);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('does not overflow when every dot is still pending',
        (tester) async {
      await _pumpDots(tester, total: 26, current: 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps its natural height whatever the question count',
        (tester) async {
      await _pumpDots(tester, total: 40, current: 20);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(FunkyProgressDots)).height,
        16,
      );
    });

    testWidgets('survives a zero-question quiz', (tester) async {
      await _pumpDots(tester, total: 0, current: 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives an unbounded width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: const FunkyProgressDots(total: 12, current: 3),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
