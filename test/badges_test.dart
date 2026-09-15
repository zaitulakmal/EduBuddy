// Badges were seeded unearned and nothing ever set is_earned, so the Badges
// row on every profile was five grey padlocks forever. These cover the award
// rules, and in particular that progress made *before* awarding existed still
// earns the badge.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:edubuddy/db/database_helper.dart';

DatabaseHelper get _db => DatabaseHelper();

/// Each test gets its own seeded database.
Future<void> _freshDatabase() async {
  await _db.close();
  final dir = await databaseFactory.getDatabasesPath();
  await databaseFactory.deleteDatabase('$dir/${DatabaseHelper.databaseName}');
}

Future<void> _setProfile({
  int quizzes = 0,
  int stories = 0,
  int worksheets = 0,
}) async {
  final db = await _db.database;
  await db.update('user_profile', {
    'quizzes_completed': quizzes,
    'stories_read': stories,
    'worksheets_done': worksheets,
  });
}

Future<Set<String>> _earnedNames() async {
  final badges = await _db.getBadges();
  return badges.where((b) => b.isEarned).map((b) => b.name).toSet();
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Own file: test files run in parallel isolates and would otherwise fight
    // over one database.
    DatabaseHelper.databaseName = 'edubuddy_badges_test.db';
  });

  setUp(_freshDatabase);
  tearDownAll(() => _db.close());

  test('a fresh profile has earned nothing', () async {
    await _db.refreshBadges();
    expect(await _earnedNames(), isEmpty);
  });

  test('one completed quiz earns First Star', () async {
    await _setProfile(quizzes: 1);
    final newly = await _db.refreshBadges();

    expect(await _earnedNames(), contains('First Star'));
    expect(newly.map((b) => b.name), contains('First Star'));
  });

  test('a badge is only reported as newly earned once', () async {
    await _setProfile(quizzes: 1);
    await _db.refreshBadges();

    final second = await _db.refreshBadges();
    expect(second, isEmpty, reason: 'already-earned badges must not re-award');
    expect(await _earnedNames(), contains('First Star'));
  });

  test('a badge is withheld until its count is actually reached', () async {
    await _setProfile(stories: 2);
    await _db.refreshBadges();
    expect(await _earnedNames(), isNot(contains('Bookworm')));

    await _setProfile(stories: 3);
    await _db.refreshBadges();
    expect(await _earnedNames(), contains('Bookworm'));
  });

  test('progress made before badges worked is still awarded', () async {
    // The regression this fixes: someone who used the app while nothing set
    // is_earned should not have to redo that work.
    await _setProfile(quizzes: 12, stories: 5, worksheets: 10);

    await _db.refreshBadges();

    expect(
      await _earnedNames(),
      containsAll(['First Star', 'Bookworm', 'Super Learner']),
    );
  });

  test('an earned date is recorded', () async {
    await _setProfile(quizzes: 1);
    await _db.refreshBadges();

    final star = (await _db.getBadges()).firstWhere((b) => b.name == 'First Star');
    expect(star.earnedDate, isNotNull);
    expect(DateTime.parse(star.earnedDate!).isAfter(DateTime(2020)), isTrue);
  });

  test('the removed Videos badge is dropped rather than left locked', () async {
    final db = await _db.database;
    // Recreate the row a pre-removal install would still be carrying.
    await db.insert('badges', {
      'name': 'Video Fan',
      'name_ms': 'Peminat Video',
      'description': 'Watch 5 videos!',
      'emoji': '📺',
      'requirement': 'videos',
      'required_count': 5,
      'is_earned': 0,
    });
    expect((await _db.getBadges()).map((b) => b.name), contains('Video Fan'));

    await _db.refreshBadges();

    expect((await _db.getBadges()).map((b) => b.name),
        isNot(contains('Video Fan')));
  });

  group('badgeProgress', () {
    test('counts a perfect quiz only when every question was right', () async {
      final db = await _db.database;
      final quiz = (await db.query('quizzes', limit: 1)).single;
      final quizId = quiz['id'] as int;
      final questions = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM quiz_questions WHERE quiz_id = ?', [quizId]))!;
      expect(questions, greaterThan(1), reason: 'need a multi-question quiz');

      await _db.saveQuizScore(quizId, questions - 1);
      expect((await _db.badgeProgress())['perfect'], 0);

      await _db.saveQuizScore(quizId, questions);
      expect((await _db.badgeProgress())['perfect'], 1);
    });

    test('counts distinct categories, not completed quizzes', () async {
      final db = await _db.database;
      final quizzes = await db.query('quizzes');
      final sameCategory = quizzes
          .where((q) => q['category_id'] == quizzes.first['category_id'])
          .toList();
      expect(sameCategory.length, greaterThan(1),
          reason: 'need two quizzes sharing a category');

      for (final q in sameCategory.take(2)) {
        await _db.saveQuizScore(q['id'] as int, 1);
      }

      expect((await _db.badgeProgress())['categories'], 1);
    });
  });
}
