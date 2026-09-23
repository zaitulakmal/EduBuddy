import 'package:edubuddy/main.dart' as app;
import 'package:edubuddy/sketch/sketch_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Draws a whole lesson on the device the way a child would: trace every guide,
// tap next, and check the drawing lands in My drawings. Also checks drafts.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> wait(WidgetTester t, [int ms = 600]) async {
    for (var i = 0; i < ms ~/ 50; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> traceStep(WidgetTester t, SketchStep step) async {
    final paper = t.getRect(find.byKey(const Key('sketch-paper')));
    final k = paper.width / kSketchSpace;
    Offset at(Offset p) => paper.topLeft + p * k;
    if (step.kind == StepKind.shade) {
      // Hatch across the area in rows.
      final b = step.shapes.map((s) => s.path.getBounds()).reduce((a, c) => a.expandToInclude(c));
      for (var y = b.top; y <= b.bottom; y += 6) {
        final g = await t.startGesture(at(Offset(b.left, y)));
        for (var x = b.left; x <= b.right; x += 6) {
          await g.moveTo(at(Offset(x, y)));
        }
        await g.up();
      }
    } else {
      for (final shape in step.shapes) {
        for (final part in shape.parts) {
          final g = await t.startGesture(at(part[0]));
          for (var i = 1; i < part.length; i += 2) {
            await g.moveTo(at(part[i]));
          }
          await g.up();
        }
      }
    }
    await t.pump();
  }

  testWidgets('draw a lesson, save it, and continue a draft', (t) async {
    app.main();
    await wait(t, 4000); // splash
    // The lessons now hang off the Drawing Studio card in Home's creative
    // activities row, not a bottom tab, so scroll down to it first.
    final studio = find.text('Drawing\nStudio');
    await t.scrollUntilVisible(
      studio,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await wait(t, 600);
    await t.tap(studio);
    await wait(t, 1500);
    await binding.takeScreenshot('1-tab');

    final lib = await SketchLibrary.load();
    final fish = lib.lesson('fish')!;
    await t.tap(find.textContaining(fish.title.en).first);
    await wait(t, 1500);
    await binding.takeScreenshot('2-lesson-start');

    for (var i = 0; i < fish.steps.length; i++) {
      await traceStep(t, fish.steps[i]);
      if (i == 3) await binding.takeScreenshot('3-lesson-mid');
      await t.tap(find.text(i == fish.steps.length - 1 ? 'Finish drawing' : 'Next step'));
      await wait(t, 1000);
    }
    await wait(t, 1500);
    await binding.takeScreenshot('4-done');
    expect(find.text('Drawing finished'), findsOneWidget);

    await t.tap(find.text('Back to lessons'));
    await wait(t, 1200);

    // Start another lesson, draw two steps, leave: it must come back as a draft.
    final snail = lib.lesson('snail')!;
    await t.tap(find.textContaining(snail.title.en).first);
    await wait(t, 1500);
    for (var i = 0; i < 2; i++) {
      await traceStep(t, snail.steps[i]);
      await t.tap(find.text('Next step'));
      await wait(t, 800);
    }
    await traceStep(t, snail.steps[2]);
    await wait(t, 800);
    await t.tap(find.byTooltip('Close'));
    await wait(t, 1500);
    await binding.takeScreenshot('5-tab-continue');
    expect(find.text('Continue'), findsWidgets);

    await t.tap(find.text('My drawings'));
    await wait(t, 1500);
    await binding.takeScreenshot('6-gallery');
    expect(find.text('Not finished yet'), findsOneWidget);
    expect(find.text('Finished'), findsOneWidget);

    await t.tap(find.text('Continue').first);
    await wait(t, 1500);
    await binding.takeScreenshot('7-resumed');
    expect(find.text('Step 3 of ${snail.steps.length}'), findsOneWidget);
  });
}
