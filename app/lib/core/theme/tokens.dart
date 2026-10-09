import 'package:flutter/material.dart';

export '../motion/tokens.dart';

/// Color roles from DESIGN_SYSTEM.md. Read via `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceRaised,
    required this.surfaceInk,
    required this.surfaceInkBorder,
    required this.shadow,
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
    bg: Color(0xFFF7F6F3),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF0EFEC),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceInk: Color(0xFF141413),
    surfaceInkBorder: Color(0xFF2C2B29),
    shadow: Color(0x0F141413),
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
    surfaceRaised: Color(0xFF1E1E1C),
    surfaceInk: Color(0xFF23221F),
    surfaceInkBorder: Color(0xFF3A3936),
    shadow: Color(0x52000000),
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

  /// Raised cards (white on the warm page; lifted by [AppElevation.raised]).
  final Color surfaceRaised;

  /// The "statement" hero card: ink in light, a raised #23221F in dark.
  final Color surfaceInk;

  /// Hairline on and inside the statement card (reads as the hero in dark).
  final Color surfaceInkBorder;

  /// Shadow tint with its alpha baked in; used by [AppElevation].
  final Color shadow;
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
    Color? surfaceRaised,
    Color? surfaceInk,
    Color? surfaceInkBorder,
    Color? shadow,
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
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceInk: surfaceInk ?? this.surfaceInk,
      surfaceInkBorder: surfaceInkBorder ?? this.surfaceInkBorder,
      shadow: shadow ?? this.shadow,
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
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      surfaceInk: l(surfaceInk, other.surfaceInk),
      surfaceInkBorder: l(surfaceInkBorder, other.surfaceInkBorder),
      shadow: l(shadow, other.shadow),
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

  /// Palette for content sitting on the statement card ([surfaceInk]):
  /// the dark scheme's ink, accent and due/advance on this card's surface.
  AppPalette get statement => dark.copyWith(
    bg: surfaceInk,
    surface: surfaceInk,
    surfaceRaised: surfaceInk,
    border: surfaceInkBorder,
    onInk: surfaceInk,
  );
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

  /// Hero / statement cards and bottom-sheet top corners.
  static const double xl = 24;
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

/// Layered soft shadows (a tight contact shadow + a wide ambient one).
/// Offsets and blur only, no spread: cheap on low-end GPUs.
abstract final class AppElevation {
  /// Raised cards and the statement card.
  static List<BoxShadow> raised(AppPalette p) => [
    BoxShadow(color: p.shadow, offset: const Offset(0, 1), blurRadius: 2),
    BoxShadow(color: p.shadow, offset: const Offset(0, 8), blurRadius: 24),
  ];

  /// Buttons: a smaller lift so they sit on, not above, the card.
  static List<BoxShadow> button(AppPalette p) => [
    BoxShadow(color: p.shadow, offset: const Offset(0, 1), blurRadius: 2),
    BoxShadow(color: p.shadow, offset: const Offset(0, 4), blurRadius: 12),
  ];
}
