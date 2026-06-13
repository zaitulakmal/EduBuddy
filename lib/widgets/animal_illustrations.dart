import 'package:flutter/material.dart';

class AnimalData {
  final String svg;
  final Color color;
  const AnimalData(this.svg, this.color);
}

// ── SVG strings (ported from Figma Make AnimalIllustrations.tsx) ──────────────

const _lion = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <circle cx="60" cy="60" r="45" fill="#E8A85B"/>
  <ellipse cx="60" cy="65" rx="30" ry="32" fill="#F4C962"/>
  <circle cx="40" cy="45" r="8" fill="#D4985B"/>
  <circle cx="80" cy="45" r="8" fill="#D4985B"/>
  <circle cx="50" cy="60" r="4" fill="#2C2C2C"/>
  <circle cx="70" cy="60" r="4" fill="#2C2C2C"/>
  <ellipse cx="60" cy="72" rx="5" ry="4" fill="#2C2C2C"/>
  <circle cx="42" cy="70" r="6" fill="#E89B5B" opacity="0.5"/>
  <circle cx="78" cy="70" r="6" fill="#E89B5B" opacity="0.5"/>
  <path d="M 60 72 Q 55 76 50 74" stroke="#2C2C2C" stroke-width="2" fill="none"/>
  <path d="M 60 72 Q 65 76 70 74" stroke="#2C2C2C" stroke-width="2" fill="none"/>
</svg>''';

const _elephant = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="65" cy="65" rx="35" ry="30" fill="#7DBEDB"/>
  <circle cx="50" cy="50" r="25" fill="#7DBEDB"/>
  <ellipse cx="30" cy="50" rx="18" ry="25" fill="#6AADC9"/>
  <path d="M 45 60 Q 35 75 30 85 Q 28 88 32 90" stroke="#7DBEDB" stroke-width="12" fill="none" stroke-linecap="round"/>
  <circle cx="50" cy="45" r="3" fill="#2C2C2C"/>
  <ellipse cx="38" cy="65" rx="3" ry="8" fill="#F5F5F5"/>
  <rect x="45" y="80" width="8" height="15" rx="4" fill="#6AADC9"/>
  <rect x="62" y="80" width="8" height="15" rx="4" fill="#6AADC9"/>
</svg>''';

const _eagle = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="40" cy="65" rx="25" ry="18" fill="#8B6F4F" transform="rotate(-20 40 65)"/>
  <ellipse cx="60" cy="60" rx="18" ry="25" fill="#6F5439"/>
  <circle cx="60" cy="40" r="16" fill="#FFFFFF"/>
  <path d="M 65 40 L 75 38 L 68 42 Z" fill="#F4C962"/>
  <circle cx="62" cy="38" r="3" fill="#2C2C2C"/>
  <ellipse cx="80" cy="65" rx="25" ry="18" fill="#8B6F4F" transform="rotate(20 80 65)"/>
  <ellipse cx="60" cy="85" rx="12" ry="8" fill="#6F5439"/>
</svg>''';

const _dolphin = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="60" cy="60" rx="35" ry="20" fill="#5BBFE8"/>
  <ellipse cx="38" cy="55" rx="18" ry="16" fill="#5BBFE8"/>
  <path d="M 60 45 Q 62 35 58 40 Z" fill="#4AADE0"/>
  <ellipse cx="25" cy="55" rx="8" ry="6" fill="#5BBFE8"/>
  <circle cx="40" cy="52" r="3" fill="#2C2C2C"/>
  <ellipse cx="60" cy="65" rx="25" ry="12" fill="#A8D8F0"/>
  <path d="M 85 58 Q 95 50 92 58 Q 95 66 85 62 Z" fill="#4AADE0"/>
  <path d="M 28 57 Q 32 60 36 57" stroke="#2C2C2C" stroke-width="1.5" fill="none"/>
</svg>''';

