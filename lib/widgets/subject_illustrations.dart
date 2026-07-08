import 'package:flutter/material.dart';
import 'animal_illustrations.dart';

// ── Procedural: exact color match (for "what colour is...") ──────────────────

class _NamedColor {
  final Color color;
  final String hex;
  const _NamedColor(this.color, this.hex);
}

const Map<String, _NamedColor> _colorWords = {
  'red': _NamedColor(Color(0xFFE85B5B), '#E85B5B'),
  'blue': _NamedColor(Color(0xFF5B8CE8), '#5B8CE8'),
  'green': _NamedColor(Color(0xFF6BBF6F), '#6BBF6F'),
  'yellow': _NamedColor(Color(0xFFF4C962), '#F4C962'),
  'purple': _NamedColor(Color(0xFF9B5BE8), '#9B5BE8'),
  'orange': _NamedColor(Color(0xFFE8784A), '#E8784A'),
  'pink': _NamedColor(Color(0xFFE85B9B), '#E85B9B'),
  'brown': _NamedColor(Color(0xFFA87555), '#A87555'),
  'white': _NamedColor(Color(0xFFF5F5F5), '#F5F5F5'),
  'black': _NamedColor(Color(0xFF2C2C2C), '#2C2C2C'),
  'merah': _NamedColor(Color(0xFFE85B5B), '#E85B5B'),
  'biru': _NamedColor(Color(0xFF5B8CE8), '#5B8CE8'),
  'hijau': _NamedColor(Color(0xFF6BBF6F), '#6BBF6F'),
  'kuning': _NamedColor(Color(0xFFF4C962), '#F4C962'),
  'ungu': _NamedColor(Color(0xFF9B5BE8), '#9B5BE8'),
  'jingga': _NamedColor(Color(0xFFE8784A), '#E8784A'),
  'perang': _NamedColor(Color(0xFFA87555), '#A87555'),
  'putih': _NamedColor(Color(0xFFF5F5F5), '#F5F5F5'),
  'hitam': _NamedColor(Color(0xFF2C2C2C), '#2C2C2C'),
};

