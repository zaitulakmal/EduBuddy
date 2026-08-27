import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Brand: sunny butter yellow (cute, happy, draws kids in) ──
  static const Color primary = Color(0xFFFFC93C); // butter yellow
  static const Color primaryDeep = Color(0xFFF4A900); // deeper amber for text on yellow / borders
  static const Color primarySoft = Color(0xFFFEF3D6); // pale butter tint (chip bg, headers)
  static const Color onPrimary = Color(0xFF6B4E00); // warm brown text on yellow (readable)

  // Supporting pop accent (original coral) — used for CTAs / celebration
  static const Color secondary = Color(0xFFFF6B35);

  // Cohesive accent set (muted, used consistently as category/section tints)
  static const Color coral = Color(0xFFFF6B35);
  static const Color teal = Color(0xFF2BB3A3);
  static const Color indigo = Color(0xFF5B6EF5);
  static const Color violet = Color(0xFF9B6BFF);
  static const Color green = Color(0xFF3FB36B);
  static const Color blue = Color(0xFF3FA7F5);
  static const Color pink = Color(0xFFFF80AB);

  // Neutrals (warm, soft — not stark)
  static const Color background = Color(0xFFFCF7EC); // warm cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF6EFE0);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF3D3526); // warm dark brown
  static const Color textMuted = Color(0xFF9A8F7A);
  static const Color divider = Color(0xFFEBE2D2);

  // ── Funky punch accents (loud partners that make butter-yellow pop) ──
  static const Color punchTeal = Color(0xFF00C2A8); // electric teal
  static const Color punchLime = Color(0xFFA4E02A); // sunny lime
  static const Color punchViolet = Color(0xFF8A4FFF); // vivid violet
  static const Color punchPink = Color(0xFFFF5DA2); // hot pink

  // Mascot ("Buddy") colours — original blob character
  static const Color mascot = Color(0xFF7C5CFF); // fun purple body
  static const Color mascotDark = Color(0xFF5A3FD6);
  static const Color mascotCheek = Color(0xFFFF9EC4);

  static const Color success = Color(0xFF3FB36B);
  static const Color error = Color(0xFFE5484D);

  // Restored alias so existing screens keep compiling
  static const Color purple = Color(0xFF9B6BFF);

  /// Soft tinted background for an icon chip, given its accent colour.
  static Color tintFor(Color accent) {
    if (accent == coral) return const Color(0xFFFFEDE3);
    if (accent == teal) return const Color(0xFFE2F4F1);
    if (accent == indigo) return const Color(0xFFE8EBFD);
    if (accent == violet) return const Color(0xFFF0E9FF);
    if (accent == green) return const Color(0xFFE4F5EA);
    if (accent == blue) return const Color(0xFFE4F1FC);
    if (accent == pink) return const Color(0xFFFDE7F1);
    if (accent == primary) return primarySoft;
    return const Color(0xFFF6EFE0);
  }

  /// Cute cohesive category palette (applied consistently, not scattered).
  static const List<Color> categoryColors = [
    Color(0xFFFFC93C), // butter
    Color(0xFFFF6B35), // coral
    Color(0xFF3FB36B), // green
    Color(0xFF3FA7F5), // blue
    Color(0xFF9B6BFF), // violet
    Color(0xFF2BB3A3), // teal
    Color(0xFFFF80AB), // pink
    Color(0xFF5B6EF5), // indigo
  ];

  /// Soft card gradients (one accent each) for a gentle, cohesive look.
  static const List<List<Color>> gradients = [
    [Color(0xFFFFC93C), Color(0xFFFFD86B)], // butter
    [Color(0xFFFF6B35), Color(0xFFFF8C5A)], // coral
    [Color(0xFF3FB36B), Color(0xFF5FCB85)], // green
    [Color(0xFF3FA7F5), Color(0xFF62BBF7)], // blue
    [Color(0xFF9B6BFF), Color(0xFFB58CFF)], // violet
    [Color(0xFF2BB3A3), Color(0xFF4CC7B8)], // teal
  ];

  /// Funky, punchy gradients (louder — for blobs / hero accents).
  static const List<List<Color>> funkyGradients = [
    [Color(0xFFFFC93C), Color(0xFFFF6B35)], // butter → coral
    [Color(0xFF8A4FFF), Color(0xFFFF5DA2)], // violet → pink
    [Color(0xFF00C2A8), Color(0xFFA4E02A)], // teal → lime
    [Color(0xFFFF6B35), Color(0xFFFFC93C)], // coral → butter
    [Color(0xFF7C5CFF), Color(0xFF00C2A8)], // mascot → teal
  ];
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.background,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.nunitoTextTheme(TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textDark),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textDark),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textDark),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.onPrimary),
      )),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800),
          elevation: 4,
          shadowColor: AppColors.primaryDeep.withValues(alpha: 0.35),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 4,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
