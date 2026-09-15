// The retention loop had three holes: the streak columns existed but nothing
// ever wrote them, mini-game progress lived only in widget state so it died on
// restart, and the games fed no stars at all. These cover the rules that close
// them, plus the systems built on top (daily challenge, shop, parent report).

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:edubuddy/db/database_helper.dart';
import 'package:edubuddy/models/shop_catalog.dart';
import 'package:edubuddy/widgets/buddy_mascot.dart';

DatabaseHelper get _db => DatabaseHelper();

Future<void> _freshDatabase() async {
  await _db.close();
  final dir = await databaseFactory.getDatabasesPath();
  await databaseFactory.deleteDatabase('$dir/${DatabaseHelper.databaseName}');
}

/// Pins `last_active` so streak tests control the clock instead of racing it.
Future<void> _setLastActive(DateTime when, {int streak = 1, int freezes = 1}) async {
  final db = await _db.database;
  await db.update('user_profile', {
    'last_active': when.toIso8601String(),
    'streak_days': streak,
    'streak_freezes': freezes,
  });
}

Future<int> _stars() async {
  final p = await _db.getUserProfile();
  return (p?['total_stars'] as int?) ?? 0;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Own file: test files run in parallel isolates and would otherwise fight
    // over one database.
    DatabaseHelper.databaseName = 'edubuddy_progression_test.db';
  });

  setUp(_freshDatabase);
  tearDownAll(() => _db.close());

  group('daily streak', () {
    final day0 = DateTime(2026, 3, 1, 9);

    test('opening the app twice in one day is still one day', () async {
      await _setLastActive(day0, streak: 3);

      final result = await _db.touchStreak(now: day0.add(const Duration(hours: 6)));

      expect(result.current, 3);
      expect(result.advanced, isFalse);
    });

    test('the next day extends the streak', () async {
      await _setLastActive(day0, streak: 3);

      final result = await _db.touchStreak(now: day0.add(const Duration(days: 1)));

      expect(result.current, 4);
      expect(result.advanced, isTrue);
      expect(result.freezeUsed, isFalse);
    });

    test('just after midnight still counts as the next day', () async {
      // A child playing at 21:00 then again at 07:00 is two calendar days,
      // even though only 10 hours passed.
      await _setLastActive(DateTime(2026, 3, 1, 21), streak: 2);

      final result = await _db.touchStreak(now: DateTime(2026, 3, 2, 7));

      expect(result.current, 3);
    });

    test('one missed day is covered by a freeze instead of breaking', () async {
      await _setLastActive(day0, streak: 6, freezes: 1);

      final result = await _db.touchStreak(now: day0.add(const Duration(days: 2)));

      expect(result.current, 7, reason: 'the streak survives the gap');
      expect(result.freezeUsed, isTrue);
      expect(result.freezesLeft, 0);
    });

    test('a missed day with no freeze left restarts the streak', () async {
      await _setLastActive(day0, streak: 6, freezes: 0);

      final result = await _db.touchStreak(now: day0.add(const Duration(days: 2)));

      expect(result.current, 1);
      expect(result.reset, isTrue);
    });

    test('two missed days break the streak even with a freeze banked', () async {
      await _setLastActive(day0, streak: 9, freezes: 1);

      final result = await _db.touchStreak(now: day0.add(const Duration(days: 3)));

      expect(result.current, 1);
      expect(result.reset, isTrue);
      expect(result.freezesLeft, 1, reason: 'an unusable freeze is not spent');
    });

    test('a freeze is granted every five days, capped at two', () async {
      await _setLastActive(day0, streak: 4, freezes: 0);

      final fifth = await _db.touchStreak(now: day0.add(const Duration(days: 1)));
      expect(fifth.current, 5);
      expect(fifth.freezesEarned, 1);
      expect(fifth.freezesLeft, 1);

      await _setLastActive(day0, streak: 9, freezes: 2);
      final capped = await _db.touchStreak(now: day0.add(const Duration(days: 1)));
      expect(capped.current, 10);
      expect(capped.freezesEarned, 0, reason: 'two freezes is the cap');
      expect(capped.freezesLeft, 2);
    });

    test('a clock that moves backwards never breaks the streak', () async {
      await _setLastActive(day0, streak: 12);

      final result = await _db.touchStreak(now: day0.subtract(const Duration(days: 2)));

      expect(result.current, 12);
      expect(result.reset, isFalse);
    });

    test('the best streak is remembered after a reset', () async {
      await _setLastActive(day0, streak: 8, freezes: 0);

      final broken = await _db.touchStreak(now: day0.add(const Duration(days: 5)));

      expect(broken.current, 1);
      expect(broken.best, 8);
    });
  });

  group('mini-game progress and rewards', () {
    test('a first clear pays two stars', () async {
      final before = await _stars();

      final reward = await _db.recordGameLevel(
          gameKey: 'math', level: 1, rating: 2, perfect: false);

      expect(reward.clearStars, 2);
      expect(reward.perfectStars, 0);
      expect(reward.firstClear, isTrue);
      expect(await _stars(), before + 2);
    });

    test('a clean run pays the three star bonus on top', () async {
      final before = await _stars();

      final reward = await _db.recordGameLevel(
          gameKey: 'math', level: 1, rating: 3, perfect: true);

      expect(reward.total, 5);
      expect(await _stars(), before + 5);
    });

    test('replaying a beaten level pays nothing', () async {
      await _db.recordGameLevel(
          gameKey: 'math', level: 1, rating: 3, perfect: true);
      final after = await _stars();

      final replay = await _db.recordGameLevel(
          gameKey: 'math', level: 1, rating: 3, perfect: true);

      expect(replay.total, 0, reason: 'grinding level 1 must not farm stars');
      expect(await _stars(), after);
    });

    test('going back for a clean run on an old level still pays the bonus',
        () async {
      await _db.recordGameLevel(
          gameKey: 'math', level: 2, rating: 1, perfect: false);
      final after = await _stars();

      final perfected = await _db.recordGameLevel(
          gameKey: 'math', level: 2, rating: 3, perfect: true);

      expect(perfected.clearStars, 0, reason: 'already cleared once');
      expect(perfected.perfectStars, 3);
      expect(await _stars(), after + 3);
    });

    test('progress survives and reports the level to resume from', () async {
      await _db.recordGameLevel(gameKey: 'word', level: 1, rating: 3);
      await _db.recordGameLevel(gameKey: 'word', level: 2, rating: 2);
      await _db.saveGameCheckpoint('word', level: 3, score: 120);

      final stats = await _db.gameStats('word');

      expect(stats.bestLevel, 3);
      expect(stats.resumeLevel, 3);
      expect(stats.highScore, 120);
      expect(stats.levelsCleared, 2);
      expect(stats.ratings[1], 3);
    });

    test('a lower rating never overwrites a better one', () async {
      await _db.recordGameLevel(gameKey: 'memory', level: 4, rating: 3);
      await _db.recordGameLevel(gameKey: 'memory', level: 4, rating: 1);

      final stats = await _db.gameStats('memory');
      expect(stats.ratings[4], 3);
    });

    test('games feed the badge requirements they are meant to', () async {
      for (var level = 1; level <= 5; level++) {
        await _db.recordGameLevel(gameKey: 'math', level: level, rating: 3);
      }

      final progress = await _db.badgeProgress();
      expect(progress['math_level'], 5);
      expect(progress['game_levels'], 5);

      await _db.refreshBadges();
      final earned =
          (await _db.getBadges()).where((b) => b.isEarned).map((b) => b.name);
      expect(earned, contains('Number Ninja'));
    });
  });

  group('daily challenge', () {
    test('the same date always yields the same challenge', () async {
      final day = DateTime(2026, 5, 20, 8);

      final first = await _db.todaysChallenge(now: day);
      final again = await _db.todaysChallenge(now: day.add(const Duration(hours: 9)));

      expect(again.kind, first.kind);
      expect(again.day, first.day);
    });

    test('a different date yields a fresh, unclaimed challenge', () async {
      final today = await _db.todaysChallenge(now: DateTime(2026, 5, 20));
      final tomorrow = await _db.todaysChallenge(now: DateTime(2026, 5, 21));

      expect(tomorrow.day, isNot(today.day));
      expect(tomorrow.progress, 0);
      expect(tomorrow.claimed, isFalse);
    });

    test('doing the matching activity completes it, and it pays out once',
        () async {
      // Find the next day whose challenge is the Math Blast task, so the test
      // drives the real reward path on a date it controls.
      DateTime? mathDay;
      for (var i = 0; i < 21 && mathDay == null; i++) {
        final day = DateTime(2026, 6, 1).add(Duration(days: i));
        if ((await _db.todaysChallenge(now: day)).kind == 'math') mathDay = day;
      }
      expect(mathDay, isNotNull, reason: 'math is in the rotation');

      final challenge = await _db.todaysChallenge(now: mathDay);
      expect(challenge.targetCount, 2);
      expect(challenge.isComplete, isFalse);

      await _db.recordGameLevel(
          gameKey: 'math', level: 1, rating: 3, perfect: true, now: mathDay);
      final half = await _db.todaysChallenge(now: mathDay);
      expect(half.progress, 1);
      expect(half.isClaimable, isFalse, reason: 'half done pays nothing');
      expect(await _db.claimDailyChallenge(now: mathDay), 0);

      await _db.recordGameLevel(
          gameKey: 'math', level: 2, rating: 3, perfect: true, now: mathDay);
      final done = await _db.todaysChallenge(now: mathDay);
      expect(done.isClaimable, isTrue);

      final before = await _stars();
      final paid = await _db.claimDailyChallenge(now: mathDay);
      expect(paid, done.reward);
      expect(await _stars(), before + paid);

      expect(await _db.claimDailyChallenge(now: mathDay), 0,
          reason: 'a challenge pays out only once');
      expect((await _db.badgeProgress())['daily'], 1);
    });

    test('an unrelated activity does not move the challenge along', () async {
      DateTime? mathDay;
      for (var i = 0; i < 21 && mathDay == null; i++) {
        final day = DateTime(2026, 6, 1).add(Duration(days: i));
        if ((await _db.todaysChallenge(now: day)).kind == 'math') mathDay = day;
      }

      await _db.recordGameLevel(
          gameKey: 'word', level: 1, rating: 3, now: mathDay);

      expect((await _db.todaysChallenge(now: mathDay)).progress, 0);
    });
  });

  group('star shop', () {
    test('an unlock deducts from spendable stars but not from lifetime stars',
        () async {
      await _db.recordGameLevel(gameKey: 'math', level: 1, rating: 3, perfect: true);
      await _db.recordGameLevel(gameKey: 'math', level: 2, rating: 3, perfect: true);
      final lifetime = await _stars();
      expect(await _db.spendableStars(), lifetime);

      final ok = await _db.unlockItem('buddy_zuzu', 8);

      expect(ok, isTrue);
      expect(await _db.spendableStars(), lifetime - 8);
      expect(await _stars(), lifetime,
          reason: 'spending must not undo star-collecting badges');
    });

    test('an unaffordable item changes nothing', () async {
      final ok = await _db.unlockItem('buddy_nova', 9999);

      expect(ok, isFalse);
      expect(await _db.unlockedItems(), isEmpty);
      expect(await _db.spendableStars(), 0);
    });

    test('buying the same item twice is refused', () async {
      await _db.recordGameLevel(gameKey: 'math', level: 1, rating: 3, perfect: true);

      expect(await _db.unlockItem('hat_party', 5), isTrue);
      final spent = await _db.spendableStars();
      expect(await _db.unlockItem('hat_party', 5), isFalse);
      expect(await _db.spendableStars(), spent);
    });

    test('every shop cosmetic maps to a real Buddy, hat or accessory', () {
      for (final item in ShopCatalog.items) {
        switch (item.kind) {
          case 'buddy':
            expect(kBuddyVariantIds.containsKey(item.value), isTrue,
                reason: '${item.key} must not fall back to the default Buddy');
          case 'hat':
            expect(buddyHatFromId(item.value), isNot(BuddyHat.none),
                reason: '${item.key} must not fall back to no hat');
          case 'accessory':
            expect(buddyAccessoryFromId(item.value), isNot(BuddyAccessory.none),
                reason: '${item.key} must not fall back to no accessory');
        }
      }
      final keys = ShopCatalog.items.map((i) => i.key).toList();
      expect(keys.toSet().length, keys.length, reason: 'shop keys are unique');
    });

    test('a worn accessory is saved without touching the hat', () async {
      await _db.setCosmetics(hat: 'crown');
      await _db.setCosmetics(accessory: 'scarf');

      final profile = await _db.getUserProfile();
      expect(profile?['buddy_accessory'], 'scarf');
      expect(profile?['buddy_hat'], 'crown');
    });
  });

  group('sticker book', () {
    test('collecting a sticker stores it once', () async {
      expect(await _db.collectSticker('sticker_unicorn'), isTrue);
      expect(await _db.collectSticker('sticker_unicorn'), isFalse,
          reason: 'a sticker already in the book is not added again');
      expect(await _db.collectedStickers(), {'sticker_unicorn'});
    });

    test('stickers are not shop purchases', () async {
      await _db.collectSticker('sticker_dragon');

      expect(await _db.unlockedItems(), isEmpty,
          reason: 'the Shopper badges count unlocks; stickers must not feed them');
      final progress = await _db.badgeProgress();
      expect(progress['unlocks'], 0);
    });
  });

  group('parent report', () {
    test('a week is always seven days, including quiet ones', () async {
      final report = await _db.weeklyReport();
      expect(report, hasLength(7));
      expect(report.every((d) => !d.active), isTrue);
    });

    test('finished activities show up on the right day with their stars',
        () async {
      final today = DateTime.now();
      await _db.recordGameLevel(
          gameKey: 'math', level: 1, rating: 3, perfect: true, now: today);
      final books = await _db.getStorybooks();
      await _db.markStorybookRead(books.first.id!);

      final report = await _db.weeklyReport(now: today);
      final day = report.last;

      expect(day.day, DatabaseHelper.dayKey(today));
      expect(day.counts['math'], 1);
      expect(day.counts['story'], 1);
      expect(day.stars, greaterThanOrEqualTo(7));
    });
  });

  group('creative activities', () {
    test('a finished creative activity pays a star and counts toward badges',
        () async {
      final before = await _stars();

      for (var i = 0; i < 5; i++) {
        await _db.markCreativeDone('coloring', label: 'Page $i');
      }

      expect(await _stars(), before + 5);
      expect((await _db.badgeProgress())['creative'], 5);

      await _db.refreshBadges();
      final earned =
          (await _db.getBadges()).where((b) => b.isEarned).map((b) => b.name);
      expect(earned, contains('Little Artist'));
    });
  });
}
