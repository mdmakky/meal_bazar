import 'package:flutter/material.dart';

/// Color roles from DESIGN_SYSTEM.md. Read via `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.borderStrong,
    required this.ink,
    required this.onInk,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.accent,
    required this.accentSoft,
    required this.due,
    required this.advance,
    required this.warning,
  });

  static const light = AppPalette(
    bg: Color(0xFFFAFAF9),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF3F3F1),
    border: Color(0xFFE6E5E2),
    borderStrong: Color(0xFFCFCECA),
    ink: Color(0xFF141413),
    onInk: Color(0xFFFAFAF9),
    inkSecondary: Color(0xFF5C5B57),
    inkTertiary: Color(0xFF6F6E6A),
    accent: Color(0xFFC98A0B),
    accentSoft: Color(0xFFFBF1DC),
    due: Color(0xFFB42318),
    advance: Color(0xFF067647),
    warning: Color(0xFFB54708),
  );

  static const dark = AppPalette(
    bg: Color(0xFF0F0F0E),
    surface: Color(0xFF181817),
    surfaceMuted: Color(0xFF201F1E),
    border: Color(0xFF2C2B29),
    borderStrong: Color(0xFF3D3C39),
    ink: Color(0xFFF2F1EE),
    onInk: Color(0xFF141413),
    inkSecondary: Color(0xFFA9A7A2),
    inkTertiary: Color(0xFF8D8B86),
    accent: Color(0xFFE8B33A),
    accentSoft: Color(0xFF3A2E12),
    due: Color(0xFFF97066),
    advance: Color(0xFF47CD89),
    warning: Color(0xFFFDB022),
  );

  final Color bg;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color borderStrong;
  final Color ink;
  final Color onInk;
  final Color inkSecondary;
  final Color inkTertiary;
  final Color accent;
  final Color accentSoft;
  final Color due;
  final Color advance;
  final Color warning;

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceMuted,
    Color? border,
    Color? borderStrong,
    Color? ink,
    Color? onInk,
    Color? inkSecondary,
    Color? inkTertiary,
    Color? accent,
    Color? accentSoft,
    Color? due,
    Color? advance,
    Color? warning,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      ink: ink ?? this.ink,
      onInk: onInk ?? this.onInk,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      inkTertiary: inkTertiary ?? this.inkTertiary,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      due: due ?? this.due,
      advance: advance ?? this.advance,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      ink: l(ink, other.ink),
      onInk: l(onInk, other.onInk),
      inkSecondary: l(inkSecondary, other.inkSecondary),
      inkTertiary: l(inkTertiary, other.inkTertiary),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      due: l(due, other.due),
      advance: l(advance, other.advance),
      warning: l(warning, other.warning),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

/// 4 dp spacing scale. Screen gutter = [lg].
abstract final class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double gutter = lg;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double fab = 16;
}

abstract final class AppSize {
  static const double touch = 48;
  static const double hairline = 1;
  static const double dot = 8;
  static const double spinner = 20;
  static const double emptyIcon = 40;
  static const double mealCellWidth = 52;

  /// Stepper grid: − / + hit area, its visible circle, the value, rows.
  static const double stepTarget = 40;
  static const double stepFace = 28;
  static const double stepValue = 32;
  static const double gridName = 96;
  static const double gridHeader = 40;
  static const double gridRow = 56;
}

abstract final class AppMotion {
  static const proofReveal = Duration(milliseconds: 220);
  static const proofRise = 8.0;
  static const valueFade = Duration(milliseconds: 120);
  static const pulse = Duration(milliseconds: 900);
}
