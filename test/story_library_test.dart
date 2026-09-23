// The story library is data, not hand-drawn painters, so these check the data
// holds up (both languages, page counts, a valid category) and that the v9
// seed lands exactly once on fresh and upgraded databases.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:edubuddy/db/database_helper.dart';
import 'package:edubuddy/models/story_library.dart';

DatabaseHelper get _db => DatabaseHelper();

late String _path;

Future<void> _deleteDatabase() async {
  await _db.close();
  await databaseFactory.deleteDatabase(_path);
}

/// A version 8 database with the storybook tables as they were before
/// `story_key` existed, holding one original book.
Future<void> _createV8Database() async {
  await _deleteDatabase();
  final db = await databaseFactory.openDatabase(
    _path,
    options: OpenDatabaseOptions(
      version: 8,
      onCreate: (db, _) async {
        await db.execute('CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, name_ms TEXT NOT NULL, icon TEXT NOT NULL, color_index INTEGER NOT NULL, age_group TEXT NOT NULL)');
        await db.execute('CREATE TABLE storybooks (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, title_ms TEXT NOT NULL, description TEXT NOT NULL, cover_emoji TEXT NOT NULL, category_id INTEGER NOT NULL, age_group TEXT NOT NULL, page_count INTEGER NOT NULL, is_read INTEGER DEFAULT 0)');
        await db.execute('CREATE TABLE storybook_pages (id INTEGER PRIMARY KEY AUTOINCREMENT, storybook_id INTEGER NOT NULL, page_number INTEGER NOT NULL, text TEXT NOT NULL, text_ms TEXT NOT NULL, background_emoji TEXT NOT NULL, background_color TEXT NOT NULL)');
        for (final name in ['Animals', 'Science', 'Language', 'Math', 'Arts & Craft']) {
          await db.insert('categories', {'name': name, 'name_ms': name, 'icon': '*', 'color_index': 0, 'age_group': 'all'});
        }
        await db.insert('storybooks', {'title': 'The Little Star', 'title_ms': 'Bintang Kecil', 'description': 'd', 'cover_emoji': '⭐', 'category_id': 1, 'age_group': 'all', 'page_count': 5, 'is_read': 1});
      },
    ),
  );
  await db.close();
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.databaseName = 'edubuddy_story_library_test.db';
    final dir = await databaseFactory.getDatabasesPath();
    _path = '$dir/${DatabaseHelper.databaseName}';
  });

  tearDownAll(() => _db.close());

  group('library content', () {
    test('twelve books with unique keys and eight to ten pages each', () {
      expect(kStoryLibrary, hasLength(12));
      final keys = kStoryLibrary.map((s) => s.key).toSet();
      expect(keys, hasLength(12));
      for (final story in kStoryLibrary) {
        expect(story.pages.length, inInclusiveRange(8, 10), reason: story.key);
      }
    });

    test('every page has text in both languages and something on stage', () {
      for (final story in kStoryLibrary) {
        expect(story.title.trim(), isNotEmpty);
        expect(story.titleMs.trim(), isNotEmpty);
        for (final (i, page) in story.pages.indexed) {
          final where = '${story.key} page ${i + 1}';
          expect(page.text.trim(), isNotEmpty, reason: where);
          expect(page.textMs.trim(), isNotEmpty, reason: where);
          expect(page.textMs, isNot(page.text), reason: '$where is untranslated');
          expect(page.shot.actors, isNotEmpty, reason: where);
          for (final a in page.shot.actors) {
            expect(a.x, inInclusiveRange(0, 1), reason: where);
            expect(a.y, inInclusiveRange(0, 1), reason: where);
          }
        }
      }
    });

    test('categories and age groups match what the app seeds', () {
      const categories = {'Animals', 'Numbers', 'Colors', 'Science', 'Language', 'Arts & Craft', 'Math', 'Music'};
      for (final story in kStoryLibrary) {
        expect(categories, contains(story.category), reason: story.key);
        expect(['preschool', 'primary', 'all'], contains(story.ageGroup), reason: story.key);
      }
    });
  });

  group('seeding', () {
    test('a fresh install has the three originals plus the library', () async {
      await _deleteDatabase();
      final books = await _db.getStorybooks();

      expect(books, hasLength(15));
      expect(books.where((b) => b.storyKey == null), hasLength(3));

      final wallet = books.firstWhere((b) => b.storyKey == 'honest_wallet');
      final pages = await _db.getStorybookPages(wallet.id!);
      expect(pages, hasLength(wallet.pageCount));
      expect(pages.map((p) => p.pageNumber), [for (var i = 1; i <= pages.length; i++) i]);
    });

    test('upgrading from v8 keeps existing books and adds the library once', () async {
      await _createV8Database();

      final books = await _db.getStorybooks();
      expect(books, hasLength(13));
      final original = books.firstWhere((b) => b.title == 'The Little Star');
      expect(original.isRead, isTrue, reason: 'reading progress survives');
      expect(original.storyKey, isNull);

      // Reopening must not seed a second copy.
      await _db.close();
      expect(await _db.getStorybooks(), hasLength(13));
    });
  });
}
