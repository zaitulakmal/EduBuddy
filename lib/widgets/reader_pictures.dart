import 'dart:math';
import 'package:flutter/material.dart';

/// Hand-drawn pictures for Buddy Reader, painted in the same chunky style as
/// the Buddy mascot: rounded shapes, a thick ink outline, and a little face on
/// anything that can carry one. Drawn in code so every picture matches the
/// app and nothing depends on the phone's emoji font.
///
/// Every picture is authored on a 100 × 100 grid and scaled to [size].
enum ReaderPic {
  cat, sun, bus, hat, bee, cow, egg, fox, car, ant, cup, key, bed, box, hen,
  fish, frog, cake, star, duck, lion, moon, tree, ship, ball, book, kite, milk,
  rain, shoe, bird, lamp, door, rice, apple, house, snake, whale, bread, mouse,
  cloud, flower, banana, turtle, elephant,
}

/// Small drawn icons for the Buddy Reader interface.
enum ReaderIcon { chest, chestOpen, stickerBook, flame, brokenHeart }

class ReaderPicture extends StatelessWidget {
  final ReaderPic pic;
  final double size;
  const ReaderPicture(this.pic, {super.key, this.size = 110});

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _PicPainter(pic)),
      );
}

class ReaderIconArt extends StatelessWidget {
  final ReaderIcon icon;
  final double size;
  const ReaderIconArt(this.icon, {super.key, this.size = 24});

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _IconPainter(icon)),
      );
}

// ─── Palette ──────────────────────────────────────────────────────────────────

const _ink = Color(0xFF3D3526);
const _white = Color(0xFFFFFDF6);
const _yellow = Color(0xFFFFC93C);
const _orange = Color(0xFFFF9F43);
const _red = Color(0xFFFF5A5F);
const _pink = Color(0xFFFF9EC4);
const _green = Color(0xFF7CC655);
const _darkGreen = Color(0xFF4E9A36);
const _blue = Color(0xFF5DB7F5);
const _sky = Color(0xFFBDE6FA);
const _purple = Color(0xFF9B6BFF);
const _brown = Color(0xFFB9784A);
const _tan = Color(0xFFE8B26A);
const _grey = Color(0xFFB9C0CC);
const _cheek = Color(0x88FF80AB);

// ─── Pen ──────────────────────────────────────────────────────────────────────

/// Fill-then-outline drawing helpers on the 100-unit grid.
class _Pen {
  final Canvas c;
  _Pen(this.c);

  final _line = Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.2
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  void shape(Path p, Color fill, {bool outline = true}) {
    c.drawPath(p, Paint()..color = fill);
    if (outline) c.drawPath(p, _line);
  }

