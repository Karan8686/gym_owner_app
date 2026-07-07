import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────
/// Design tokens — single source of truth.
/// Must match the Stitch spec exactly.
/// ──────────────────────────────────────────────

// ---------------------------------------------------------------------------
// Colors
// ---------------------------------------------------------------------------
abstract final class AppColors {
  static const Color background   = Color(0xFFF6F6F4);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color border       = Color(0xFFE4E4E1);
  static const Color inkPrimary   = Color(0xFF161616);
  static const Color inkSecondary = Color(0xFF7A7A76);

  /// ONLY for expired / overdue / destructive states — never decorative.
  static const Color signal       = Color(0xFFD6321F);
}

// ---------------------------------------------------------------------------
// Corner radius
// ---------------------------------------------------------------------------
abstract final class AppRadius {
  static const double sm   = 4;
  static const double base = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 24;
  static const double full = 9999;
}

/// Shortcut — most widgets use the base 8 px radius.
const double cornerRadius = AppRadius.base;

// ---------------------------------------------------------------------------
// Spacing — all multiples of 4 px.
// ---------------------------------------------------------------------------
abstract final class AppSpacing {
  static const double unit             = 4;
  static const double containerPadding = 24;
  static const double gutter           = 16;
  static const double stackSm          = 8;
  static const double stackMd          = 16;
  static const double stackLg          = 32;
}

// ---------------------------------------------------------------------------
// Typography
// ---------------------------------------------------------------------------
/// Full typography scale from the Stitch design spec.
///
///  • Inter — UI labels, headers, descriptions.
///  • JetBrains Mono — all counts, timestamps, money, dates.
///
/// **Font files:** drop the `.ttf`/`.otf` files into `assets/fonts/`
/// and register them in `pubspec.yaml` under the family names
/// `JetBrainsMono` and `Inter`.
abstract final class AppText {
  // ---- Inter (grotesk sans) ------------------------------------------------

  /// 24 / 32, Semi-bold, –0.02 em tracking
  static const TextStyle display = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    letterSpacing: -0.48, // -0.02 em × 24
    color: AppColors.inkPrimary,
  );

  /// 18 / 24, Semi-bold, –0.01 em tracking
  static const TextStyle headline = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    letterSpacing: -0.18, // -0.01 em × 18
    color: AppColors.inkPrimary,
  );

  /// 16 / 24, Regular
  static const TextStyle bodyLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.inkPrimary,
  );

  /// 14 / 20, Regular — default body text
  static const TextStyle bodySm = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.inkPrimary,
  );

  /// 12 / 16, Medium, +0.05 em tracking — field labels, badges
  static const TextStyle label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0.6, // 0.05 em × 12
    color: AppColors.inkPrimary,
  );

  // ---- JetBrains Mono (monospace) ------------------------------------------

  /// 16 / 24, Medium — large data numbers
  static const TextStyle dataLg = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 24 / 16,
    color: AppColors.inkPrimary,
  );

  /// 13 / 18, Regular — table data, dates, small counts
  static const TextStyle dataSm = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
    color: AppColors.inkPrimary,
  );

  // ---- Legacy aliases (keep existing call-sites working) -------------------
  static const TextStyle numeral = dataLg;
  static const TextStyle body    = bodySm;
}

// ---------------------------------------------------------------------------
// App-wide ThemeData
// ---------------------------------------------------------------------------
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.light(
    surface: AppColors.surface,
    primary: AppColors.inkPrimary,
    error: AppColors.signal,
  ),
  dividerColor: AppColors.border,
  textTheme: const TextTheme(
    displayLarge: AppText.display,
    headlineMedium: AppText.headline,
    bodyLarge: AppText.bodyLg,
    bodyMedium: AppText.bodySm,
    labelSmall: AppText.label,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.inkPrimary,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  cardTheme: const CardThemeData(
    elevation: 0,
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(cornerRadius)),
      side: BorderSide(color: AppColors.border, width: 1),
    ),
  ),
);
