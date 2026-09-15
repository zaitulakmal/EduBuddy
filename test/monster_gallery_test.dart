import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edubuddy/widgets/buddy_mascot.dart';
import 'package:edubuddy/widgets/score_monster.dart';

/// Renders contact sheets of every Buddy / score-monster option so the art can
/// be eyeballed without launching the app.
///
///   flutter test test/monster_gallery_test.dart
///
/// Sheets land in build/monster_gallery/.

const _cell = 120.0;

Future<void> _sheet(
  WidgetTester tester,
  String name,
  List<Widget> cells, {
  int columns = 6,
}) async {
  final rows = (cells.length / columns).ceil();
  final key = GlobalKey();
  tester.view.physicalSize = Size(columns * _cell, rows * _cell);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: Container(
          color: const Color(0xFFFCF7EC),
          child: Wrap(
            children: [
              for (final c in cells)
                SizedBox(
                  width: _cell,
                  height: _cell,
                  child: Center(child: c),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/monster_gallery/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
    expect(file.lengthSync(), greaterThan(0));
  });
}

Widget _buddy({
  BuddyVariant variant = BuddyVariant.buddy,
  BuddyExpression? expression,
  BuddyStyle? style,
  BuddyHat hat = BuddyHat.none,
  BuddyAccessory accessory = BuddyAccessory.none,
}) =>
    BuddyMascot(
      size: 104,
      animation: BuddyAnim.idle,
      variant: variant,
      expression: expression,
      style: style,
      hat: hat,
      accessory: accessory,
    );

void main() {
  testWidgets('buddy variants', (tester) async {
    await _sheet(tester, 'buddy_variants', columns: 8, [
      for (final v in BuddyVariant.values) _buddy(variant: v),
    ]);
  });

  testWidgets('buddy expressions', (tester) async {
    await _sheet(tester, 'buddy_expressions', [
      for (final e in BuddyExpression.values) _buddy(expression: e),
      for (final e in BuddyExpression.values)
        _buddy(variant: BuddyVariant.zap, expression: e),
    ]);
  });

  testWidgets('buddy styles', (tester) async {
    await _sheet(tester, 'buddy_styles', columns: 9, [
      for (final s in BuddyStyle.values)
        _buddy(variant: BuddyVariant.lumi, style: s),
    ]);
  });

  testWidgets('buddy hats and accessories', (tester) async {
    await _sheet(tester, 'buddy_wearables', [
      for (final h in BuddyHat.values)
        _buddy(variant: BuddyVariant.pip, hat: h),
      for (final a in BuddyAccessory.values)
        _buddy(variant: BuddyVariant.tako, accessory: a),
    ]);
  });

  testWidgets('score monster', (tester) async {
    await _sheet(tester, 'score_monster', columns: 8, [
      for (final c in ScoreMonsterColor.values)
        ScoreMonster(size: 100, color: c),
      for (final s in ScoreMonsterStyle.values)
        ScoreMonster(size: 100, style: s),
      for (final m in ScoreMonsterMood.values)
        ScoreMonster(size: 100, mood: m),
    ]);
  });
}
