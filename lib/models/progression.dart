/// Value types for the progression systems that sit on top of the raw content:
/// daily streaks, per-game progress, the daily challenge, the star shop, the
/// Buddy companion's mood, and the parent report.
///
/// These are plain data — every rule that decides *when* they change lives in
/// [DatabaseHelper], so the same rule is applied whether the caller is a screen
/// or a test.
library;

/// What one visit did to the daily streak.
///
/// Returned by `touchStreak()` so the caller can celebrate an extended streak
/// without re-deriving why it changed.
class StreakResult {
  /// Length of the streak *after* this visit, in days. Always at least 1.
  final int current;

  /// Longest streak ever reached, after this visit.
  final int best;

  /// True when this visit pushed the streak forward (a new day).
  final bool advanced;

  /// True when a missed day was covered by a freeze instead of breaking.
  final bool freezeUsed;

  /// True when the streak broke and restarted from 1.
  final bool reset;

  /// Freezes still banked after this visit.
  final int freezesLeft;

  /// Freezes granted by reaching this visit's milestone (0 most days).
  final int freezesEarned;

  const StreakResult({
    required this.current,
    required this.best,
    required this.advanced,
    required this.freezeUsed,
    required this.reset,
    required this.freezesLeft,
    required this.freezesEarned,
  });

  /// True when the streak is worth interrupting the child for — a new day, a
  /// rescue, or a fresh personal best.
  bool get worthCelebrating => advanced || freezeUsed;

  /// True when this visit set a new personal record.
  bool get isPersonalBest => advanced && current == best && current > 1;
}

/// Where the child has reached in one mini-game.
class GameStats {
  final String gameKey;

  /// Highest level ever reached — what a resume should start from.
  final int bestLevel;

  /// Level the child was on when they last stopped, so an interrupted run
  /// resumes exactly where it left off rather than at the top.
  final int lastLevel;

  final int highScore;
  final int plays;

  /// Rating (1-3 stars) per level index that has been cleared.
  final Map<int, int> ratings;

  const GameStats({
    required this.gameKey,
    required this.bestLevel,
    required this.lastLevel,
    required this.highScore,
    required this.plays,
    required this.ratings,
  });

  static GameStats empty(String gameKey) => GameStats(
    gameKey: gameKey,
    bestLevel: 0,
    lastLevel: 0,
    highScore: 0,
    plays: 0,
    ratings: const {},
  );

  int get levelsCleared => ratings.length;
  int get totalRating => ratings.values.fold(0, (a, b) => a + b);

  /// Level to drop the child into when they reopen the game. One past their
  /// best clear, so they continue rather than repeat.
  int get resumeLevel =>
      lastLevel > 0 ? lastLevel : (bestLevel + 1).clamp(1, 999);
}

/// Stars paid out for finishing a game level, and why.
class GameReward {
  /// Stars for clearing a level that had never been cleared before.
  final int clearStars;

  /// Bonus stars for clearing it without losing a life, first time only.
  final int perfectStars;

  /// True when this run beat the previously stored rating for the level.
  final bool improved;

  /// True when this level had never been cleared before.
  final bool firstClear;

  const GameReward({
    this.clearStars = 0,
    this.perfectStars = 0,
    this.improved = false,
    this.firstClear = false,
  });

  int get total => clearStars + perfectStars;
  bool get paid => total > 0;
}

/// The one challenge offered today. Chosen from the calendar date, so it is
/// the same all day, changes at local midnight, and never depends on when the
/// app happened to be opened.
class DailyChallenge {
  /// Local `yyyy-MM-dd` this challenge belongs to.
  final String day;

  /// One of: quiz, story, worksheet, math, word, memory, creative.
  final String kind;

  /// How many of [kind] are needed today.
  final int targetCount;

  /// How many have been done today.
  final int progress;

  /// Stars paid when it is completed.
  final int reward;

  final bool claimed;

  const DailyChallenge({
    required this.day,
    required this.kind,
    required this.targetCount,
    required this.progress,
    required this.reward,
    required this.claimed,
  });

  bool get isComplete => progress >= targetCount;

  /// Ready to pay out: finished, but the stars have not been handed over yet.
  bool get isClaimable => isComplete && !claimed;

  double get fraction =>
      targetCount == 0 ? 0 : (progress / targetCount).clamp(0.0, 1.0);
}

/// One purchasable cosmetic. Cosmetics only — nothing here gates learning
/// content, so a child who never spends a star can still reach every activity.
class ShopItem {
  final String key;

  /// What it changes: 'buddy' (a new avatar), 'hat', or 'theme'.
  final String kind;

  final String name;
  final String nameMs;

  /// Cost in stars.
  final int cost;

  /// Value the app reads once unlocked — a Buddy variant id, a hat id, or a
  /// theme id, depending on [kind].
  final String value;

  const ShopItem({
    required this.key,
    required this.kind,
    required this.name,
    required this.nameMs,
    required this.cost,
    required this.value,
  });
}

/// One day's worth of activity, for the weekly parent report.
class DayReport {
  /// Local `yyyy-MM-dd`.
  final String day;

  /// Activity count keyed by kind (quiz, story, worksheet, math, ...).
  final Map<String, int> counts;

  /// Stars earned that day.
  final int stars;

  const DayReport({
    required this.day,
    required this.counts,
    required this.stars,
  });

  int get total => counts.values.fold(0, (a, b) => a + b);
  bool get active => total > 0;
}

/// How Buddy is feeling, derived from how recently the child visited.
///
/// This drives the companion loop: Buddy is bright when you keep coming back
/// and droopy when you have been away, which is the pull that brings a child
/// back tomorrow.
enum BuddyMood {
  /// Visited today and on a streak.
  excited,

  /// Visited today.
  happy,

  /// A day has slipped by.
  sleepy,

  /// Away long enough that Buddy is waiting.
  missing,
}

/// Picks Buddy's mood from time away and streak length.
///
/// [hoursAway] is time since the last recorded visit; a negative or null value
/// means "never visited", which reads as a fresh, happy Buddy rather than a
/// neglected one.
BuddyMood buddyMoodFor({double? hoursAway, int streak = 0}) {
  if (hoursAway == null || hoursAway < 0) return BuddyMood.happy;
  if (hoursAway >= 48) return BuddyMood.missing;
  if (hoursAway >= 20) return BuddyMood.sleepy;
  return streak >= 2 ? BuddyMood.excited : BuddyMood.happy;
}