const _giraffe = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="60" cy="75" rx="25" ry="18" fill="#F4C962"/>
  <rect x="52" y="35" width="16" height="42" rx="8" fill="#F4C962"/>
  <ellipse cx="60" cy="30" rx="14" ry="16" fill="#F4C962"/>
  <circle cx="55" cy="70" r="4" fill="#C49B3D"/>
  <circle cx="68" cy="75" r="4" fill="#C49B3D"/>
  <circle cx="58" cy="50" r="4" fill="#C49B3D"/>
  <circle cx="62" cy="60" r="3" fill="#C49B3D"/>
  <ellipse cx="52" cy="25" rx="4" ry="6" fill="#C49B3D"/>
  <ellipse cx="68" cy="25" rx="4" ry="6" fill="#C49B3D"/>
  <circle cx="52" cy="22" r="3" fill="#8B6F4F"/>
  <circle cx="68" cy="22" r="3" fill="#8B6F4F"/>
  <circle cx="56" cy="30" r="2" fill="#2C2C2C"/>
  <circle cx="64" cy="30" r="2" fill="#2C2C2C"/>
  <ellipse cx="60" cy="36" rx="6" ry="5" fill="#E8B84D"/>
  <rect x="48" y="85" width="6" height="20" rx="3" fill="#C49B3D"/>
  <rect x="66" y="85" width="6" height="20" rx="3" fill="#C49B3D"/>
</svg>''';

const _frog = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="60" cy="65" rx="30" ry="25" fill="#6BBF6F"/>
  <ellipse cx="60" cy="50" rx="28" ry="22" fill="#6BBF6F"/>
  <circle cx="48" cy="45" r="10" fill="#8BDF8F"/>
  <circle cx="72" cy="45" r="10" fill="#8BDF8F"/>
  <circle cx="48" cy="45" r="5" fill="#2C2C2C"/>
  <circle cx="72" cy="45" r="5" fill="#2C2C2C"/>
  <ellipse cx="60" cy="70" rx="20" ry="18" fill="#9FD9A3"/>
  <path d="M 50 58 Q 60 62 70 58" stroke="#2C2C2C" stroke-width="2" fill="none"/>
  <ellipse cx="38" cy="75" rx="8" ry="12" fill="#5AAF5F"/>
  <ellipse cx="82" cy="75" rx="8" ry="12" fill="#5AAF5F"/>
  <ellipse cx="35" cy="80" rx="12" ry="8" fill="#5AAF5F" transform="rotate(-30 35 80)"/>
  <ellipse cx="85" cy="80" rx="12" ry="8" fill="#5AAF5F" transform="rotate(30 85 80)"/>
</svg>''';

const _shark = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="60" cy="60" rx="40" ry="18" fill="#5B8CE8"/>
  <ellipse cx="35" cy="58" rx="20" ry="16" fill="#5B8CE8"/>
  <path d="M 55 45 L 60 30 L 65 45 Z" fill="#4A7BD6"/>
  <path d="M 90 55 L 105 45 L 98 60 L 105 65 L 90 65 Z" fill="#4A7BD6"/>
  <ellipse cx="60" cy="68" rx="30" ry="10" fill="#B8D4F5"/>
  <circle cx="38" cy="55" r="3" fill="#2C2C2C"/>
  <path d="M 50 70 L 42 82 L 55 72 Z" fill="#4A7BD6"/>
</svg>''';

const _penguin = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="60" cy="70" rx="28" ry="35" fill="#2C2C2C"/>
  <ellipse cx="60" cy="72" rx="18" ry="28" fill="#FFFFFF"/>
  <circle cx="60" cy="35" r="18" fill="#2C2C2C"/>
  <ellipse cx="60" cy="38" rx="12" ry="14" fill="#FFFFFF"/>
  <circle cx="56" cy="36" r="3" fill="#2C2C2C"/>
  <circle cx="64" cy="36" r="3" fill="#2C2C2C"/>
  <ellipse cx="60" cy="42" rx="4" ry="3" fill="#F4A742"/>
  <ellipse cx="35" cy="70" rx="8" ry="22" fill="#1C1C1C" transform="rotate(-20 35 70)"/>
  <ellipse cx="85" cy="70" rx="8" ry="22" fill="#1C1C1C" transform="rotate(20 85 70)"/>
  <ellipse cx="52" cy="100" rx="8" ry="5" fill="#F4A742"/>
  <ellipse cx="68" cy="100" rx="8" ry="5" fill="#F4A742"/>
  <circle cx="50" cy="42" r="3" fill="#F4C962" opacity="0.4"/>
  <circle cx="70" cy="42" r="3" fill="#F4C962" opacity="0.4"/>
</svg>''';

