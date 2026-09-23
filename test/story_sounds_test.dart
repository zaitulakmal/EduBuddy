import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edubuddy/models/story_library.dart';
import 'package:edubuddy/models/story_sounds.dart';
import 'package:edubuddy/widgets/story_stage.dart';

void main() {
  group('sound assets', () {
    test('every tap sound an actor can make is bundled', () {
      for (final name in kStorySfxNames) {
        expect(File('assets/audio/story_$name.m4a').existsSync(), isTrue, reason: 'story_$name.m4a');
      }
    });

    test('every ambient loop a page can ask for is bundled', () {
      for (final name in kStoryAmbientNames) {
        expect(File('assets/audio/amb_$name.m4a').existsSync(), isTrue, reason: 'amb_$name.m4a');
      }
      for (final story in kStoryLibrary) {
        for (final page in story.pages) {
          expect(kStoryAmbientNames, contains(storyAmbientFor(page.shot)));
        }
      }
    });

    test('night scenes outdoors get crickets, day scenes get birds', () {
      expect(storyAmbientFor(const StoryShot(StoryBackdrop.kampung, [], night: true)), 'night');
      expect(storyAmbientFor(const StoryShot(StoryBackdrop.kampung, [])), 'day');
      expect(storyAmbientFor(const StoryShot(StoryBackdrop.beach, [], night: true)), 'waves');
    });
  });

  group('tapping', () {
    const size = Size(360, 540);
    const shot = StoryShot(StoryBackdrop.garden, [
      StorySpot(StoryActor.rainbow, 0.5, 0.36, 0.34),
      StorySpot(StoryActor.heart, 0.5, 0.36, 0.08),
      StorySpot(StoryActor.ant, 0.2, 0.68, 0.16),
    ]);

    test('a tap on an actor finds it, a tap on empty scenery finds nothing', () {
      expect(storyActorAt(shot, const Offset(0.2 * 360, 0.68 * 540), size), 2);
      expect(storyActorAt(shot, const Offset(340, 60), size), isNull);
    });

    test('a small actor in front of a big one stays tappable', () {
      expect(storyActorAt(shot, const Offset(0.5 * 360, 0.36 * 540), size), 1);
    });

    test('the hint skips scenery and picks the biggest character', () {
      expect(storyHintActor(shot), 2);
    });

    testWidgets('tapping an actor on the stage reacts without errors', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SizedBox(width: 360, height: 540, child: StoryStage(shot: shot))),
      ));
      await tester.pump(const Duration(milliseconds: 16));

      final topLeft = tester.getTopLeft(find.byType(StoryStage));
      await tester.tapAt(topLeft + const Offset(0.2 * 360, 0.68 * 540));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
    });
  });
}