  Path circlePath(double x, double y, double r) =>
      Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r));

  Path ovalPath(double l, double t, double w, double h) =>
      Path()..addOval(Rect.fromLTWH(l, t, w, h));

  Path rrectPath(double l, double t, double w, double h, double r) =>
      Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(l, t, w, h), Radius.circular(r)));

  Path polyPath(List<Offset> pts) => Path()..addPolygon(pts, true);

  void circle(double x, double y, double r, Color fill) => shape(circlePath(x, y, r), fill);
  void oval(double l, double t, double w, double h, Color fill) =>
      shape(ovalPath(l, t, w, h), fill);
  void rrect(double l, double t, double w, double h, double r, Color fill) =>
      shape(rrectPath(l, t, w, h, r), fill);
  void poly(List<Offset> pts, Color fill) => shape(polyPath(pts), fill);

  /// Several overlapping shapes drawn as one outlined blob.
  void blob(List<Path> parts, Color fill) {
    var p = parts.first;
    for (final q in parts.skip(1)) {
      p = Path.combine(PathOperation.union, p, q);
    }
    shape(p, fill);
  }

  void line(double x1, double y1, double x2, double y2, {double w = 3.2, Color color = _ink}) {
    c.drawLine(
      Offset(x1, y1),
      Offset(x2, y2),
      Paint()
        ..color = color
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round,
    );
  }

  void stroke(Path p, {double w = 3.2, Color color = _ink}) {
    c.drawPath(
      p,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void eye(double x, double y, {double r = 3.6}) {
    c.drawOval(Rect.fromCenter(center: Offset(x, y), width: r * 2, height: r * 2.3),
        Paint()..color = _ink);
    c.drawCircle(Offset(x + r * 0.35, y - r * 0.5), r * 0.38, Paint()..color = Colors.white);
  }

  void smile(double x, double y, {double w = 8}) {
    stroke(Path()
      ..moveTo(x - w / 2, y)
      ..quadraticBezierTo(x, y + w * 0.6, x + w / 2, y));
  }

  /// Two eyes, a smile and pink cheeks centred on ([x], [y]).
  void face(double x, double y, {double spread = 12, double scale = 1, bool cheeks = true}) {
    eye(x - spread / 2, y, r: 3.6 * scale);
    eye(x + spread / 2, y, r: 3.6 * scale);
    smile(x, y + 7 * scale, w: 8 * scale);
    if (cheeks) {
      final p = Paint()..color = _cheek;
      c.drawOval(
          Rect.fromCenter(center: Offset(x - spread / 2 - 5 * scale, y + 7 * scale), width: 7 * scale, height: 4.5 * scale), p);
      c.drawOval(
          Rect.fromCenter(center: Offset(x + spread / 2 + 5 * scale, y + 7 * scale), width: 7 * scale, height: 4.5 * scale), p);
    }
  }
}

// ─── Word pictures ────────────────────────────────────────────────────────────

class _PicPainter extends CustomPainter {
  final ReaderPic pic;
  const _PicPainter(this.pic);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final d = _Pen(canvas);
    switch (pic) {
      case ReaderPic.cat: _cat(d);
      case ReaderPic.sun: _sun(d);
      case ReaderPic.bus: _bus(d);
      case ReaderPic.hat: _hat(d);
      case ReaderPic.bee: _bee(d);
      case ReaderPic.cow: _cow(d);
      case ReaderPic.egg: _egg(d);
      case ReaderPic.fox: _fox(d);
      case ReaderPic.car: _car(d);
      case ReaderPic.ant: _ant(d);
      case ReaderPic.cup: _cup(d);
      case ReaderPic.key: _key(d);
      case ReaderPic.bed: _bed(d);
      case ReaderPic.box: _box(d);
      case ReaderPic.hen: _hen(d);
      case ReaderPic.fish: _fish(d);
      case ReaderPic.frog: _frog(d);
      case ReaderPic.cake: _cake(d);
      case ReaderPic.star: _star(d);
      case ReaderPic.duck: _duck(d);
      case ReaderPic.lion: _lion(d);
      case ReaderPic.moon: _moon(d);
      case ReaderPic.tree: _tree(d);
      case ReaderPic.ship: _ship(d);
      case ReaderPic.ball: _ball(d);
      case ReaderPic.book: _book(d);
      case ReaderPic.kite: _kite(d);
      case ReaderPic.milk: _milk(d);
      case ReaderPic.rain: _rain(d);
      case ReaderPic.shoe: _shoe(d);
      case ReaderPic.bird: _bird(d);
      case ReaderPic.lamp: _lamp(d);
      case ReaderPic.door: _door(d);
      case ReaderPic.rice: _rice(d);
      case ReaderPic.apple: _apple(d);
      case ReaderPic.house: _house(d);
      case ReaderPic.snake: _snake(d);
      case ReaderPic.whale: _whale(d);
      case ReaderPic.bread: _bread(d);
      case ReaderPic.mouse: _mouse(d);
      case ReaderPic.cloud: _cloud(d);
      case ReaderPic.flower: _flower(d);
      case ReaderPic.banana: _banana(d);
      case ReaderPic.turtle: _turtle(d);
      case ReaderPic.elephant: _elephant(d);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PicPainter old) => old.pic != pic;

  static const _o = Offset.new;

  void _cat(_Pen d) {
    d.poly([_o(18, 44), _o(22, 10), _o(44, 28)], _orange);
    d.poly([_o(82, 44), _o(78, 10), _o(56, 28)], _orange);
    d.poly([_o(24, 34), _o(25, 19), _o(36, 28)], _pink);
    d.poly([_o(76, 34), _o(75, 19), _o(64, 28)], _pink);
    d.oval(12, 22, 76, 66, _orange);
    d.face(50, 54, spread: 22);
    for (final dy in [-3.0, 3.0]) {
      d.line(20, 62 + dy, 8, 60 + dy * 2, w: 2.2);
      d.line(80, 62 + dy, 92, 60 + dy * 2, w: 2.2);
    }
  }

  void _sun(_Pen d) {
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4;
      final tip = Offset(50 + cos(a) * 46, 50 + sin(a) * 46);
      final l = Offset(50 + cos(a - 0.28) * 30, 50 + sin(a - 0.28) * 30);
      final r = Offset(50 + cos(a + 0.28) * 30, 50 + sin(a + 0.28) * 30);
      d.poly([l, tip, r], _orange);
    }
    d.circle(50, 50, 28, _yellow);
    d.face(50, 48, spread: 18);
  }

  void _bus(_Pen d) {
    d.rrect(6, 22, 88, 56, 12, _yellow);
    for (final x in [14.0, 38.0, 62.0]) {
      d.rrect(x, 30, 20, 18, 4, _sky);
    }
    d.line(6, 56, 94, 56, w: 3);
    d.circle(28, 80, 10, const Color(0xFF5A5A6A));
    d.circle(72, 80, 10, const Color(0xFF5A5A6A));
    d.face(50, 64, spread: 14, scale: 0.8, cheeks: false);
  }

  void _hat(_Pen d) {
    d.oval(6, 62, 88, 24, _purple);
    d.rrect(24, 18, 52, 58, 10, _purple);
    d.rrect(24, 54, 52, 10, 2, _red);
    d.face(50, 36, spread: 16, scale: 0.9);
  }

  void _bee(_Pen d) {
    d.oval(26, 10, 24, 30, _sky);
    d.oval(46, 8, 24, 30, _sky);
    d.line(30, 36, 22, 20, w: 2.6);
    d.circle(21, 18, 3, _ink);
    final body = d.ovalPath(14, 30, 72, 54);
    d.c.drawPath(body, Paint()..color = _yellow);
    d.c.save();
    d.c.clipPath(body);
    d.c.drawRect(const Rect.fromLTWH(46, 20, 9, 70), Paint()..color = _ink);
    d.c.drawRect(const Rect.fromLTWH(64, 20, 9, 70), Paint()..color = _ink);
    d.c.restore();
    d.stroke(body);
    d.poly([_o(86, 55), _o(96, 58), _o(86, 62)], _ink);
    d.face(31, 54, spread: 12, scale: 0.85);
  }

  void _cow(_Pen d) {
    d.poly([_o(24, 30), _o(14, 12), _o(34, 22)], _white);
    d.poly([_o(76, 30), _o(86, 12), _o(66, 22)], _white);
    d.oval(2, 32, 22, 14, _white);
    d.oval(76, 32, 22, 14, _white);
    final head = d.ovalPath(16, 20, 68, 72);
    d.c.drawPath(head, Paint()..color = _white);
    d.c.save();
    d.c.clipPath(head);
    d.c.drawOval(const Rect.fromLTWH(12, 18, 28, 24), Paint()..color = _ink);
    d.c.drawOval(const Rect.fromLTWH(64, 40, 22, 20), Paint()..color = _ink);
    d.c.restore();
    d.stroke(head);
    d.oval(26, 62, 48, 28, _pink);
    d.circle(40, 76, 3, _ink);
    d.circle(60, 76, 3, _ink);
    d.eye(38, 48);
    d.eye(62, 48);
  }

  void _egg(_Pen d) {
    d.oval(22, 8, 56, 84, const Color(0xFFFFF1D6));
    d.face(50, 56, spread: 18);
  }

  void _fox(_Pen d) {
    d.poly([_o(14, 40), _o(18, 6), _o(42, 26)], _orange);
    d.poly([_o(86, 40), _o(82, 6), _o(58, 26)], _orange);
    d.shape(
        Path()
          ..moveTo(8, 34)
          ..quadraticBezierTo(50, 14, 92, 34)
          ..quadraticBezierTo(78, 76, 50, 92)
          ..quadraticBezierTo(22, 76, 8, 34)
          ..close(),
        _orange);
    d.shape(
        Path()
          ..moveTo(18, 52)
          ..quadraticBezierTo(38, 58, 50, 90)
          ..quadraticBezierTo(62, 58, 82, 52)
          ..quadraticBezierTo(66, 80, 50, 92)
          ..quadraticBezierTo(34, 80, 18, 52)
          ..close(),
        _white);
    d.circle(50, 86, 4, _ink);
    d.eye(36, 48);
    d.eye(64, 48);
  }

  void _car(_Pen d) {
    d.blob([d.rrectPath(6, 46, 88, 30, 12), d.rrectPath(22, 22, 54, 38, 14)], _red);
    d.rrect(30, 30, 16, 16, 4, _sky);
    d.rrect(52, 30, 16, 16, 4, _sky);
    d.circle(28, 78, 11, const Color(0xFF5A5A6A));
    d.circle(72, 78, 11, const Color(0xFF5A5A6A));
    d.face(50, 58, spread: 14, scale: 0.8, cheeks: false);
  }

  void _ant(_Pen d) {
    const body = Color(0xFFD9674E);
    for (final x in [36.0, 50.0, 64.0]) {
      d.line(x, 60, x - 8, 86, w: 3);
    }
    d.line(80, 34, 74, 12, w: 2.6);
    d.line(86, 38, 94, 16, w: 2.6);
    d.circle(24, 58, 18, body);
    d.circle(50, 58, 11, body);
    d.circle(76, 46, 16, body);
    d.eye(71, 43, r: 3);
    d.eye(83, 43, r: 3);
    d.smile(77, 52, w: 6);
  }

  void _cup(_Pen d) {
    d.stroke(
        Path()
          ..moveTo(74, 40)
          ..cubicTo(98, 38, 98, 70, 70, 70),
        w: 8);
    d.stroke(
        Path()
          ..moveTo(74, 40)
          ..cubicTo(98, 38, 98, 70, 70, 70),
        w: 3.5,
        color: const Color(0xFF2BB3A3));
    d.poly([_o(16, 30), _o(80, 30), _o(72, 88), _o(24, 88)], const Color(0xFF2BB3A3));
    for (final x in [36.0, 52.0]) {
      d.stroke(
          Path()
            ..moveTo(x, 22)
            ..quadraticBezierTo(x - 6, 14, x, 8),
          w: 2.6,
          color: _grey);
    }
    d.face(48, 54, spread: 16);
  }

  void _key(_Pen d) {
    d.rrect(44, 42, 50, 12, 4, _yellow);
    d.rrect(74, 50, 8, 16, 2, _yellow);
    d.rrect(86, 50, 7, 11, 2, _yellow);
    d.circle(28, 48, 24, _yellow);
    d.circle(28, 56, 6, _white);
    d.eye(21, 40, r: 3);
    d.eye(35, 40, r: 3);
  }

  void _bed(_Pen d) {
    d.rrect(6, 22, 18, 66, 6, _brown);
    d.rrect(84, 50, 12, 38, 5, _brown);
    d.rrect(12, 56, 82, 22, 6, _blue);
    d.oval(18, 40, 30, 20, _white);
    d.rrect(42, 48, 50, 30, 8, _red);
    d.line(48, 60, 86, 60, w: 2.4);
  }

  void _box(_Pen d) {
    d.poly([_o(70, 38), _o(90, 20), _o(90, 70), _o(70, 90)], const Color(0xFFC0844F));
    d.poly([_o(10, 38), _o(30, 20), _o(90, 20), _o(70, 38)], const Color(0xFFF0C58C));
    d.rrect(10, 38, 60, 52, 2, _tan);
    d.rrect(34, 38, 12, 14, 1, const Color(0xFFFFE9B8));
    d.face(40, 66, spread: 16);
  }

  void _hen(_Pen d) {
    d.circle(44, 18, 7, _red);
    d.circle(54, 15, 8, _red);
    d.circle(63, 20, 6, _red);
    d.oval(12, 20, 76, 74, _white);
    d.shape(
        Path()
          ..moveTo(20, 60)
          ..quadraticBezierTo(30, 82, 50, 74)
          ..quadraticBezierTo(34, 66, 20, 60)
          ..close(),
        const Color(0xFFEFE6D2));
    d.poly([_o(74, 46), _o(92, 52), _o(74, 58)], _orange);
    d.oval(68, 56, 10, 14, _red);
    d.eye(58, 42);
    d.line(40, 92, 38, 99, w: 3, color: _orange);
    d.line(60, 92, 62, 99, w: 3, color: _orange);
  }

  void _fish(_Pen d) {
    d.poly([_o(64, 50), _o(94, 26), _o(94, 74)], _orange);
    d.poly([_o(40, 26), _o(56, 14), _o(62, 30)], _orange);
    d.oval(6, 24, 66, 52, _blue);
    d.stroke(
        Path()
          ..moveTo(46, 30)
          ..quadraticBezierTo(38, 50, 46, 70),
        w: 2.6);
    d.eye(24, 44, r: 4.2);
    d.smile(24, 56, w: 8);
  }

  void _frog(_Pen d) {
    d.circle(30, 34, 16, _green);
    d.circle(70, 34, 16, _green);
    d.oval(8, 34, 84, 56, _green);
    d.circle(30, 34, 9, _white);
    d.circle(70, 34, 9, _white);
    d.eye(30, 35, r: 4);
    d.eye(70, 35, r: 4);
    d.stroke(
        Path()
          ..moveTo(28, 62)
          ..quadraticBezierTo(50, 80, 72, 62),
        w: 3.2);
    final p = Paint()..color = _cheek;
    d.c.drawOval(Rect.fromCenter(center: const Offset(20, 60), width: 10, height: 6), p);
    d.c.drawOval(Rect.fromCenter(center: const Offset(80, 60), width: 10, height: 6), p);
  }

  void _cake(_Pen d) {
    d.rrect(46, 12, 8, 22, 3, _sky);
    d.shape(
        Path()
          ..moveTo(50, 2)
          ..quadraticBezierTo(57, 9, 50, 13)
          ..quadraticBezierTo(43, 9, 50, 2)
          ..close(),
        _orange);
    d.rrect(12, 34, 76, 56, 10, _pink);
    d.shape(
        Path()
          ..moveTo(12, 46)
          ..lineTo(12, 44)
          ..quadraticBezierTo(12, 34, 22, 34)
          ..lineTo(78, 34)
          ..quadraticBezierTo(88, 34, 88, 44)
          ..lineTo(88, 50)
          ..quadraticBezierTo(80, 58, 72, 50)
          ..quadraticBezierTo(62, 60, 50, 50)
          ..quadraticBezierTo(38, 60, 28, 50)
          ..quadraticBezierTo(20, 58, 12, 50)
          ..close(),
        _white);
    d.face(50, 68, spread: 18);
  }

  void _star(_Pen d) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 46.0 : 21.0;
      final a = -pi / 2 + i * pi / 5;
      final pt = Offset(50 + cos(a) * r, 54 + sin(a) * r);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    p.close();
    d.shape(p, _yellow);
    d.face(50, 54, spread: 14, scale: 0.9);
  }

  void _duck(_Pen d) {
    d.oval(8, 46, 72, 44, _yellow);
    d.circle(62, 34, 20, _yellow);
    d.shape(
        Path()
          ..moveTo(78, 34)
          ..quadraticBezierTo(98, 36, 94, 44)
          ..quadraticBezierTo(86, 50, 76, 44)
          ..close(),
        _orange);
    d.stroke(
        Path()
          ..moveTo(24, 62)
          ..quadraticBezierTo(38, 80, 54, 64),
        w: 3);
    d.eye(64, 30, r: 4);
  }

  void _lion(_Pen d) {
    const mane = Color(0xFFD9822B);
    for (var i = 0; i < 12; i++) {
      final a = i * pi / 6;
      d.circle(50 + cos(a) * 32, 52 + sin(a) * 32, 14, mane);
    }
    d.circle(50, 52, 34, mane);
    d.circle(24, 26, 8, const Color(0xFFFFD27A));
    d.circle(76, 26, 8, const Color(0xFFFFD27A));
    d.circle(50, 54, 28, const Color(0xFFFFD27A));
    d.oval(38, 58, 24, 18, _white);
    d.poly([_o(44, 58), _o(56, 58), _o(50, 65)], _ink);
    d.eye(39, 46);
    d.eye(61, 46);
  }

  void _moon(_Pen d) {
    final outer = d.circlePath(50, 50, 42);
    final bite = d.circlePath(72, 38, 36);
    d.shape(Path.combine(PathOperation.difference, outer, bite), _yellow);
    for (final x in [20.0, 34.0]) {
      d.stroke(
          Path()
            ..moveTo(x - 4, 54)
            ..quadraticBezierTo(x, 58, x + 4, 54),
          w: 2.8);
    }
    d.smile(27, 66, w: 7);
  }

  void _tree(_Pen d) {
    d.rrect(40, 58, 20, 38, 4, _brown);
    d.blob([
      d.circlePath(30, 48, 22),
      d.circlePath(70, 48, 22),
      d.circlePath(50, 30, 26),
      d.rrectPath(18, 44, 64, 24, 12),
    ], _green);
    d.face(50, 44, spread: 18);
  }

  void _ship(_Pen d) {
    d.line(50, 10, 50, 62, w: 3.4);
    d.poly([_o(54, 12), _o(54, 56), _o(86, 56)], _white);
    d.poly([_o(46, 20), _o(46, 56), _o(20, 56)], _yellow);
    d.poly([_o(6, 62), _o(94, 62), _o(80, 86), _o(20, 86)], _red);
    d.eye(40, 72, r: 3);
    d.eye(60, 72, r: 3);
    d.stroke(
        Path()
          ..moveTo(4, 94)
          ..quadraticBezierTo(16, 88, 28, 94)
          ..quadraticBezierTo(40, 100, 52, 94)
          ..quadraticBezierTo(64, 88, 76, 94)
          ..quadraticBezierTo(88, 100, 96, 94),
        w: 3,
        color: _blue);
  }

  void _ball(_Pen d) {
    final ball = d.circlePath(50, 52, 40);
    d.c.drawPath(ball, Paint()..color = _white);
    d.c.save();
    d.c.clipPath(ball);
    d.c.drawPath(
        Path()
          ..moveTo(50, 52)
          ..lineTo(10, 0)
          ..lineTo(50, 0)
          ..close(),
        Paint()..color = _red);
    d.c.drawPath(
        Path()
          ..moveTo(50, 52)
          ..lineTo(100, 30)
          ..lineTo(100, 80)
          ..close(),
        Paint()..color = _blue);
    d.c.drawPath(
        Path()
          ..moveTo(50, 52)
          ..lineTo(0, 70)
          ..lineTo(30, 100)
          ..close(),
        Paint()..color = _yellow);
    d.c.restore();
    d.stroke(ball);
    d.face(50, 50, spread: 16, scale: 0.9);
  }

  void _book(_Pen d) {
    d.poly([_o(4, 26), _o(50, 34), _o(96, 26), _o(96, 82), _o(50, 90), _o(4, 82)], _blue);
    d.poly([_o(10, 20), _o(50, 28), _o(50, 82), _o(10, 74)], _white);
    d.poly([_o(90, 20), _o(50, 28), _o(50, 82), _o(90, 74)], _white);
    for (final y in [38.0, 50.0, 62.0]) {
      d.line(18, y - 4, 42, y, w: 2.2, color: _grey);
      d.line(58, y, 82, y - 4, w: 2.2, color: _grey);
    }
  }

  void _kite(_Pen d) {
    d.stroke(
        Path()
          ..moveTo(50, 76)
          ..cubicTo(40, 88, 66, 90, 58, 99),
        w: 2.6);
    d.poly([_o(50, 4), _o(84, 38), _o(50, 78), _o(16, 38)], _pink);
    d.line(50, 4, 50, 78, w: 2.4);
    d.line(16, 38, 84, 38, w: 2.4);
    d.face(50, 50, spread: 14, scale: 0.8, cheeks: false);
  }

  void _milk(_Pen d) {
    d.poly([_o(26, 32), _o(36, 12), _o(64, 12), _o(74, 32)], _blue);
    d.rrect(26, 32, 48, 60, 4, _white);
    d.rrect(26, 44, 48, 22, 1, _sky);
    d.face(50, 54, spread: 14, scale: 0.85);
  }

  void _rain(_Pen d) {
    for (final x in [28.0, 50.0, 72.0]) {
      d.shape(
          Path()
            ..moveTo(x, 66)
            ..quadraticBezierTo(x + 9, 82, x, 90)
            ..quadraticBezierTo(x - 9, 82, x, 66)
            ..close(),
          _blue);
    }
    d.blob([
      d.circlePath(30, 44, 18),
      d.circlePath(52, 34, 22),
      d.circlePath(72, 44, 16),
      d.rrectPath(14, 40, 74, 22, 11),
    ], _grey);
    d.face(50, 44, spread: 16, scale: 0.85);
  }

  void _shoe(_Pen d) {
    d.shape(
        Path()
          ..moveTo(10, 70)
          ..lineTo(14, 36)
          ..quadraticBezierTo(30, 30, 44, 40)
          ..quadraticBezierTo(60, 50, 80, 54)
          ..quadraticBezierTo(94, 58, 92, 72)
          ..close(),
        _red);
    d.rrect(6, 68, 90, 16, 8, _white);
    for (final x in [34.0, 44.0, 54.0]) {
      d.line(x - 3, 42 + (x - 34) * 0.4, x + 5, 50 + (x - 34) * 0.4, w: 2.6, color: _white);
    }
    d.eye(20, 52, r: 3);
    d.eye(30, 54, r: 3);
  }

  void _bird(_Pen d) {
    d.poly([_o(74, 46), _o(94, 54), _o(74, 62)], _orange);
    d.line(40, 82, 36, 96, w: 3, color: _orange);
    d.line(56, 82, 60, 96, w: 3, color: _orange);
    d.circle(46, 54, 32, _blue);
    d.shape(
        Path()
          ..moveTo(20, 56)
          ..quadraticBezierTo(34, 80, 50, 62)
          ..quadraticBezierTo(34, 56, 20, 56)
          ..close(),
        _sky);
    d.shape(
        Path()
          ..moveTo(40, 24)
          ..quadraticBezierTo(44, 8, 52, 22)
          ..close(),
        _blue);
    d.eye(58, 46, r: 4);
  }

  void _lamp(_Pen d) {
    d.oval(26, 84, 48, 12, _purple);
    d.rrect(46, 50, 8, 36, 3, _grey);
    d.poly([_o(30, 12), _o(70, 12), _o(86, 52), _o(14, 52)], _yellow);
    d.face(50, 32, spread: 16, scale: 0.85);
  }

  void _door(_Pen d) {
    d.rrect(22, 6, 56, 90, 8, _brown);
    d.rrect(30, 16, 40, 30, 4, const Color(0xFFD39A6A));
    d.rrect(30, 54, 40, 34, 4, const Color(0xFFD39A6A));
    d.circle(66, 52, 4.5, _yellow);
  }

  void _rice(_Pen d) {
    d.blob([
      d.circlePath(32, 48, 16),
      d.circlePath(50, 38, 20),
      d.circlePath(68, 48, 16),
    ], _white);
    d.shape(
        Path()
          ..moveTo(8, 50)
          ..lineTo(92, 50)
          ..quadraticBezierTo(90, 90, 50, 92)
          ..quadraticBezierTo(10, 90, 8, 50)
          ..close(),
        _red);
    d.line(10, 58, 90, 58, w: 2.4, color: _white);
    d.face(50, 70, spread: 16, scale: 0.85);
  }

  void _apple(_Pen d) {
    d.line(50, 26, 54, 8, w: 4);
    d.shape(
        Path()
          ..moveTo(54, 16)
          ..quadraticBezierTo(74, 2, 82, 16)
          ..quadraticBezierTo(66, 26, 54, 16)
          ..close(),
        _green);
    d.blob([d.circlePath(36, 56, 30), d.circlePath(64, 56, 30)], _red);
    d.face(50, 56, spread: 18);
  }

  void _house(_Pen d) {
    d.rrect(18, 44, 64, 50, 3, const Color(0xFFFFF1D6));
    d.poly([_o(8, 48), _o(50, 10), _o(92, 48)], _red);
    d.rrect(42, 64, 16, 30, 3, _brown);
    d.rrect(24, 56, 12, 12, 2, _sky);
    d.rrect(64, 56, 12, 12, 2, _sky);
  }

  void _snake(_Pen d) {
    final body = Path()
      ..moveTo(10, 84)
      ..cubicTo(40, 96, 70, 80, 44, 62)
      ..cubicTo(20, 46, 44, 26, 70, 32);
    d.stroke(body, w: 20);
    d.stroke(body, w: 13.6, color: _green);
    d.poly([_o(90, 30), _o(99, 26), _o(99, 34)], _red);
    d.circle(78, 30, 13, _green);
    d.eye(74, 26, r: 3);
    d.eye(84, 26, r: 3);
  }

  void _whale(_Pen d) {
    for (final dx in [-6.0, 0.0, 6.0]) {
      d.stroke(
          Path()
            ..moveTo(50 + dx * 0.3, 24)
            ..quadraticBezierTo(50 + dx, 14, 50 + dx * 2, 6),
          w: 2.6,
          color: _blue);
    }
    d.shape(
        Path()
          ..moveTo(84, 54)
          ..quadraticBezierTo(96, 30, 98, 38)
          ..quadraticBezierTo(92, 54, 98, 70)
          ..quadraticBezierTo(96, 76, 84, 60)
          ..close(),
        _blue);
    d.shape(
        Path()
          ..moveTo(6, 60)
          ..quadraticBezierTo(8, 26, 50, 26)
          ..quadraticBezierTo(86, 26, 88, 58)
          ..quadraticBezierTo(80, 84, 44, 84)
          ..quadraticBezierTo(8, 84, 6, 60)
          ..close(),
        _blue);
    d.shape(
        Path()
          ..moveTo(12, 66)
          ..quadraticBezierTo(46, 72, 82, 64)
          ..quadraticBezierTo(74, 82, 44, 82)
          ..quadraticBezierTo(18, 82, 12, 66)
          ..close(),
        _sky);
    d.eye(28, 50, r: 4);
    d.smile(40, 58, w: 10);
  }

  void _bread(_Pen d) {
    d.blob([d.ovalPath(10, 16, 80, 46), d.rrectPath(18, 36, 64, 56, 8)], _tan);
    d.blob([d.ovalPath(18, 24, 64, 36), d.rrectPath(24, 40, 52, 46, 6)], const Color(0xFFFFE9B8));
    d.face(50, 58, spread: 16);
  }

  void _mouse(_Pen d) {
    d.circle(24, 30, 18, _grey);
    d.circle(76, 30, 18, _grey);
    d.circle(24, 30, 10, _pink);
    d.circle(76, 30, 10, _pink);
    d.oval(18, 30, 64, 62, _grey);
    d.circle(50, 72, 5, _pink);
    d.eye(38, 58);
    d.eye(62, 58);
    for (final dy in [-3.0, 3.0]) {
      d.line(32, 74 + dy, 14, 72 + dy * 2, w: 2);
      d.line(68, 74 + dy, 86, 72 + dy * 2, w: 2);
    }
  }

  void _cloud(_Pen d) {
    d.blob([
      d.circlePath(28, 56, 20),
      d.circlePath(50, 42, 26),
      d.circlePath(74, 54, 20),
      d.rrectPath(10, 52, 82, 26, 13),
    ], _white);
    d.face(50, 58, spread: 18);
  }

  void _flower(_Pen d) {
    d.line(50, 56, 50, 96, w: 4.5, color: _darkGreen);
    d.shape(
        Path()
          ..moveTo(50, 84)
          ..quadraticBezierTo(70, 64, 84, 74)
          ..quadraticBezierTo(70, 90, 50, 84)
          ..close(),
        _green);
    for (var i = 0; i < 6; i++) {
      final a = i * pi / 3 - pi / 2;
      d.circle(50 + cos(a) * 22, 38 + sin(a) * 22, 15, _pink);
    }
    d.circle(50, 38, 18, _yellow);
    d.face(50, 36, spread: 12, scale: 0.75, cheeks: false);
  }

  void _banana(_Pen d) {
    d.shape(
        Path()
          ..moveTo(18, 18)
          ..cubicTo(8, 60, 40, 92, 90, 76)
          ..quadraticBezierTo(94, 82, 86, 86)
          ..cubicTo(34, 100, 0, 64, 10, 20)
          ..close(),
        _yellow);
    d.shape(
        Path()
          ..moveTo(18, 18)
          ..cubicTo(22, 52, 44, 72, 90, 76)
          ..cubicTo(40, 92, 8, 60, 18, 18)
          ..close(),
        const Color(0xFFFFE27A));
    d.rrect(12, 10, 8, 12, 3, _brown);
    d.eye(34, 64, r: 3.2);
    d.eye(46, 70, r: 3.2);
  }

  void _turtle(_Pen d) {
    d.oval(18, 66, 18, 22, _green);
    d.oval(60, 66, 18, 22, _green);
    d.circle(84, 58, 12, _green);
    d.shape(
        Path()
          ..moveTo(8, 70)
          ..quadraticBezierTo(10, 26, 48, 26)
          ..quadraticBezierTo(86, 26, 88, 70)
          ..close(),
        const Color(0xFF3FA86B));
    d.poly([_o(34, 44), _o(48, 36), _o(62, 44), _o(56, 60), _o(40, 60)], _green);
    d.line(8, 70, 88, 70, w: 3.2);
    d.eye(86, 55, r: 3);
  }

  void _elephant(_Pen d) {
    const skin = Color(0xFF9FB3D1);
    d.oval(2, 24, 36, 50, skin);
    d.oval(62, 24, 36, 50, skin);
    d.oval(4 + 6, 32, 22, 34, _pink);
    d.oval(68, 32, 22, 34, _pink);
    final trunk = Path()
      ..moveTo(50, 60)
      ..cubicTo(50, 80, 52, 90, 66, 92);
    d.stroke(trunk, w: 18);
    d.stroke(trunk, w: 11.6, color: skin);
    d.circle(50, 48, 28, skin);
    d.eye(40, 44);
    d.eye(60, 44);
  }
}