const _butterfly = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="40" cy="50" rx="18" ry="22" fill="#E85B9B"/>
  <ellipse cx="38" cy="72" rx="15" ry="18" fill="#F48BB8"/>
  <ellipse cx="80" cy="50" rx="18" ry="22" fill="#E85B9B"/>
  <ellipse cx="82" cy="72" rx="15" ry="18" fill="#F48BB8"/>
  <circle cx="40" cy="48" r="5" fill="#FFF" opacity="0.6"/>
  <circle cx="80" cy="48" r="5" fill="#FFF" opacity="0.6"/>
  <circle cx="38" cy="70" r="4" fill="#FFF" opacity="0.6"/>
  <circle cx="82" cy="70" r="4" fill="#FFF" opacity="0.6"/>
  <ellipse cx="60" cy="60" rx="6" ry="28" fill="#2C2C2C"/>
  <circle cx="60" cy="45" r="5" fill="#2C2C2C"/>
  <path d="M 60 42 Q 55 35 52 32" stroke="#2C2C2C" stroke-width="2" fill="none" stroke-linecap="round"/>
  <path d="M 60 42 Q 65 35 68 32" stroke="#2C2C2C" stroke-width="2" fill="none" stroke-linecap="round"/>
  <circle cx="52" cy="32" r="2" fill="#2C2C2C"/>
  <circle cx="68" cy="32" r="2" fill="#2C2C2C"/>
</svg>''';

const _snake = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M 30 80 Q 20 60 35 45 Q 50 30 70 35 Q 90 40 95 55 Q 100 70 85 80 Q 70 90 50 85"
        stroke="#6FBF8B" stroke-width="20" fill="none" stroke-linecap="round"/>
  <circle cx="40" cy="65" r="4" fill="#4A9F6A"/>
  <circle cx="55" cy="50" r="4" fill="#4A9F6A"/>
  <circle cx="75" cy="52" r="4" fill="#4A9F6A"/>
  <circle cx="85" cy="68" r="4" fill="#4A9F6A"/>
  <ellipse cx="32" cy="78" rx="12" ry="10" fill="#6FBF8B"/>
  <circle cx="28" cy="76" r="3" fill="#F4C962"/>
  <circle cx="28" cy="76" r="1.5" fill="#2C2C2C"/>
  <path d="M 24 80 L 18 82 M 24 80 L 18 78" stroke="#E85B5B" stroke-width="1.5" fill="none"/>
</svg>''';

const _kangaroo = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="60" cy="65" rx="22" ry="28" fill="#B8845B"/>
  <ellipse cx="55" cy="38" rx="14" ry="16" fill="#B8845B"/>
  <ellipse cx="48" cy="26" rx="6" ry="14" fill="#A87555" transform="rotate(-20 48 26)"/>
  <ellipse cx="62" cy="26" rx="6" ry="14" fill="#A87555" transform="rotate(20 62 26)"/>
  <ellipse cx="48" cy="28" rx="3" ry="8" fill="#D4A574" transform="rotate(-20 48 28)"/>
  <ellipse cx="62" cy="28" rx="3" ry="8" fill="#D4A574" transform="rotate(20 62 28)"/>
  <circle cx="52" cy="38" r="2" fill="#2C2C2C"/>
  <circle cx="58" cy="38" r="2" fill="#2C2C2C"/>
  <ellipse cx="55" cy="44" rx="3" ry="2" fill="#2C2C2C"/>
  <ellipse cx="60" cy="70" rx="16" ry="22" fill="#D4A574"/>
  <ellipse cx="45" cy="60" rx="5" ry="12" fill="#A87555"/>
  <ellipse cx="75" cy="60" rx="5" ry="12" fill="#A87555"/>
  <path d="M 75 85 Q 95 90 98 95" stroke="#A87555" stroke-width="10" fill="none" stroke-linecap="round"/>
  <ellipse cx="50" cy="95" rx="12" ry="8" fill="#A87555" transform="rotate(-10 50 95)"/>
  <ellipse cx="70" cy="95" rx="12" ry="8" fill="#A87555" transform="rotate(10 70 95)"/>