String _colorBlobSvg(String hex) {
  return '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
    <path d="M60 14 Q92 18 97 50 Q102 80 76 96 Q50 110 28 90 Q8 71 18 44 Q27 16 60 14 Z" fill="$hex"/>
    <circle cx="44" cy="38" r="9" fill="#FFFFFF" opacity="0.25"/>
  </svg>''';
}

// ── Procedural: geometric shapes (for "what shape is...") ────────────────────

const _shapeColor = Color(0xFF7B6EC8);

String _shapeSvg(String shape) {
  switch (shape) {
    case 'circle':
      return '<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg"><circle cx="60" cy="60" r="42" fill="#7B6EC8"/></svg>';
    case 'square':
      return '<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg"><rect x="22" y="22" width="76" height="76" rx="10" fill="#7B6EC8"/></svg>';
    case 'triangle':
      return '<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg"><path d="M60 16 L104 98 L16 98 Z" fill="#7B6EC8"/></svg>';
    default: // rectangle
      return '<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg"><rect x="12" y="32" width="96" height="56" rx="10" fill="#7B6EC8"/></svg>';
  }
}

// ── Space ──────────────────────────────────────────────────────────────────

const _earthSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <circle cx="60" cy="60" r="42" fill="#5BA8E8"/>
  <path d="M30 45 Q45 40 55 48 Q60 55 50 60 Q35 62 30 45" fill="#6BBF6F"/>
  <path d="M70 70 Q85 68 88 80 Q80 90 68 85 Q62 78 70 70" fill="#6BBF6F"/>
  <ellipse cx="50" cy="48" rx="22" ry="8" fill="#FFFFFF" opacity="0.18" transform="rotate(-15 50 48)"/>
</svg>''';

const _marsSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <circle cx="60" cy="60" r="42" fill="#E8674A"/>
  <circle cx="45" cy="48" r="6" fill="#C44F35" opacity="0.6"/>
  <circle cx="72" cy="65" r="9" fill="#C44F35" opacity="0.6"/>
  <circle cx="55" cy="78" r="5" fill="#C44F35" opacity="0.5"/>
</svg>''';

const _saturnSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="60" cy="64" rx="52" ry="13" fill="#E8C078" opacity="0.85"/>
  <circle cx="60" cy="60" r="32" fill="#F4D9A0"/>
  <ellipse cx="60" cy="64" rx="52" ry="13" fill="none" stroke="#D4A85E" stroke-width="3" opacity="0.6"/>
</svg>''';

const _jupiterSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <circle cx="60" cy="60" r="42" fill="#E8A85B"/>
  <ellipse cx="60" cy="48" rx="40" ry="6" fill="#D4985B" opacity="0.7"/>
  <ellipse cx="60" cy="68" rx="38" ry="5" fill="#D4985B" opacity="0.6"/>
  <ellipse cx="76" cy="58" rx="9" ry="6" fill="#C4784A"/>
</svg>''';

const _rocketSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M60 14 Q76 36 75 70 L45 70 Q44 36 60 14 Z" fill="#E8784A"/>
  <circle cx="60" cy="45" r="8" fill="#B8D4F5"/>
  <path d="M45 70 L28 92 L45 83 Z" fill="#5B8CE8"/>
  <path d="M75 70 L92 92 L75 83 Z" fill="#5B8CE8"/>
  <path d="M50 70 L70 70 L65 96 L55 96 Z" fill="#D8D8D8"/>
  <path d="M52 96 L68 96 L60 110 Z" fill="#F4A742"/>
</svg>''';

const _moonStarsSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M75 22 Q98 34 98 60 Q98 90 70 98 Q92 80 86 54 Q80 32 58 26 Q66 22 75 22 Z" fill="#D4C9A0"/>
  <circle cx="28" cy="36" r="3" fill="#F4D9A0"/>
  <circle cx="44" cy="20" r="2" fill="#F4D9A0"/>
  <circle cx="22" cy="62" r="2.5" fill="#F4D9A0"/>
</svg>''';

const _sunSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <circle cx="60" cy="60" r="28" fill="#F4C962"/>
  <g stroke="#F4C962" stroke-width="6" stroke-linecap="round">
    <line x1="60" y1="14" x2="60" y2="4"/>
    <line x1="60" y1="106" x2="60" y2="116"/>
    <line x1="14" y1="60" x2="4" y2="60"/>
    <line x1="106" y1="60" x2="116" y2="60"/>
    <line x1="26" y1="26" x2="19" y2="19"/>
    <line x1="94" y1="94" x2="101" y2="101"/>
    <line x1="94" y1="26" x2="101" y2="19"/>
    <line x1="26" y1="94" x2="19" y2="101"/>
  </g>
</svg>''';

const _astronautSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <circle cx="60" cy="55" r="38" fill="#E8E8E8"/>
  <circle cx="60" cy="55" r="26" fill="#5B8CE8"/>
  <ellipse cx="50" cy="48" rx="8" ry="10" fill="#FFFFFF" opacity="0.4"/>
  <rect x="38" y="88" width="44" height="14" rx="7" fill="#E8E8E8"/>
</svg>''';

// ── Human body ─────────────────────────────────────────────────────────────

const _boneSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M30 45 Q22 38 28 30 Q36 22 44 30 Q48 35 55 42 L78 65 Q85 72 90 76 Q98 82 92 90 Q84 98 76 92 Q72 88 65 80 L42 57 Q35 50 30 45 Z" fill="#F5F0E8"/>
  <circle cx="32" cy="38" r="9" fill="#F5F0E8"/>
  <circle cx="38" cy="32" r="9" fill="#F5F0E8"/>
  <circle cx="88" cy="82" r="9" fill="#F5F0E8"/>
  <circle cx="82" cy="88" r="9" fill="#F5F0E8"/>
</svg>''';

const _lungsSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M58 22 L58 55 Q40 50 32 65 Q24 82 35 95 Q46 105 55 92 L58 70 Z" fill="#E85B9B"/>
  <path d="M62 22 L62 55 Q80 50 88 65 Q96 82 85 95 Q74 105 65 92 L62 70 Z" fill="#F48BB8"/>
  <rect x="57" y="12" width="6" height="20" rx="3" fill="#C44F7A"/>
</svg>''';

const _bloodDropSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M60 16 Q86 50 86 72 Q86 99 60 99 Q34 99 34 72 Q34 50 60 16 Z" fill="#E85B5B"/>
  <ellipse cx="50" cy="70" rx="8" ry="12" fill="#FFFFFF" opacity="0.25"/>
</svg>''';

const _toothSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M40 24 Q60 14 80 24 Q92 31 90 49 Q88 70 82 88 Q78 100 70 95 Q66 88 64 75 Q62 65 60 65 Q58 65 56 75 Q54 88 50 95 Q42 100 38 88 Q32 70 30 49 Q28 31 40 24 Z" fill="#FFFFFF"/>
  <ellipse cx="48" cy="40" rx="6" ry="8" fill="#F0F0F0"/>
</svg>''';

const _brainSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M45 28 Q30 28 28 47 Q18 49 20 64 Q15 75 25 85 Q28 98 45 95 Q55 100 60 92 L60 33 Q55 26 45 28 Z" fill="#E85B9B"/>
  <path d="M75 28 Q90 28 92 47 Q102 49 100 64 Q105 75 95 85 Q92 98 75 95 Q65 100 60 92 L60 33 Q65 26 75 28 Z" fill="#F48BB8"/>
</svg>''';

// ── Food ───────────────────────────────────────────────────────────────────

const _appleSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M60 36 Q40 30 32 50 Q25 70 38 88 Q48 100 60 95 Q72 100 82 88 Q95 70 88 50 Q80 30 60 36 Z" fill="#E85B5B"/>
  <path d="M58 36 Q55 22 48 17 Q53 28 56 37" fill="#6BBF6F"/>
  <ellipse cx="48" cy="55" rx="8" ry="14" fill="#FFFFFF" opacity="0.2"/>
</svg>''';

const _citrusSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <circle cx="60" cy="65" r="40" fill="#F4C962"/>
  <path d="M60 25 Q66 17 73 21 Q68 28 61 30" fill="#6BBF6F"/>
  <circle cx="60" cy="65" r="27" fill="#F8E08A" opacity="0.5"/>
</svg>''';

const _orangeFruitSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <circle cx="60" cy="65" r="40" fill="#E8944A"/>
  <path d="M60 25 Q66 17 73 21 Q68 28 61 30" fill="#6BBF6F"/>
  <circle cx="60" cy="65" r="27" fill="#F4B36B" opacity="0.5"/>
</svg>''';

const _carrotSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M55 30 L76 36 Q86 70 60 106 Q35 95 41 55 Z" fill="#F4944A"/>
  <path d="M55 30 Q45 14 35 17 Q42 25 48 32" fill="#6BBF6F"/>
  <path d="M76 36 Q86 22 80 11 Q72 22 68 32" fill="#6BBF6F"/>
  <path d="M65 32 Q60 17 55 19 Q58 28 60 35" fill="#6BBF6F"/>
</svg>''';

const _milkSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M35 35 L85 35 L85 96 Q85 101 80 101 L40 101 Q35 101 35 96 Z" fill="#FFFFFF"/>
  <path d="M35 35 L60 16 L85 35 Z" fill="#5BA8E8"/>
  <rect x="35" y="56" width="50" height="14" fill="#5BA8E8" opacity="0.8"/>
</svg>''';

const _coconutSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <circle cx="60" cy="62" r="40" fill="#8B6F4F"/>
  <circle cx="60" cy="62" r="40" fill="#A0826A" opacity="0.4"/>
  <circle cx="50" cy="48" r="4" fill="#5B4332"/>
  <circle cx="68" cy="50" r="4" fill="#5B4332"/>
  <circle cx="58" cy="60" r="4" fill="#5B4332"/>
</svg>''';

// ── Music ──────────────────────────────────────────────────────────────────

const _guitarSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M50 14 L70 14 L68 48 L52 48 Z" fill="#8B6F4F"/>
  <path d="M40 53 Q30 68 38 87 Q45 102 60 99 Q75 102 82 87 Q90 68 80 53 Q70 43 60 46 Q50 43 40 53 Z" fill="#E8A85B"/>
  <circle cx="60" cy="74" r="14" fill="#5B4332"/>
  <line x1="60" y1="16" x2="60" y2="95" stroke="#2C2C2C" stroke-width="1.5" opacity="0.35"/>
</svg>''';

const _pianoSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <rect x="15" y="38" width="90" height="50" rx="4" fill="#2C2C2C"/>
  <rect x="20" y="43" width="80" height="40" fill="#FFFFFF"/>
  <line x1="36" y1="43" x2="36" y2="83" stroke="#2C2C2C" stroke-width="1.5"/>
  <line x1="52" y1="43" x2="52" y2="83" stroke="#2C2C2C" stroke-width="1.5"/>
  <line x1="68" y1="43" x2="68" y2="83" stroke="#2C2C2C" stroke-width="1.5"/>
  <line x1="84" y1="43" x2="84" y2="83" stroke="#2C2C2C" stroke-width="1.5"/>
  <rect x="30" y="43" width="8" height="24" fill="#2C2C2C"/>
  <rect x="62" y="43" width="8" height="24" fill="#2C2C2C"/>
  <rect x="78" y="43" width="8" height="24" fill="#2C2C2C"/>
</svg>''';

const _harpSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M40 18 Q76 24 80 70 L80 101 L70 101 L68 72 Q65 33 38 28 Z" fill="#E8A85B"/>
  <line x1="45" y1="34" x2="68" y2="96" stroke="#FFFFFF" stroke-width="1.5" opacity="0.7"/>
  <line x1="50" y1="31" x2="70" y2="91" stroke="#FFFFFF" stroke-width="1.5" opacity="0.7"/>
  <line x1="55" y1="29" x2="72" y2="86" stroke="#FFFFFF" stroke-width="1.5" opacity="0.7"/>
  <line x1="60" y1="27" x2="74" y2="81" stroke="#FFFFFF" stroke-width="1.5" opacity="0.7"/>
</svg>''';

const _drumSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M22 40 L26 80 Q26 93 60 93 Q94 93 94 80 L98 40" fill="#E85B5B"/>
  <ellipse cx="60" cy="40" rx="38" ry="14" fill="#FFFFFF"/>
  <ellipse cx="60" cy="40" rx="38" ry="14" fill="none" stroke="#E8E8E8" stroke-width="2"/>
</svg>''';

// ── Arts ───────────────────────────────────────────────────────────────────

const _sculptureSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M45 28 L75 28 L78 50 Q85 70 75 90 Q65 101 60 101 Q55 101 45 90 Q35 70 42 50 Z" fill="#C49B7A"/>
  <ellipse cx="60" cy="28" rx="16" ry="6" fill="#A87E5E"/>
</svg>''';

const _mosaicSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <rect x="18" y="18" width="38" height="38" fill="#E85B5B"/>
  <rect x="62" y="18" width="38" height="38" fill="#5BA8E8"/>
  <rect x="18" y="62" width="38" height="38" fill="#F4C962"/>
  <rect x="62" y="62" width="38" height="38" fill="#6BBF6F"/>
</svg>''';

const _paintingSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <rect x="18" y="18" width="84" height="84" rx="4" fill="#8B6F4F"/>
  <rect x="27" y="27" width="66" height="66" fill="#F5F0E8"/>
  <circle cx="48" cy="48" r="10" fill="#F4C962"/>
  <path d="M27 82 L48 60 L64 73 L93 48 L93 93 L27 93 Z" fill="#6BBF6F"/>
</svg>''';

const _origamiSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M60 18 L97 70 L60 101 L23 70 Z" fill="#5BA8E8"/>
  <path d="M60 18 L60 101 L23 70 Z" fill="#7BC0F0"/>
  <path d="M60 18 L97 70 L60 101 Z" fill="#3A88C8"/>
</svg>''';

// ── Weather ────────────────────────────────────────────────────────────────

const _sunCloudSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <circle cx="60" cy="45" r="24" fill="#F4C962"/>
  <line x1="60" y1="12" x2="60" y2="4" stroke="#F4C962" stroke-width="5" stroke-linecap="round"/>
  <line x1="60" y1="86" x2="60" y2="78" stroke="#F4C962" stroke-width="5" stroke-linecap="round"/>
  <line x1="27" y1="45" x2="19" y2="45" stroke="#F4C962" stroke-width="5" stroke-linecap="round"/>
  <line x1="101" y1="45" x2="93" y2="45" stroke="#F4C962" stroke-width="5" stroke-linecap="round"/>
  <ellipse cx="55" cy="82" rx="28" ry="18" fill="#B8D4F5"/>
  <ellipse cx="72" cy="86" rx="22" ry="16" fill="#D0E8FF"/>
  <ellipse cx="40" cy="88" rx="18" ry="14" fill="#D0E8FF"/>
</svg>''';

const _thermometerSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <rect x="52" y="13" width="16" height="65" rx="8" fill="#E8E8E8"/>
  <circle cx="60" cy="90" r="18" fill="#E85B5B"/>
  <rect x="56" y="28" width="8" height="55" rx="4" fill="#E85B5B"/>
</svg>''';

const _lightningSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M65 13 L35 65 L55 65 L48 107 L88 50 L65 50 Z" fill="#F4C962"/>
</svg>''';

const _snowflakeSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <g stroke="#9BD4F0" stroke-width="5" stroke-linecap="round">
    <line x1="60" y1="20" x2="60" y2="100"/>
    <line x1="20" y1="60" x2="100" y2="60"/>
    <line x1="34" y1="34" x2="86" y2="86"/>
    <line x1="86" y1="34" x2="34" y2="86"/>
  </g>
  <circle cx="60" cy="60" r="8" fill="#9BD4F0"/>
</svg>''';

// ── Language ───────────────────────────────────────────────────────────────

const _alphabetBlocksSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <rect x="38" y="14" width="32" height="32" rx="6" fill="#F4C962"/>
  <rect x="18" y="50" width="32" height="32" rx="6" fill="#E85B5B"/>
  <rect x="58" y="50" width="32" height="32" rx="6" fill="#5BA8E8"/>
</svg>''';

const _speechBubbleSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M20 30 Q20 20 30 20 L90 20 Q100 20 100 30 L100 63 Q100 73 90 73 L50 73 L35 93 L38 73 L30 73 Q20 73 20 63 Z" fill="#7B6EC8"/>
  <circle cx="42" cy="46" r="5" fill="#FFFFFF"/>
  <circle cx="60" cy="46" r="5" fill="#FFFFFF"/>
  <circle cx="78" cy="46" r="5" fill="#FFFFFF"/>
</svg>''';

// ── Master resolver ────────────────────────────────────────────────────────

/// Tries to match the question against non-animal subject topics (colors, shapes,
/// space, body, food, music, arts, weather, language). Returns null if nothing matches,
/// so the caller can fall back to animal illustrations.
AnimalData? subjectIllustrationFor(String question) {
  final t = question.toLowerCase();

  // Exact color name match — render that precise color
  for (final entry in _colorWords.entries) {
    if (t.contains(entry.key)) return AnimalData(_colorBlobSvg(entry.value.hex), entry.value.color);
  }

  // Shapes
  if (t.contains('circle') || t.contains('bulat') || t.contains('round') || t.contains('pizza') || t.contains('ball')) {
    return AnimalData(_shapeSvg('circle'), _shapeColor);
  }
  if (t.contains('square') || t.contains('segi empat') && !t.contains('tepat')) {
    return AnimalData(_shapeSvg('square'), _shapeColor);
  }
  if (t.contains('triangle') || t.contains('segi tiga') || t.contains('tiga segi')) {
    return AnimalData(_shapeSvg('triangle'), _shapeColor);
  }
  if (t.contains('rectangle') || t.contains('segiempat tepat')) {
    return AnimalData(_shapeSvg('rectangle'), _shapeColor);
  }

  // Space
  if (t.contains('saturn') || t.contains('zuhal') || t.contains('ring')) return const AnimalData(_saturnSvg, Color(0xFFE8C078));
  if (t.contains('jupiter') || t.contains('musytari')) return const AnimalData(_jupiterSvg, Color(0xFFE8A85B));
  if (t.contains('mars') || t.contains('marikh') || t.contains('red planet')) return const AnimalData(_marsSvg, Color(0xFFE8674A));
  if (t.contains('earth') || t.contains('bumi') || t.contains('orbit')) return const AnimalData(_earthSvg, Color(0xFF5BA8E8));
  if (t.contains('rocket') || t.contains('roket')) return const AnimalData(_rocketSvg, Color(0xFFE8784A));
  if (t.contains('astronaut') || t.contains('angkasawan') || t.contains('space suit')) return const AnimalData(_astronautSvg, Color(0xFF5B8CE8));
  if (t.contains('sun') || t.contains('matahari') || t.contains('star') || t.contains('bintang')) return const AnimalData(_sunSvg, Color(0xFFF4C962));
  if (t.contains('moon') || t.contains('bulan') || t.contains('satellite') || t.contains('meteor')) return const AnimalData(_moonStarsSvg, Color(0xFFD4C9A0));
  if (t.contains('planet') || t.contains('solar') || t.contains('venus') || t.contains('mercury') || t.contains('zuhrah') || t.contains('utarid')) {
    return const AnimalData(_earthSvg, Color(0xFF5BA8E8));
  }

  // Human body
  if (t.contains('bone') || t.contains('tulang') || t.contains('skeleton')) return const AnimalData(_boneSvg, Color(0xFFF5F0E8));
  if (t.contains('lung') || t.contains('paru-paru') || t.contains('breathe') || t.contains('bernafas')) return const AnimalData(_lungsSvg, Color(0xFFE85B9B));
  if (t.contains('blood') || t.contains('darah') || t.contains('oxygen') || t.contains('oksigen')) return const AnimalData(_bloodDropSvg, Color(0xFFE85B5B));
  if (t.contains('teeth') || t.contains('tooth') || t.contains('gigi')) return const AnimalData(_toothSvg, Color(0xFFFFFFFF));
  if (t.contains('brain') || t.contains('otak')) return const AnimalData(_brainSvg, Color(0xFFE85B9B));

  // Food
  if (t.contains('carrot') || t.contains('lobak')) return const AnimalData(_carrotSvg, Color(0xFFF4944A));
  if (t.contains('milk') || t.contains('susu') || t.contains('cow') || t.contains('lembu')) return const AnimalData(_milkSvg, Color(0xFF5BA8E8));
  if (t.contains('coconut') || t.contains('kelapa')) return const AnimalData(_coconutSvg, Color(0xFF8B6F4F));
  if (t.contains('mango') || t.contains('mangga')) return const AnimalData(_orangeFruitSvg, Color(0xFFE8944A));
  if (t.contains('lemon') || t.contains('orange') || t.contains('oren')) return const AnimalData(_citrusSvg, Color(0xFFF4C962));
  if (t.contains('apple') || t.contains('epal') || t.contains('fruit') || t.contains('buah')) return const AnimalData(_appleSvg, Color(0xFFE85B5B));

  // Music
  if (t.contains('guitar') || t.contains('gitar')) return const AnimalData(_guitarSvg, Color(0xFFE8A85B));
  if (t.contains('piano') || t.contains('keys')) return const AnimalData(_pianoSvg, Color(0xFF2C2C2C));
  if (t.contains('harp') || t.contains('harpa') || t.contains('pluck')) return const AnimalData(_harpSvg, Color(0xFFE8A85B));
  if (t.contains('drum') || t.contains('dram')) return const AnimalData(_drumSvg, Color(0xFFE85B5B));
  if (t.contains('music') || t.contains('muzik') || t.contains('song') || t.contains('lagu') || t.contains('tempo') || t.contains('band') || t.contains('musician')) {
    return const AnimalData(_guitarSvg, Color(0xFFE8A85B));
  }

  // Arts
  if (t.contains('sculpture') || t.contains('clay') || t.contains('arca') || t.contains('tanah liat')) return const AnimalData(_sculptureSvg, Color(0xFFC49B7A));
  if (t.contains('mosaic') || t.contains('mozek') || t.contains('tile')) return const AnimalData(_mosaicSvg, Color(0xFFE85B5B));
  if (t.contains('mona lisa') || t.contains('painting') || t.contains('lukisan')) return const AnimalData(_paintingSvg, Color(0xFF8B6F4F));
  if (t.contains('origami')) return const AnimalData(_origamiSvg, Color(0xFF5BA8E8));
  if (t.contains('primary colour') || t.contains('warna asas') || t.contains('art') || t.contains('seni') || t.contains('craft') || t.contains('kraf')) {
    return const AnimalData(_paintingSvg, Color(0xFF8B6F4F));
  }

  // Weather
  if (t.contains('thermometer') || t.contains('termometer') || t.contains('temperature') || t.contains('suhu') || t.contains('freeze') || t.contains('membeku')) {
    return const AnimalData(_thermometerSvg, Color(0xFFE85B5B));
  }
  if (t.contains('lightning') || t.contains('kilat') || t.contains('thunder')) return const AnimalData(_lightningSvg, Color(0xFFF4C962));
  if (t.contains('winter') || t.contains('cold') || t.contains('snow') || t.contains('sejuk')) return const AnimalData(_snowflakeSvg, Color(0xFF9BD4F0));
  if (t.contains('weather') || t.contains('cuaca') || t.contains('cloud') || t.contains('awan') || t.contains('atmosphere') || t.contains('season') || t.contains('musim') || t.contains('rain') || t.contains('hujan')) {
    return const AnimalData(_sunCloudSvg, Color(0xFFF4C962));
  }

  // Language
  if (t.contains('pronoun') || t.contains('ganti nama') || t.contains('sentence') || t.contains('ayat') || t.contains('correct')) {
    return const AnimalData(_speechBubbleSvg, Color(0xFF7B6EC8));
  }
  if (t.contains('adjective') || t.contains('adjektif') || t.contains('word') || t.contains('kata') || t.contains('grammar') ||
      t.contains('opposite') || t.contains('antonim') || t.contains('past tense') || t.contains('maksud') || t.contains('terima kasih') ||
      t.contains('bahasa') || t.contains('letter') || t.contains('huruf')) {
    return const AnimalData(_alphabetBlocksSvg, Color(0xFFF4C962));
  }

  return null;
}
