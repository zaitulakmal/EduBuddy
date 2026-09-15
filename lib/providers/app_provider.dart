import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';
import '../services/sound_service.dart';
import '../models/category_model.dart';
import '../models/quiz_model.dart';
import '../models/storybook_model.dart';
import '../models/worksheet_model.dart';
import '../models/badge_model.dart';
import '../models/progression.dart';
import '../models/shop_catalog.dart';
import '../widgets/buddy_mascot.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<CategoryModel> categories = [];
  List<QuizModel> quizzes = [];
  List<StorybookModel> storybooks = [];
  List<WorksheetModel> worksheets = [];
  List<BadgeModel> badges = [];
  Map<String, dynamic>? userProfile;

  /// Progress toward every badge, so locked tiles can show how close they are.
  /// An almost-full bar is what pulls a child back, far more than a badge
  /// already earned.
  Map<String, int> badgeProgress = {};

  /// What today's visit did to the streak. Read once after [loadAll] to show
  /// the celebration, then cleared with [consumeStreakEvent].
  StreakResult? pendingStreak;

  DailyChallenge? dailyChallenge;
  Set<String> unlockedItems = {};
  Set<String> collectedStickers = {};
  int spendableStars = 0;
  double? _hoursAway;

  bool isLoading = false;
  String selectedLanguage = 'en';

  Future<void> loadAll() async {
    isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    selectedLanguage = prefs.getString('app_language') ?? 'en';
    SoundService.setLanguageResolver(() => selectedLanguage);

    // Read how long they have been away *before* recording this visit, so
    // Buddy's mood reflects the gap the child actually left.
    _hoursAway = await _db.hoursSinceLastVisit();

    categories = await _db.getCategories();
    quizzes = await _db.getQuizzes();
    storybooks = await _db.getStorybooks();
    worksheets = await _db.getWorksheets();

    final streak = await _db.touchStreak();
    pendingStreak = streak.worthCelebrating ? streak : null;

    dailyChallenge = await _db.todaysChallenge();
    userProfile = await _db.getUserProfile();
    // Award anything already deserved before the first paint, so progress made
    // before badges worked at all shows up straight away.
    await _db.refreshBadges();
    badges = await _db.getBadges();
    badgeProgress = await _db.badgeProgress();
    unlockedItems = await _db.unlockedItems();
    collectedStickers = await _db.collectedStickers();
    spendableStars = await _db.spendableStars();

    isLoading = false;
    notifyListeners();
  }

  Future<List<QuizQuestion>> loadQuizQuestions(int quizId) async {
    return _db.getQuizQuestions(quizId);
  }

  Future<List<StorybookPage>> loadStorybookPages(int storybookId) async {
    return _db.getStorybookPages(storybookId);
  }

  Future<void> saveQuizScore(int quizId, int score) async {
    await _db.saveQuizScore(quizId, score);
    await _refreshQuizzes();
    await _refreshProgress();
  }

  Future<void> markStorybookRead(int id) async {
    await _db.markStorybookRead(id);
    final idx = storybooks.indexWhere((s) => s.id == id);
    if (idx != -1) storybooks[idx].isRead = true;
    await _refreshProgress();
  }

  Future<void> markWorksheetDone(int id) async {
    await _db.markWorksheetDone(id);
    final idx = worksheets.indexWhere((w) => w.id == id);
    if (idx != -1) worksheets[idx].isCompleted = true;
    await _refreshProgress();
  }

  Future<void> updateProfile(String name, String avatar) async {
    await _db.updateUserProfile(name, avatar);
    userProfile = await _db.getUserProfile();
    notifyListeners();
  }

  Future<void> _refreshQuizzes() async {
    quizzes = await _db.getQuizzes();
  }

  /// Badges earned by the most recent bit of progress. Read it after an await
  /// on one of the progress methods to celebrate them; it is replaced each
  /// time, not accumulated.
  List<BadgeModel> newlyEarnedBadges = [];

  /// Reloads everything a completed activity can move, and re-checks badges.
  /// Every progress path funnels through here so a new activity type only has
  /// to record itself — the rest of the UI updates for free.
  Future<void> _refreshProgress() async {
    userProfile = await _db.getUserProfile();
    newlyEarnedBadges = await _db.refreshBadges();
    badges = await _db.getBadges();
    badgeProgress = await _db.badgeProgress();
    dailyChallenge = await _db.todaysChallenge();
    spendableStars = await _db.spendableStars();
    notifyListeners();
  }

  // ── Mini-games ────────────────────────────────────────────────────────────

  Future<GameStats> gameStats(String gameKey) => _db.gameStats(gameKey);

  /// Records a cleared level and returns the stars it paid, so the game can
  /// show the reward without asking the database again.
  Future<GameReward> recordGameLevel({
    required String gameKey,
    required int level,
    required int rating,
    bool perfect = false,
    int score = 0,
  }) async {
    final reward = await _db.recordGameLevel(
      gameKey: gameKey,
      level: level,
      rating: rating,
      perfect: perfect,
      score: score,
    );
    await _refreshProgress();
    return reward;
  }

  /// Remembers where a run stopped so the game resumes there next time.
  Future<void> saveGameCheckpoint(String gameKey,
      {required int level, int score = 0}) {
    return _db.saveGameCheckpoint(gameKey, level: level, score: score);
  }

  // ── Creative activities ───────────────────────────────────────────────────

  Future<int> markCreativeDone(String kind, {String? label}) async {
    final stars = await _db.markCreativeDone(kind, label: label);
    await _refreshProgress();
    return stars;
  }

  // ── Daily challenge ───────────────────────────────────────────────────────

  Future<int> claimDailyChallenge() async {
    final stars = await _db.claimDailyChallenge();
    if (stars > 0) await _refreshProgress();
    return stars;
  }

  // ── Streak ────────────────────────────────────────────────────────────────

  int get streakDays => (userProfile?['streak_days'] as int?) ?? 0;
  int get bestStreak => (userProfile?['best_streak'] as int?) ?? 0;
  int get streakFreezes => (userProfile?['streak_freezes'] as int?) ?? 0;

  /// Hands the pending streak celebration to the caller exactly once, so a
  /// rebuild does not replay it.
  StreakResult? consumeStreakEvent() {
    final event = pendingStreak;
    pendingStreak = null;
    return event;
  }

  // ── Buddy companion ───────────────────────────────────────────────────────

  BuddyMood get buddyMood =>
      buddyMoodFor(hoursAway: _hoursAway, streak: streakDays);

  BuddyHat get buddyHat => buddyHatFromId(userProfile?['buddy_hat'] as String?);

  BuddyAccessory get buddyAccessory =>
      buddyAccessoryFromId(userProfile?['buddy_accessory'] as String?);

  AppThemeSkin get themeSkin => themeSkinFor(userProfile?['theme_key'] as String?);

  /// A short line from Buddy for the Home header, matched to the mood.
  String get buddyGreeting {
    switch (buddyMood) {
      case BuddyMood.excited:
        return t("You're on fire! Let's go!", 'Kau hebat! Jom teruskan!');
      case BuddyMood.happy:
        return t('Ready to learn something?', 'Sedia belajar sesuatu?');
      case BuddyMood.sleepy:
        return t('I was getting sleepy waiting!', 'Buddy dah mengantuk tunggu!');
      case BuddyMood.missing:
        return t('I missed you! Play with me?', 'Buddy rindu! Jom main?');
    }
  }

  // ── Sticker book ──────────────────────────────────────────────────────────

  /// Adds a Buddy Reader sticker to the book. Returns false when it was
  /// already there.
  Future<bool> collectSticker(String stickerKey) async {
    final added = await _db.collectSticker(stickerKey);
    if (added) {
      collectedStickers = {...collectedStickers, stickerKey};
      notifyListeners();
    }
    return added;
  }

  // ── Star shop ─────────────────────────────────────────────────────────────

  bool owns(String itemKey) => unlockedItems.contains(itemKey);

  /// True when a Buddy variant is available — either free from the start or
  /// bought. The six original picker Buddies stay free.
  bool buddyAvailable(BuddyVariant variant) {
    final item = ShopCatalog.forValue('buddy', buddyVariantId(variant));
    return item == null || owns(item.key);
  }

  /// Buys a cosmetic. Returns false when it is already owned or unaffordable,
  /// leaving the balance untouched.
  Future<bool> buyItem(ShopItem item) async {
    final ok = await _db.unlockItem(item.key, item.cost);
    if (!ok) return false;
    unlockedItems = await _db.unlockedItems();
    await _refreshProgress();
    return true;
  }

  Future<void> setHat(BuddyHat hat) async {
    await _db.setCosmetics(hat: buddyHatId(hat));
    userProfile = await _db.getUserProfile();
    notifyListeners();
  }

  Future<void> setAccessory(BuddyAccessory accessory) async {
    await _db.setCosmetics(accessory: buddyAccessoryId(accessory));
    userProfile = await _db.getUserProfile();
    notifyListeners();
  }

  Future<void> setThemeSkin(String key) async {
    await _db.setCosmetics(theme: key);
    userProfile = await _db.getUserProfile();
    notifyListeners();
  }

  // ── Parent report ─────────────────────────────────────────────────────────

  Future<List<DayReport>> weeklyReport() => _db.weeklyReport();

  // ── Language ──────────────────────────────────────────────────────────────

  void toggleLanguage() {
    selectedLanguage = selectedLanguage == 'en' ? 'ms' : 'en';
    SoundService.setLanguageResolver(() => selectedLanguage);
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.setString('app_language', selectedLanguage));
  }

  String t(String en, String ms) => selectedLanguage == 'en' ? en : ms;

  int get totalStars => (userProfile?['total_stars'] as int?) ?? 0;
  int get quizzesCompleted => (userProfile?['quizzes_completed'] as int?) ?? 0;
  int get storiesRead => (userProfile?['stories_read'] as int?) ?? 0;
  int get worksheetsDone => (userProfile?['worksheets_done'] as int?) ?? 0;
  int get creativeDone => (userProfile?['creative_done'] as int?) ?? 0;
  String get userName => (userProfile?['name'] as String?) ?? 'Explorer';
  String get userAvatar => (userProfile?['avatar_emoji'] as String?) ?? '🦁';
}
