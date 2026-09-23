import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Lessons come from SketchStep (the web app): `npm run export:edubuddy` there
// samples every drawing into polylines and writes assets/data/sketch_lessons.json.
// Coordinates live in a 400×400 space.
const double kSketchSpace = 400;

class SketchText {
  final String en;
  final String ms;
  const SketchText(this.en, this.ms);

  factory SketchText.fromJson(Map<String, dynamic> j) =>
      SketchText(j['en'] as String, j['ms'] as String);

  String of(String lang) => lang == 'ms' ? ms : en;
}

/// One continuous run of points; `closed` when the source path ended with Z.
class SketchPolyline {
  final bool closed;
  final Float32List points; // x0, y0, x1, y1, ...

  SketchPolyline(this.closed, this.points);

  int get length => points.length ~/ 2;
  Offset operator [](int i) => Offset(points[i * 2], points[i * 2 + 1]);
}

/// One source path: may hold several subpaths (e.g. two eyes).
class SketchShape {
  final List<SketchPolyline> parts;
  SketchShape(this.parts);

  Path? _path;
  Path get path => _path ??= _build();

  Path _build() {
    final p = Path();
    for (final part in parts) {
      if (part.length == 0) continue;
      p.moveTo(part[0].dx, part[0].dy);
      for (var i = 1; i < part.length; i++) {
        p.lineTo(part[i].dx, part[i].dy);
      }
      if (part.closed) p.close();
    }
    return p;
  }
}

enum StepKind { line, shade }

class SketchStep {
  final StepKind kind;
  final String? weight; // 'guide' | 'fine'
  final int? tone; // 1..3 for shading
  final SketchText tip;
  final List<SketchShape> shapes;

  SketchStep(this.kind, this.weight, this.tone, this.tip, this.shapes);
}

class SketchLesson {
  final String id;
  final String pathId;
  final String role; // skill | subject | practice
  final String level; // easy | medium | hard
  final int minutes;
  final SketchText title;
  final List<SketchStep> steps;

  SketchLesson(this.id, this.pathId, this.role, this.level, this.minutes, this.title, this.steps);
}

class SketchPathGroup {
  final String id;
  final SketchText title;
  final List<SketchLesson> lessons;
  SketchPathGroup(this.id, this.title, this.lessons);
}

class SketchLibrary {
  final List<SketchPathGroup> paths;
  SketchLibrary(this.paths);

  Iterable<SketchLesson> get lessons => paths.expand((p) => p.lessons);

  SketchLesson? lesson(String id) {
    for (final l in lessons) {
      if (l.id == id) return l;
    }
    return null;
  }

  static Future<SketchLibrary>? _loading;

  static Future<SketchLibrary> load() => _loading ??= _load();

  static Future<SketchLibrary> _load() async {
    final raw = await rootBundle.loadString('assets/data/sketch_lessons.json');
    final json = await compute(jsonDecode, raw) as Map<String, dynamic>;
    return _parse(json);
  }

  static SketchLibrary _parse(Map<String, dynamic> json) {
    SketchPolyline poly(dynamic j) {
      final p = (j['p'] as List).cast<num>();
      final pts = Float32List(p.length);
      for (var i = 0; i < p.length; i++) {
        pts[i] = p[i] / 10;
      }
      return SketchPolyline(j['c'] as bool, pts);
    }

    return SketchLibrary([
      for (final p in json['paths'] as List)
        SketchPathGroup(
          p['id'] as String,
          SketchText.fromJson(p['title'] as Map<String, dynamic>),
          [
            for (final l in p['lessons'] as List)
              SketchLesson(
                l['id'] as String,
                p['id'] as String,
                l['role'] as String,
                l['level'] as String,
                l['minutes'] as int,
                SketchText.fromJson(l['title'] as Map<String, dynamic>),
                [
                  for (final s in l['steps'] as List)
                    SketchStep(
                      s['kind'] == 'shade' ? StepKind.shade : StepKind.line,
                      s['weight'] as String?,
                      s['tone'] as int?,
                      SketchText.fromJson(s['tip'] as Map<String, dynamic>),
                      [
                        for (final shape in s['paths'] as List)
                          SketchShape([for (final part in shape as List) poly(part)]),
                      ],
                    ),
                ],
              ),
          ],
        ),
    ]);
  }
}
