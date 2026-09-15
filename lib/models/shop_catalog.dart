import 'package:flutter/material.dart';

import 'progression.dart';

/// Everything the star shop sells.
///
/// Cosmetics only. Nothing here gates an activity, a story or a quiz, so a
/// child who never spends a star can still reach every piece of learning
/// content — the shop exists to give stars somewhere to go, not to put
/// content behind a wall.
///
/// Nothing that was already free became purchasable: the six Buddies in the
/// avatar picker stay free, and the shop adds ten more alongside hats,
/// accessories and colour themes.
class ShopCatalog {
  ShopCatalog._();

  static const List<ShopItem> items = [
    // ── Extra Buddies ──────────────────────────────────────────────────────
    ShopItem(key: 'buddy_nova', kind: 'buddy', name: 'Nova', nameMs: 'Nova', cost: 60, value: 'nova'),
    ShopItem(key: 'buddy_coco', kind: 'buddy', name: 'Coco', nameMs: 'Coco', cost: 60, value: 'coco'),
    ShopItem(key: 'buddy_kiki', kind: 'buddy', name: 'Kiki', nameMs: 'Kiki', cost: 80, value: 'kiki'),
    ShopItem(key: 'buddy_momo', kind: 'buddy', name: 'Momo', nameMs: 'Momo', cost: 80, value: 'momo'),
    ShopItem(key: 'buddy_rio', kind: 'buddy', name: 'Rio', nameMs: 'Rio', cost: 80, value: 'rio'),
    ShopItem(key: 'buddy_boba', kind: 'buddy', name: 'Boba', nameMs: 'Boba', cost: 80, value: 'boba'),
    ShopItem(key: 'buddy_yuki', kind: 'buddy', name: 'Yuki', nameMs: 'Yuki', cost: 80, value: 'yuki'),
    ShopItem(key: 'buddy_gigi', kind: 'buddy', name: 'Gigi', nameMs: 'Gigi', cost: 80, value: 'gigi'),
    ShopItem(key: 'buddy_zap', kind: 'buddy', name: 'Zap', nameMs: 'Zap', cost: 80, value: 'zap'),
    ShopItem(key: 'buddy_onyx', kind: 'buddy', name: 'Onyx', nameMs: 'Onyx', cost: 120, value: 'onyx'),

    // ── Hats ───────────────────────────────────────────────────────────────
    ShopItem(key: 'hat_bow', kind: 'hat', name: 'Ribbon', nameMs: 'Reben', cost: 25, value: 'bow'),
    ShopItem(key: 'hat_cap', kind: 'hat', name: 'Cap', nameMs: 'Topi Sukan', cost: 35, value: 'cap'),
    ShopItem(key: 'hat_party', kind: 'hat', name: 'Party Hat', nameMs: 'Topi Pesta', cost: 45, value: 'party'),
    ShopItem(key: 'hat_crown', kind: 'hat', name: 'Crown', nameMs: 'Mahkota', cost: 80, value: 'crown'),
    ShopItem(key: 'hat_wizard', kind: 'hat', name: 'Wizard Hat', nameMs: 'Topi Ahli Sihir', cost: 120, value: 'wizard'),
    ShopItem(key: 'hat_beanie', kind: 'hat', name: 'Beanie', nameMs: 'Topi Kait', cost: 30, value: 'beanie'),
    ShopItem(key: 'hat_flower', kind: 'hat', name: 'Flower', nameMs: 'Bunga', cost: 30, value: 'flower'),
    ShopItem(key: 'hat_headphones', kind: 'hat', name: 'Headphones', nameMs: 'Fon Kepala', cost: 60, value: 'headphones'),
    ShopItem(key: 'hat_pirate', kind: 'hat', name: 'Pirate Hat', nameMs: 'Topi Lanun', cost: 90, value: 'pirate'),
    ShopItem(key: 'hat_halo', kind: 'hat', name: 'Halo', nameMs: 'Halo', cost: 150, value: 'halo'),

    // ── Accessories ────────────────────────────────────────────────────────
    ShopItem(key: 'acc_bowtie', kind: 'accessory', name: 'Bow Tie', nameMs: 'Tali Leher Kupu-kupu', cost: 25, value: 'bowtie'),
    ShopItem(key: 'acc_glasses', kind: 'accessory', name: 'Glasses', nameMs: 'Cermin Mata', cost: 35, value: 'glasses'),
    ShopItem(key: 'acc_scarf', kind: 'accessory', name: 'Scarf', nameMs: 'Skaf', cost: 40, value: 'scarf'),
    ShopItem(key: 'acc_medal', kind: 'accessory', name: 'Medal', nameMs: 'Pingat', cost: 60, value: 'medal'),
    ShopItem(key: 'acc_sunglasses', kind: 'accessory', name: 'Sunglasses', nameMs: 'Cermin Mata Hitam', cost: 70, value: 'sunglasses'),
    ShopItem(key: 'acc_cape', kind: 'accessory', name: 'Cape', nameMs: 'Jubah', cost: 100, value: 'cape'),

    // ── Colour themes ──────────────────────────────────────────────────────
    ShopItem(key: 'theme_ocean', kind: 'theme', name: 'Ocean', nameMs: 'Lautan', cost: 50, value: 'ocean'),
    ShopItem(key: 'theme_forest', kind: 'theme', name: 'Forest', nameMs: 'Hutan', cost: 50, value: 'forest'),
    ShopItem(key: 'theme_sunset', kind: 'theme', name: 'Sunset', nameMs: 'Senja', cost: 70, value: 'sunset'),
    ShopItem(key: 'theme_candy', kind: 'theme', name: 'Candy', nameMs: 'Gula-gula', cost: 90, value: 'candy'),
    ShopItem(key: 'theme_midnight', kind: 'theme', name: 'Midnight', nameMs: 'Tengah Malam', cost: 150, value: 'midnight'),
  ];