</svg>''';

const _bee = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="45" cy="50" rx="15" ry="20" fill="#FFF" opacity="0.7" transform="rotate(-30 45 50)"/>
  <ellipse cx="75" cy="50" rx="15" ry="20" fill="#FFF" opacity="0.7" transform="rotate(30 75 50)"/>
  <ellipse cx="60" cy="60" rx="18" ry="25" fill="#F4C962"/>
  <ellipse cx="60" cy="52" rx="18" ry="5" fill="#2C2C2C"/>
  <ellipse cx="60" cy="63" rx="18" ry="5" fill="#2C2C2C"/>
  <ellipse cx="60" cy="74" rx="18" ry="5" fill="#2C2C2C"/>
  <circle cx="60" cy="38" r="12" fill="#2C2C2C"/>
  <circle cx="56" cy="36" r="3" fill="#FFF"/>
  <circle cx="64" cy="36" r="3" fill="#FFF"/>
  <path d="M 56 30 Q 52 22 50 18" stroke="#2C2C2C" stroke-width="2" fill="none" stroke-linecap="round"/>
  <path d="M 64 30 Q 68 22 70 18" stroke="#2C2C2C" stroke-width="2" fill="none" stroke-linecap="round"/>
  <circle cx="50" cy="18" r="2" fill="#2C2C2C"/>
  <circle cx="70" cy="18" r="2" fill="#2C2C2C"/>
  <path d="M 60 82 L 60 90" stroke="#2C2C2C" stroke-width="3" fill="none" stroke-linecap="round"/>
</svg>''';

const _fox = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="65" cy="75" rx="25" ry="20" fill="#E86B5B"/>
  <circle cx="55" cy="50" r="22" fill="#E86B5B"/>
  <path d="M 40 35 L 35 15 L 48 30 Z" fill="#E86B5B"/>
  <path d="M 62 28 L 68 12 L 70 32 Z" fill="#E86B5B"/>
  <path d="M 42 30 L 38 20 L 46 28 Z" fill="#2C2C2C"/>
  <path d="M 64 26 L 66 18 L 68 28 Z" fill="#2C2C2C"/>
  <ellipse cx="55" cy="52" rx="16" ry="14" fill="#FFFFFF"/>
  <ellipse cx="55" cy="58" rx="8" ry="10" fill="#FFFFFF"/>
  <ellipse cx="55" cy="60" rx="4" ry="3" fill="#2C2C2C"/>
  <circle cx="50" cy="48" r="3" fill="#2C2C2C"/>
  <circle cx="60" cy="48" r="3" fill="#2C2C2C"/>
  <ellipse cx="88" cy="72" rx="20" ry="12" fill="#E86B5B" transform="rotate(25 88 72)"/>
  <ellipse cx="92" cy="68" rx="10" ry="6" fill="#FFFFFF" transform="rotate(25 92 68)"/>
</svg>''';

const _koala = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="60" cy="75" rx="28" ry="24" fill="#8B9B9F"/>
  <circle cx="60" cy="45" r="26" fill="#8B9B9F"/>
  <circle cx="38" cy="28" r="16" fill="#7B8B8F"/>
  <circle cx="82" cy="28" r="16" fill="#7B8B8F"/>
  <circle cx="38" cy="30" r="10" fill="#D4C4C0"/>
  <circle cx="82" cy="30" r="10" fill="#D4C4C0"/>
  <ellipse cx="60" cy="50" rx="18" ry="20" fill="#D4C4C0"/>
  <ellipse cx="60" cy="52" rx="10" ry="12" fill="#2C2C2C"/>
  <circle cx="52" cy="42" r="3" fill="#2C2C2C"/>
  <circle cx="68" cy="42" r="3" fill="#2C2C2C"/>
  <ellipse cx="60" cy="78" rx="20" ry="18" fill="#C4B4B0"/>
  <ellipse cx="38" cy="70" rx="8" ry="16" fill="#7B8B8F"/>
  <ellipse cx="82" cy="70" rx="8" ry="16" fill="#7B8B8F"/>
</svg>''';

