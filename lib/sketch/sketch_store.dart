import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../db/database_helper.dart';
import 'pencil.dart';

class SketchDrawing {
  final String id;
  final String lessonId;
  final DateTime createdAt;
  final int score;
  final int stars;
  final String imagePath;
  SketchDrawing(this.id, this.lessonId, this.createdAt, this.score, this.stars, this.imagePath);
}

class SketchDraft {
  final String lessonId;
  final int step;
  final List<int> scores;
  final List<PencilStroke> strokes;
  final DateTime updatedAt;
  final String? imagePath;
  SketchDraft(this.lessonId, this.step, this.scores, this.strokes, this.updatedAt, this.imagePath);
}

/// Drawings, drafts and stars for the Draw tab, stored in EduBuddy's SQLite
/// database with the PNGs next to it in the app's documents folder.
class SketchStore {
  SketchStore._();
  static final SketchStore instance = SketchStore._();

  // The v5 migration creates the tables, but a device whose database already reports
  // v5 or later (e.g. from a test build) would skip it. Creating them if missing, once,
  // keeps the Draw tab working either way.
  Future<Database>? _ready;
  Future<Database> get _db => _ready ??= DatabaseHelper().database.then((db) async {
        await DatabaseHelper.createSketchTables(db);
        return db;
      });

  Future<Directory> _dir() async {
    final d = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'sketches'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<String> _writePng(String name, Uint8List png) async {
    final f = File(p.join((await _dir()).path, name));
    await f.writeAsBytes(png, flush: true);
    return f.path;
  }

  Future<void> _deleteFile(String? path) async {
    if (path == null) return;
    final f = File(path);
    if (await f.exists()) await f.delete();
  }

  // ------------------------------------------------------------ Finished drawings

  Future<void> saveDrawing(String lessonId, int score, int stars, Uint8List png) async {
    final id = const Uuid().v4();
    final path = await _writePng('$id.png', png);
    await (await _db).insert('sketch_drawings', {
      'id': id,
      'lesson_id': lessonId,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'score': score,
      'stars': stars,
      'image_path': path,
    });
  }

  Future<List<SketchDrawing>> drawings() async {
    final rows = await (await _db).query('sketch_drawings', orderBy: 'created_at DESC');
    return [
      for (final r in rows)
        SketchDrawing(r['id'] as String, r['lesson_id'] as String, DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
            r['score'] as int, r['stars'] as int, r['image_path'] as String),
    ];
  }

  Future<void> deleteDrawing(SketchDrawing d) async {
    await (await _db).delete('sketch_drawings', where: 'id = ?', whereArgs: [d.id]);
    await _deleteFile(d.imagePath);
  }

  // ------------------------------------------------------------ Drafts (lessons in progress)

  Future<SketchDraft?> draft(String lessonId) async {
    final rows = await (await _db).query('sketch_drafts', where: 'lesson_id = ?', whereArgs: [lessonId]);
    return rows.isEmpty ? null : _draft(rows.first);
  }

  Future<List<SketchDraft>> drafts() async {
    final rows = await (await _db).query('sketch_drafts', orderBy: 'updated_at DESC');
    return rows.map(_draft).toList();
  }

  SketchDraft _draft(Map<String, Object?> r) => SketchDraft(
        r['lesson_id'] as String,
        r['step'] as int,
        (jsonDecode(r['scores'] as String) as List).cast<int>(),
        [for (final s in jsonDecode(r['strokes'] as String) as List) PencilStroke.fromJson(s as Map<String, dynamic>)],
        DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int),
        r['image_path'] as String?,
      );

  Future<void> saveDraft(String lessonId, int step, List<int> scores, List<PencilStroke> strokes, Uint8List preview) async {
    // A new file name each time, so image caches never show an older preview.
    final old = await draft(lessonId);
    final path = await _writePng('draft-$lessonId-${DateTime.now().millisecondsSinceEpoch}.png', preview);
    await (await _db).insert(
      'sketch_drafts',
      {
        'lesson_id': lessonId,
        'step': step,
        'scores': jsonEncode(scores),
        'strokes': jsonEncode([for (final s in strokes) s.toJson()]),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'image_path': path,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (old?.imagePath != path) await _deleteFile(old?.imagePath);
  }

  Future<void> deleteDraft(String lessonId) async {
    final existing = await draft(lessonId);
    await (await _db).delete('sketch_drafts', where: 'lesson_id = ?', whereArgs: [lessonId]);
    await _deleteFile(existing?.imagePath);
  }

  // ------------------------------------------------------------ Stars per lesson

  Future<Map<String, int>> stars() async {
    final rows = await (await _db).query('sketch_progress');
    return {for (final r in rows) r['lesson_id'] as String: r['stars'] as int};
  }

  Future<void> recordProgress(String lessonId, int score, int stars) async {
    final db = await _db;
    final prev = await db.query('sketch_progress', where: 'lesson_id = ?', whereArgs: [lessonId]);
    final oldStars = prev.isEmpty ? 0 : prev.first['stars'] as int;
    final oldBest = prev.isEmpty ? 0 : prev.first['best'] as int;
    await db.insert(
      'sketch_progress',
      {'lesson_id': lessonId, 'stars': stars > oldStars ? stars : oldStars, 'best': score > oldBest ? score : oldBest},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