  static List<ShopItem> ofKind(String kind) =>
      items.where((i) => i.kind == kind).toList();

  static ShopItem? byKey(String key) {
    for (final i in items) {
      if (i.key == key) return i;
    }
    return null;
  }

  /// The shop item that grants [value] for [kind], if any. Used to tell a
  /// bought Buddy apart from one that was always free.
  static ShopItem? forValue(String kind, String value) {
    for (final i in items) {
      if (i.kind == kind && i.value == value) return i;
    }
    return null;
  }
}

/// A background palette a child can buy. Applied to the Home header so the
/// purchase is visible on the screen they see most.
class AppThemeSkin {
  final String key;
  final String name;
  final String nameMs;
  final Color background;
  final List<Color> headerGradient;

  const AppThemeSkin({
    required this.key,
    required this.name,
    required this.nameMs,
    required this.background,
    required this.headerGradient,
  });
}

/// Every skin, including the free default the app ships with.
const Map<String, AppThemeSkin> kThemeSkins = {
  'default': AppThemeSkin(
    key: 'default',
    name: 'Butter',
    nameMs: 'Mentega',
    background: Color(0xFFFCF7EC),
    headerGradient: [Color(0xFFFFD24A), Color(0xFFFFC93C)],
  ),
  'ocean': AppThemeSkin(
    key: 'ocean',
    name: 'Ocean',
    nameMs: 'Lautan',
    background: Color(0xFFEDF6FC),
    headerGradient: [Color(0xFF5AC8F5), Color(0xFF3FA7F5)],
  ),
  'forest': AppThemeSkin(
    key: 'forest',
    name: 'Forest',
    nameMs: 'Hutan',
    background: Color(0xFFEEF7F0),
    headerGradient: [Color(0xFF6FD08C), Color(0xFF3FB36B)],
  ),
  'sunset': AppThemeSkin(
    key: 'sunset',
    name: 'Sunset',
    nameMs: 'Senja',
    background: Color(0xFFFFF0EA),
    headerGradient: [Color(0xFFFF9068), Color(0xFFFF6B35)],
  ),
  'candy': AppThemeSkin(
    key: 'candy',
    name: 'Candy',
    nameMs: 'Gula-gula',
    background: Color(0xFFFDEFF6),
    headerGradient: [Color(0xFFFF9EC4), Color(0xFFFF5DA2)],
  ),
  'midnight': AppThemeSkin(
    key: 'midnight',
    name: 'Midnight',
    nameMs: 'Tengah Malam',
    background: Color(0xFFEFEFFA),
    headerGradient: [Color(0xFF7C5CFF), Color(0xFF5B6EF5)],
  ),
};

AppThemeSkin themeSkinFor(String? key) =>
    kThemeSkins[key] ?? kThemeSkins['default']!;