const _bat = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M 25 55 Q 15 45 20 35 Q 30 40 35 50 Z" fill="#785BC8"/>
  <path d="M 95 55 Q 105 45 100 35 Q 90 40 85 50 Z" fill="#785BC8"/>
  <ellipse cx="32" cy="60" rx="22" ry="18" fill="#6A4DB8" transform="rotate(-25 32 60)"/>
  <ellipse cx="88" cy="60" rx="22" ry="18" fill="#6A4DB8" transform="rotate(25 88 60)"/>
  <ellipse cx="60" cy="65" rx="14" ry="18" fill="#5A3DA8"/>
  <circle cx="60" cy="48" r="12" fill="#5A3DA8"/>
  <path d="M 52 42 L 48 32 L 54 40 Z" fill="#785BC8"/>
  <path d="M 68 42 L 72 32 L 66 40 Z" fill="#785BC8"/>
  <circle cx="56" cy="48" r="2" fill="#F4C962"/>
  <circle cx="64" cy="48" r="2" fill="#F4C962"/>
  <path d="M 58 52 L 58 56" stroke="#FFF" stroke-width="1.5" fill="none"/>
  <path d="M 62 52 L 62 56" stroke="#FFF" stroke-width="1.5" fill="none"/>
</svg>''';

const _octopus = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M 35 70 Q 25 85 22 95" stroke="#C85BE8" stroke-width="8" fill="none" stroke-linecap="round"/>
  <path d="M 45 72 Q 38 88 35 98" stroke="#C85BE8" stroke-width="8" fill="none" stroke-linecap="round"/>
  <path d="M 55 74 Q 52 90 50 100" stroke="#C85BE8" stroke-width="8" fill="none" stroke-linecap="round"/>
  <path d="M 65 74 Q 68 90 70 100" stroke="#C85BE8" stroke-width="8" fill="none" stroke-linecap="round"/>
  <path d="M 75 72 Q 82 88 85 98" stroke="#C85BE8" stroke-width="8" fill="none" stroke-linecap="round"/>
  <path d="M 85 70 Q 95 85 98 95" stroke="#C85BE8" stroke-width="8" fill="none" stroke-linecap="round"/>
  <ellipse cx="60" cy="50" rx="30" ry="28" fill="#D85BF8"/>
  <circle cx="50" cy="48" r="8" fill="#FFF"/>
  <circle cx="70" cy="48" r="8" fill="#FFF"/>
  <circle cx="50" cy="48" r="4" fill="#2C2C2C"/>
  <circle cx="70" cy="48" r="4" fill="#2C2C2C"/>
  <circle cx="42" cy="55" r="5" fill="#F48BF8" opacity="0.5"/>
  <circle cx="78" cy="55" r="5" fill="#F48BF8" opacity="0.5"/>
</svg>''';

const _wolf = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="65" cy="72" rx="28" ry="22" fill="#6B5B78"/>
  <circle cx="48" cy="50" r="20" fill="#6B5B78"/>
  <path d="M 35 38 L 32 22 L 42 35 Z" fill="#5B4B68"/>
  <path d="M 56 34 L 60 20 L 58 36 Z" fill="#5B4B68"/>
  <ellipse cx="40" cy="55" rx="12" ry="10" fill="#8B7B98"/>
  <ellipse cx="38" cy="58" rx="4" ry="3" fill="#2C2C2C"/>
  <circle cx="44" cy="46" r="3" fill="#F4C962"/>
  <circle cx="52" cy="44" r="3" fill="#F4C962"/>
  <circle cx="44" cy="46" r="1.5" fill="#2C2C2C"/>
  <circle cx="52" cy="44" r="1.5" fill="#2C2C2C"/>
  <ellipse cx="55" cy="70" rx="18" ry="16" fill="#8B7B98"/>
  <rect x="48" y="85" width="8" height="18" rx="4" fill="#5B4B68"/>
  <rect x="68" y="85" width="8" height="18" rx="4" fill="#5B4B68"/>
  <ellipse cx="88" cy="75" rx="18" ry="10" fill="#6B5B78" transform="rotate(20 88 75)"/>