// ─── Interface icons ──────────────────────────────────────────────────────────

class _IconPainter extends CustomPainter {
  final ReaderIcon icon;
  const _IconPainter(this.icon);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final d = _Pen(canvas);
    switch (icon) {
      case ReaderIcon.chest: _chest(d, open: false);
      case ReaderIcon.chestOpen: _chest(d, open: true);
      case ReaderIcon.stickerBook: _stickerBook(d);
      case ReaderIcon.flame: _flame(d);
      case ReaderIcon.brokenHeart: _brokenHeart(d);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) => old.icon != icon;

  static const _wood = Color(0xFFC0773F);
  static const _gold = Color(0xFFFFC93C);

  void _chest(_Pen d, {required bool open}) {
    if (open) {
      // Light spilling out of the chest.
      d.c.drawPath(
          Path()
            ..moveTo(20, 50)
            ..lineTo(4, 0)
            ..lineTo(96, 0)
            ..lineTo(80, 50)
            ..close(),
          Paint()..color = const Color(0x66FFE27A));
      d.shape(
          Path()
            ..moveTo(12, 44)
            ..lineTo(18, 14)
            ..quadraticBezierTo(50, 2, 82, 14)
            ..lineTo(88, 44)
            ..close(),
          _wood);
    } else {
      d.shape(
          Path()
            ..moveTo(8, 48)
            ..lineTo(8, 36)
            ..quadraticBezierTo(50, 4, 92, 36)
            ..lineTo(92, 48)
            ..close(),
          _wood);
      d.rrect(44, 16, 12, 34, 2, _gold);
    }
    d.rrect(8, 46, 84, 44, 6, _wood);
    d.rrect(14, 46, 10, 44, 2, _gold);
    d.rrect(76, 46, 10, 44, 2, _gold);
    d.rrect(40, 46, 20, 22, 4, _gold);
    d.circle(50, 56, 3.5, _ink);
  }

