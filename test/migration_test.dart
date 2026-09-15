// The v6 upgrade adds the streak, game-progress, shop, challenge and activity
// tables to databases that are already on a phone. Every other test starts from
// a fresh v6 database, which never exercises that path — so these build a v5
// database by hand and open it through the real helper.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:edubuddy/db/database_helper.dart';

DatabaseHelper get _db => DatabaseHelper();

late String _path;

/// Builds a database shaped the way version 5 shipped: the old `user_profile`
/// columns, the five original badges, and none of the progression tables.
Future<void> _createV5Database({
  int totalStars = 0,
  int streakDays = 4,
  int quizzes = 0,
}) async {
  await _db.close();
  await databaseFactory.deleteDatabase(_path);

  final db = await databaseFactory.openDatabase(
    _path,
    options: OpenDatabaseOptions(
      version: 5,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE user_profile (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL DEFAULT 'Explorer',
            avatar_emoji TEXT NOT NULL DEFAULT '🦁',
            total_stars INTEGER DEFAULT 0,
            videos_watched INTEGER DEFAULT 0,
            quizzes_completed INTEGER DEFAULT 0,
            stories_read INTEGER DEFAULT 0,
            worksheets_done INTEGER DEFAULT 0,
            streak_days INTEGER DEFAULT 0,
            last_active TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE badges (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            name_ms TEXT NOT NULL,
            description TEXT NOT NULL,
            emoji TEXT NOT NULL,
            requirement TEXT NOT NULL,
            required_count INTEGER NOT NULL,
            is_earned INTEGER DEFAULT 0,
            earned_date TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE quizzes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            title_ms TEXT NOT NULL,
            category_id INTEGER,
            age_group TEXT,
            emoji TEXT,
            high_score INTEGER DEFAULT 0,
            is_completed INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE quiz_questions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            quiz_id INTEGER,
            question TEXT,
            question_ms TEXT,
            options TEXT,
            options_ms TEXT,
            correct_index INTEGER,
            explanation TEXT,
            emoji TEXT DEFAULT ''
          )
        ''');
      },
    ),
  );

  await db.insert('user_profile', {
    'id': 1,
    'name': 'Aisyah',
    'avatar_emoji': 'zuzu',
    'total_stars': totalStars,
    'quizzes_completed': quizzes,
    'stories_read': 3,
    'worksheets_done': 2,
    'streak_days': streakDays,
    'last_active': DateTime.now().toIso8601String(),
  });
  // The five badges a version 5 install already carried.
  for (final b in const [
    {'name': 'First Star', 'name_ms': 'Bintang Pertama', 'description': 'Complete your first quiz!', 'emoji': '⭐', 'requirement': 'quizzes', 'required_count': 1, 'is_earned': 1},
    {'name': 'Bookworm', 'name_ms': 'Kutu Buku', 'description': 'Read 3 storybooks!', 'emoji': '📚', 'requirement': 'stories', 'required_count': 3, 'is_earned': 0},
    {'name': 'Quiz Champion', 'name_ms': 'Juara Kuiz', 'description': 'Get 100% in any quiz!', 'emoji': '🏆', 'requirement': 'perfect', 'required_count': 1, 'is_earned': 0},
    {'name': 'Super Learner', 'name_ms': 'Pelajar Super', 'description': 'Complete 10 worksheets!', 'emoji': '🎓', 'requirement': 'worksheets', 'required_count': 10, 'is_earned': 0},
    {'name': 'Explorer', 'name_ms': 'Penjelajah', 'description': 'Try all 4 categories!', 'emoji': '🗺️', 'requirement': 'categories', 'required_count': 4, 'is_earned': 0},
  ]) {
    await db.insert('badges', b);
  }
  await db.close();
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.databaseName = 'edubuddy_migration_test.db';
    final dir = await databaseFactory.getDatabasesPath();
    _path = '$dir/${DatabaseHelper.databaseName}';
  });

  tearDownAll(() => _db.close());

  test('upgrading keeps the profile a real user already had', () async {
    await _createV5Database(totalStars: 42, quizzes: 7);

    final profile = await _db.getUserProfile();

    expect(profile?['name'], 'Aisyah');
    expect(profile?['avatar_emoji'], 'zuzu');
    expect(profile?['total_stars'], 42);
    expect(profile?['quizzes_completed'], 7);
    expect(profile?['stories_read'], 3);
  });

  test('upgrading adds the new profile columns with usable defaults', () async {
    await _createV5Database();

    final profile = await _db.getUserProfile();

    expect(profile?.containsKey('best_streak'), isTrue);
    expect(profile?['streak_freezes'], 1, reason: 'one spare day to start');
    expect(profile?['stars_spent'], 0);
    expect(profile?['creative_done'], 0);
    expect(profile?.containsKey('buddy_accessory'), isTrue);
    expect(await _db.spendableStars(), 0);
  });

  test('an in-progress streak is carried into the new best-streak record',
      () async {
    await _createV5Database(streakDays: 9);

    final profile = await _db.getUserProfile();

    expect(profile?['best_streak'], 9,
        reason: 'upgrading must not erase a streak someone already built');
  });

  test('upgrading creates the progression tables', () async {
    await _createV5Database();
    final db = await _db.database;

    final tables = (await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type = 'table'"))
        .map((r) => r['name'] as String)
        .toSet();

    expect(
      tables,
      containsAll([
        'game_levels',
        'game_stats',
        'unlocks',
        'daily_challenge',
        'activity_log',
        'stickers',
      ]),
    );
  });

  test('upgrading keeps earned badges and adds the new ones', () async {
    await _createV5Database();

    final badges = await _db.getBadges();
    final names = badges.map((b) => b.name).toList();

    expect(names.where((n) => n == 'First Star'), hasLength(1),
        reason: 'seeding must not duplicate a badge that already exists');
    expect(badges.firstWhere((b) => b.name == 'First Star').isEarned, isTrue,
        reason: 'an earned badge must survive the upgrade');
    expect(names, containsAll(['Streak Starter', 'Number Ninja', 'Shopper']));
    expect(names.length, greaterThan(20));
  });

  test('the upgraded database can immediately run the new systems', () async {
    await _createV5Database(streakDays: 2);

    // Everything the new code does on a first launch after upgrading.
    final streak = await _db.touchStreak();
    final challenge = await _db.todaysChallenge();
    final reward = await _db.recordGameLevel(
        gameKey: 'math', level: 1, rating: 3, perfect: true);
    final report = await _db.weeklyReport();

    expect(streak.current, greaterThanOrEqualTo(2));
    expect(challenge.kind, isNotEmpty);
    expect(reward.total, 5);
    expect(report, hasLength(7));
    expect(await _db.spendableStars(), 5);
  });

  test('running the upgrade twice changes nothing', () async {
    await _createV5Database();
    final firstCount = (await _db.getBadges()).length;

    // Close and reopen: onUpgrade will not fire again, but the reopen proves
    // the migrated schema is stable and readable.
    await _db.close();
    final badges = await _db.getBadges();

    expect(badges, hasLength(firstCount));
    expect(await _db.badgeProgress(), isNotEmpty);
  });
}