</svg>''';

// ── Non-animal subject SVGs ───────────────────────────────────────────────────

const _mathSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <rect x="20" y="20" width="80" height="80" rx="16" fill="#FFD23F"/>
  <rect x="20" y="20" width="80" height="26" rx="16" fill="#E8B800"/>
  <rect x="20" y="34" width="80" height="12" fill="#E8B800"/>
  <circle cx="38" cy="65" r="8" fill="#FF6B35"/>
  <circle cx="82" cy="65" r="8" fill="#4ECDC4"/>
  <rect x="56" y="58" width="8" height="14" rx="4" fill="#7B6EC8"/>
  <rect x="50" y="64" width="20" height="8" rx="4" fill="#7B6EC8"/>
  <circle cx="38" cy="88" r="8" fill="#4ECDC4"/>
  <circle cx="82" cy="88" r="8" fill="#FF6B35"/>
  <rect x="55" y="84" width="10" height="8" rx="4" fill="#2C2C2C"/>
</svg>''';

const _scienceSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <path d="M 48 20 L 48 60 L 28 90 Q 24 98 30 102 L 90 102 Q 96 98 92 90 L 72 60 L 72 20 Z" fill="#7BCF4F"/>
  <path d="M 48 20 L 48 60 L 28 90 Q 24 98 30 102 L 90 102 Q 96 98 92 90 L 72 60 L 72 20 Z" fill="#A8E87A" opacity="0.5"/>
  <rect x="44" y="16" width="32" height="8" rx="4" fill="#5AAF2F"/>
  <circle cx="45" cy="82" r="8" fill="#FFF" opacity="0.8"/>
  <circle cx="65" cy="90" r="6" fill="#FFF" opacity="0.8"/>
  <circle cx="80" cy="82" r="5" fill="#FFF" opacity="0.8"/>
  <path d="M 48 50 L 72 50" stroke="#5AAF2F" stroke-width="2"/>
</svg>''';

const _languageSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <rect x="18" y="20" width="84" height="88" rx="10" fill="#7B6EC8"/>
  <rect x="25" y="20" width="70" height="88" rx="8" fill="#F5F0FF"/>
  <rect x="18" y="20" width="14" height="88" rx="7" fill="#9B8BBF"/>
  <rect x="34" y="40" width="50" height="6" rx="3" fill="#7B6EC8" opacity="0.4"/>
  <rect x="34" y="54" width="44" height="6" rx="3" fill="#7B6EC8" opacity="0.4"/>
  <rect x="34" y="68" width="48" height="6" rx="3" fill="#7B6EC8" opacity="0.4"/>
  <rect x="34" y="82" width="36" height="6" rx="3" fill="#7B6EC8" opacity="0.4"/>
</svg>''';

const _musicSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="38" cy="88" rx="16" ry="12" fill="#5BA8E8"/>
  <ellipse cx="80" cy="78" rx="16" ry="12" fill="#5BA8E8"/>
  <rect x="50" y="28" width="8" height="62" rx="4" fill="#3A88C8"/>
  <rect x="50" y="28" width="46" height="8" rx="4" fill="#3A88C8"/>
  <rect x="84" y="28" width="12" height="52" rx="4" fill="#3A88C8"/>
  <circle cx="38" cy="88" r="4" fill="#2C5B8F"/>
  <circle cx="80" cy="78" r="4" fill="#2C5B8F"/>
</svg>''';

const _artsSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <circle cx="60" cy="60" r="42" fill="#F5F0E8"/>
  <circle cx="60" cy="60" r="42" fill="none" stroke="#E8D4A0" stroke-width="6"/>
  <circle cx="60" cy="28" r="12" fill="#E85B5B"/>
  <circle cx="86" cy="44" r="12" fill="#F4C962"/>
  <circle cx="86" cy="76" r="12" fill="#6BBF6F"/>
  <circle cx="60" cy="92" r="12" fill="#5BA8E8"/>
  <circle cx="34" cy="76" r="12" fill="#9B5BE8"/>
  <circle cx="34" cy="44" r="12" fill="#E8784A"/>
  <circle cx="60" cy="60" r="14" fill="#FFFFFF"/>
  <circle cx="60" cy="60" r="6" fill="#E8D4A0"/>
</svg>''';