  void _stickerBook(_Pen d) {
    d.rrect(14, 8, 72, 86, 8, const Color(0xFF7C5CFF));
    d.rrect(14, 8, 14, 86, 4, const Color(0xFF5A3FD6));
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 22.0 : 10.0;
      final a = -pi / 2 + i * pi / 5;
      final pt = Offset(57 + cos(a) * r, 50 + sin(a) * r);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    d.shape(p..close(), _gold);
  }

  void _flame(_Pen d) {
    d.shape(
        Path()
          ..moveTo(50, 4)
          ..cubicTo(62, 26, 90, 40, 86, 66)
          ..cubicTo(82, 90, 64, 96, 50, 96)
          ..cubicTo(34, 96, 14, 88, 14, 64)
          ..cubicTo(14, 46, 30, 42, 30, 26)
          ..cubicTo(40, 34, 42, 44, 42, 50)
          ..cubicTo(50, 40, 54, 22, 50, 4)
          ..close(),
        const Color(0xFFFF6B35));
    d.shape(
        Path()
          ..moveTo(50, 50)
          ..cubicTo(62, 62, 70, 72, 66, 82)
          ..cubicTo(62, 92, 38, 92, 34, 80)
          ..cubicTo(32, 70, 42, 64, 50, 50)
          ..close(),
        _gold);
  }

  void _brokenHeart(_Pen d) {
    Path half(bool left) {
      final p = Path()
        ..moveTo(50, 28)
        ..cubicTo(left ? 36 : 64, 4, left ? 2 : 98, 12, left ? 6 : 94, 42)
        ..cubicTo(left ? 10 : 90, 64, left ? 34 : 66, 80, 50, 94);
      if (left) {
        p
          ..lineTo(44, 74)
          ..lineTo(56, 58)
          ..lineTo(44, 42)
          ..close();
      } else {
        p
          ..lineTo(56, 74)
          ..lineTo(44, 58)
          ..lineTo(56, 42)
          ..close();
      }
      return p;
    }

    const heart = Color(0xFFFF4D6D);
    d.c.save();
    d.c.translate(-5, 3);
    d.c.rotate(-0.06);
    d.shape(half(true), heart);
    d.c.restore();
    d.c.save();
    d.c.translate(5, 3);
    d.c.rotate(0.06);
    d.shape(half(false), heart);
    d.c.restore();
  }
}
