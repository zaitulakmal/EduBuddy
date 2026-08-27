import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';
import '../services/sound_service.dart';
import '../models/category_model.dart';
import '../models/quiz_model.dart';
import '../models/storybook_model.dart';
import '../models/worksheet_model.dart';
import '../models/badge_model.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<CategoryModel> categories = [];
  List<QuizModel> quizzes = [];
  List<StorybookModel> storybooks = [];
  List<WorksheetModel> worksheets = [];
  List<BadgeModel> badges = [];
  Map<String, dynamic>? userProfile;

  bool isLoading = false;
  String selectedLanguage = 'en';

  Future<void> loadAll() async {
    isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    selectedLanguage = prefs.getString('app_language') ?? 'en';
    SoundService.setLanguageResolver(() => selectedLanguage);
    categories = await _db.getCategories();
    quizzes = await _db.getQuizzes();
    storybooks = await _db.getStorybooks();
    worksheets = await _db.getWorksheets();
    userProfile = await _db.getUserProfile();
    // Award anything already deserved before the first paint, so progress made
    // before badges worked at all shows up straight away.
    await _db.refreshBadges();
    badges = await _db.getBadges();
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
    userProfile = await _db.getUserProfile();
    await _awardBadges();
    notifyListeners();
  }

  Future<void> markStorybookRead(int id) async {
    await _db.markStorybookRead(id);
    final idx = storybooks.indexWhere((s) => s.id == id);
    if (idx != -1) storybooks[idx].isRead = true;
    userProfile = await _db.getUserProfile();
    await _awardBadges();
    notifyListeners();
  }

  Future<void> markWorksheetDone(int id) async {
    await _db.markWorksheetDone(id);
    final idx = worksheets.indexWhere((w) => w.id == id);
    if (idx != -1) worksheets[idx].isCompleted = true;
    userProfile = await _db.getUserProfile();
    await _awardBadges();
    notifyListeners();
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

  Future<void> _awardBadges() async {
    newlyEarnedBadges = await _db.refreshBadges();
    badges = await _db.getBadges();
  }

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
  String get userName => (userProfile?['name'] as String?) ?? 'Explorer';
  String get userAvatar => (userProfile?['avatar_emoji'] as String?) ?? '🦁';
}