const _weatherSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <circle cx="60" cy="45" r="24" fill="#F4C962"/>
  <line x1="60" y1="12" x2="60" y2="4" stroke="#F4C962" stroke-width="5" stroke-linecap="round"/>
  <line x1="60" y1="86" x2="60" y2="78" stroke="#F4C962" stroke-width="5" stroke-linecap="round"/>
  <line x1="27" y1="45" x2="19" y2="45" stroke="#F4C962" stroke-width="5" stroke-linecap="round"/>
  <line x1="101" y1="45" x2="93" y2="45" stroke="#F4C962" stroke-width="5" stroke-linecap="round"/>
  <ellipse cx="55" cy="82" rx="28" ry="18" fill="#B8D4F5"/>
  <ellipse cx="72" cy="86" rx="22" ry="16" fill="#D0E8FF"/>
  <ellipse cx="40" cy="88" rx="18" ry="14" fill="#D0E8FF"/>
</svg>''';

const _generalSvg = '''<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <circle cx="60" cy="60" r="45" fill="#F4C962"/>
  <circle cx="60" cy="55" r="28" fill="#FFFFFF"/>
  <circle cx="52" cy="50" r="5" fill="#2C2C2C"/>
  <circle cx="68" cy="50" r="5" fill="#2C2C2C"/>
  <path d="M 50 65 Q 60 72 70 65" stroke="#2C2C2C" stroke-width="3" fill="none" stroke-linecap="round"/>
  <circle cx="44" cy="62" r="5" fill="#F4A0A0" opacity="0.6"/>
  <circle cx="76" cy="62" r="5" fill="#F4A0A0" opacity="0.6"/>
</svg>''';

// ── Keyword → (svgString, color) map ─────────────────────────────────────────

const Map<String, AnimalData> _map = {
  'lion':       AnimalData(_lion,       Color(0xFFE8A85B)),
  'elephant':   AnimalData(_elephant,   Color(0xFF7DBEDB)),
  'eagle':      AnimalData(_eagle,      Color(0xFF8B6F4F)),
  'dolphin':    AnimalData(_dolphin,    Color(0xFF5BBFE8)),
  'giraffe':    AnimalData(_giraffe,    Color(0xFFF4C962)),
  'frog':       AnimalData(_frog,       Color(0xFF6BBF6F)),
  'shark':      AnimalData(_shark,      Color(0xFF5B8CE8)),
  'penguin':    AnimalData(_penguin,    Color(0xFF4A4A6A)),
  'butterfly':  AnimalData(_butterfly,  Color(0xFFE85B9B)),
  'snake':      AnimalData(_snake,      Color(0xFF6FBF8B)),
  'kangaroo':   AnimalData(_kangaroo,   Color(0xFFB8845B)),
  'bee':        AnimalData(_bee,        Color(0xFFF4C962)),
  'fox':        AnimalData(_fox,        Color(0xFFE86B5B)),
  'koala':      AnimalData(_koala,      Color(0xFF8B9B9F)),
  'bat':        AnimalData(_bat,        Color(0xFF785BC8)),
  'octopus':    AnimalData(_octopus,    Color(0xFFC85BE8)),
  'wolf':       AnimalData(_wolf,       Color(0xFF6B5B78)),
  // subjects
  'math':       AnimalData(_mathSvg,    Color(0xFFFFD23F)),
  'science':    AnimalData(_scienceSvg, Color(0xFF7BCF4F)),
  'language':   AnimalData(_languageSvg,Color(0xFF7B6EC8)),
  'music':      AnimalData(_musicSvg,   Color(0xFF5BA8E8)),
  'arts':       AnimalData(_artsSvg,    Color(0xFFE8784A)),
  'weather':    AnimalData(_weatherSvg, Color(0xFF5BBFE8)),
  'general':    AnimalData(_generalSvg, Color(0xFFF4C962)),
};

// ── Animals list for variety fallback ────────────────────────────────────────

const _animalKeys = [
  'lion', 'elephant', 'eagle', 'dolphin', 'giraffe', 'frog',
  'shark', 'penguin', 'butterfly', 'snake', 'kangaroo', 'bee',
  'fox', 'koala', 'bat', 'octopus', 'wolf',
];

// ── Public API ────────────────────────────────────────────────────────────────

AnimalData illustrationFor(String question, {int categoryId = 0, int questionIndex = 0}) {
  final t = question.toLowerCase();

  // Animals — specific keyword matches
  if (t.contains('lion') || t.contains('roar') || t.contains('mane')) return _map['lion']!;
  if (t.contains('elephant') || t.contains('trunk') || t.contains('tusk') || t.contains('gajah')) return _map['elephant']!;
  if (t.contains('eagle') || t.contains('hawk') || t.contains('owl') || t.contains('bird') || t.contains('helang')) return _map['eagle']!;
  if (t.contains('dolphin') || t.contains('whale') || t.contains('porpoise') || t.contains('paus')) return _map['dolphin']!;
  if (t.contains('giraffe') || t.contains('zirafah')) return _map['giraffe']!;
  if (t.contains('frog') || t.contains('toad') || t.contains('amphibian')) return _map['frog']!;
  if (t.contains('shark') || t.contains('crab') || t.contains('ketam') || t.contains('gill')) return _map['shark']!;
  if (t.contains('penguin') || t.contains('cannot fly')) return _map['penguin']!;
  if (t.contains('butterfly') || t.contains('caterpillar') || t.contains('chrysalis') || t.contains('kupu')) return _map['butterfly']!;
  if (t.contains('snake') || t.contains('serpent') || t.contains('slither') || t.contains('ular')) return _map['snake']!;
  if (t.contains('kangaroo') || t.contains('australia') || t.contains('marsupial') || t.contains('zebra')) return _map['kangaroo']!;
  if (t.contains('bee') || t.contains('honey') || t.contains('hive') || t.contains('sting') || t.contains('lebah') || t.contains('madu') || t.contains('insect') || t.contains('serangga')) return _map['bee']!;
  if (t.contains('fox') || t.contains('vixen')) return _map['fox']!;
  if (t.contains('koala') || t.contains('eucalyptus')) return _map['koala']!;
  if (t.contains('bat') || t.contains('echolocation') || t.contains('only mammal that can fly')) return _map['bat']!;
  if (t.contains('octopus') || t.contains('tentacle') || t.contains('squid')) return _map['octopus']!;
  if (t.contains('wolf') || t.contains('pack of') || t.contains('howl')) return _map['wolf']!;
  if (t.contains('cow') || t.contains('moo') || t.contains('cattle') || t.contains('bovine')) return _map['elephant']!;
  if (t.contains('rabbit') || t.contains('bunny') || t.contains('hare')) return _map['kangaroo']!;
  if (t.contains('fish') || t.contains('swim') || t.contains('aquatic') || t.contains('underwater')) return _map['shark']!;
  if (t.contains('cat') || t.contains('kitten') || t.contains('feline')) return _map['lion']!;
  if (t.contains('dog') || t.contains('puppy') || t.contains('canine')) return _map['fox']!;
  if (t.contains('bear') || t.contains('grizzly') || t.contains('panda')) return _map['koala']!;
  if (t.contains('tiger') || t.contains('stripe') || t.contains('cheetah')) return _map['lion']!;
  if (t.contains('monkey') || t.contains('ape') || t.contains('chimpanzee') || t.contains('gorilla')) return _map['kangaroo']!;
  if (t.contains('insect') || t.contains('bug') || t.contains('moth') || t.contains('ant')) return _map['butterfly']!;
  if (t.contains('reptile') || t.contains('lizard') || t.contains('crocodile') || t.contains('turtle')) return _map['snake']!;
  if (t.contains('animal') || t.contains('mammal') || t.contains('creature') || t.contains('habitat')) return _map['lion']!;

  // Fallback: cycle through all animals by question index so every question gets a different one
  return _map[_animalKeys[questionIndex % _animalKeys.length]]!;
}
