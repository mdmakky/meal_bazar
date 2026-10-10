import 'package:flutter/material.dart';

import '../motion/transitions.dart';
import 'tokens.dart';

const _font = 'HindSiliguri';
const _tabular = [FontFeature.tabularFigures()];

abstract final class AppTheme {
  /// [accent] overrides the turmeric token (platform branding).
  static ThemeData light({Color? accent}) =>
      _build(AppPalette.light.copyWith(accent: accent), Brightness.light);
  static ThemeData dark({Color? accent}) =>
      _build(AppPalette.dark.copyWith(accent: accent), Brightness.dark);

  /// Theme for content on the statement card (`AppCard.ink`): text, icons,
  /// buttons and `context.palette` all resolve against [AppPalette.statement].
  static ThemeData statement(Brightness b) =>
      b == Brightness.light ? _statementLight : _statementDark;
  static final _statementLight = _build(
    AppPalette.light.statement,
    Brightness.dark,
  );
  static final _statementDark = _build(
    AppPalette.dark.statement,
    Brightness.dark,
  );

  static TextTheme _textTheme(AppPalette p) {
    // Tabular figures on every role: numbers line up wherever they appear.
    TextStyle s(
      double size,
      double height,
      FontWeight w, {
      Color? color,
      double tracking = 0,
    }) => TextStyle(
      fontFamily: _font,
      fontSize: size,
      height: height,
      fontWeight: w,
      letterSpacing: tracking,
      color: color ?? p.ink,
      fontFeatures: _tabular,
    );
    return TextTheme(
      // Hero figures. Tight tracking is for Latin digits; RollingNumber and
      // AppType.figure reset it to 0 for Bangla digits.
      displayLarge: s(44, 1.05, FontWeight.w600, tracking: -0.5),
      displaySmall: s(34, 1.15, FontWeight.w600, tracking: -0.25),
      headlineSmall: s(24, 1.25, FontWeight.w600),
      // Section titles: one step up from v1, and a touch tighter.
      titleLarge: s(20, 1.3, FontWeight.w600, tracking: -0.1),
      titleMedium: s(18, 1.35, FontWeight.w600),
      titleSmall: s(16, 1.4, FontWeight.w600),
      bodyLarge: s(16, 1.55, FontWeight.w400),
      bodyMedium: s(14, 1.5, FontWeight.w400, color: p.inkSecondary),
      labelLarge: s(15, 1.3, FontWeight.w500),
      labelMedium: s(13, 1.3, FontWeight.w500),
      labelSmall: s(12, 1.3, FontWeight.w500, color: p.inkTertiary),
    );
  }

  static ThemeData _build(AppPalette p, Brightness b) {
    final text = _textTheme(p);
    final scheme = ColorScheme(
      brightness: b,
      primary: p.ink,
      onPrimary: p.onInk,
      secondary: p.ink,
      onSecondary: p.onInk,
      secondaryContainer: p.surfaceMuted,
      onSecondaryContainer: p.ink,
      tertiary: p.accent,
      onTertiary: b == Brightness.light ? p.ink : p.onInk,
      tertiaryContainer: p.accentSoft,
      onTertiaryContainer: p.ink,
      error: p.due,
      onError: p.onInk,
      surface: p.surface,
      onSurface: p.ink,
      onSurfaceVariant: p.inkSecondary,
      surfaceContainerLowest: p.surface,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surface,
      surfaceContainerHighest: p.surfaceMuted,
      outline: p.border,
      outlineVariant: p.borderStrong,
      inverseSurface: p.ink,
      onInverseSurface: p.onInk,
      shadow: p.ink,
      scrim: p.ink,
      surfaceTint: Colors.transparent,
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
    const buttonSize = Size(AppSize.touch, AppSize.touch);
    const buttonPadding = EdgeInsets.symmetric(horizontal: AppSpace.xl);
    final smShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
    );
    OutlineInputBorder inputBorder(Color c, [double w = AppSize.hairline]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      fontFamily: _font,
      textTheme: text,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      extensions: [p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.ink,
          foregroundColor: p.onInk,
          disabledBackgroundColor: p.ink.withValues(alpha: 0.38),
          disabledForegroundColor: p.onInk,
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? p.ink.withValues(alpha: 0.38)
                : p.ink,
          ),
          backgroundColor: WidgetStatePropertyAll(p.surfaceRaised),
          side: WidgetStateProperty.resolveWith(
            (s) => BorderSide(
              color: s.contains(WidgetState.disabled)
                  ? p.border.withValues(alpha: 0.38)
                  : p.border,
            ),
          ),
          minimumSize: const WidgetStatePropertyAll(buttonSize),
          padding: const WidgetStatePropertyAll(buttonPadding),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.ink,
          disabledForegroundColor: p.ink.withValues(alpha: 0.38),
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.ink,
        foregroundColor: p.onInk,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.fab),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: inputBorder(p.borderStrong),
        enabledBorder: inputBorder(p.borderStrong),
        focusedBorder: inputBorder(p.ink, 2),
        errorBorder: inputBorder(p.due),
        focusedErrorBorder: inputBorder(p.due, 2),
        disabledBorder: inputBorder(p.border),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        labelStyle: text.bodyMedium,
        hintStyle: text.bodyLarge?.copyWith(color: p.inkTertiary),
        errorStyle: text.labelSmall?.copyWith(color: p.due),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: p.border),
        ),
      ),
      // Calendars: paper surface, the amber accent marks the chosen day.
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: p.surface,
        headerForegroundColor: p.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? p.inkTertiary : p.ink,
        ),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : null,
        ),
        todayForegroundColor: WidgetStatePropertyAll(p.ink),
        todayBackgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : null,
        ),
        todayBorder: BorderSide(color: p.accent),
        yearForegroundColor: WidgetStatePropertyAll(p.ink),
        yearBackgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : null,
        ),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: p.ink),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: p.ink),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        modalElevation: 4,
        shadowColor: p.ink.withValues(alpha: 0.10),
        showDragHandle: true,
        dragHandleColor: p.borderStrong,
        dragHandleSize: const Size(36, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.onInk),
        actionTextColor: p.accent,
        closeIconColor: p.onInk,
        elevation: 6,
        insetPadding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          0,
          AppSpace.gutter,
          AppSpace.md,
        ),
        shape: const StadiumBorder(),
      ),
      dividerTheme: DividerThemeData(
        color: p.border,
        thickness: AppSize.hairline,
        space: AppSize.hairline,
      ),
      // Selected = filled ink with a check that slides in (RawChip animates
      // both, ~180 ms); unselected = raised white with a hairline.
      chipTheme: ChipThemeData(
        shape: smShape,
        side: WidgetStateBorderSide.resolveWith(
          (s) => BorderSide(
            color: s.contains(WidgetState.selected) ? p.ink : p.border,
          ),
        ),
        color: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? p.surfaceMuted
              : s.contains(WidgetState.selected)
              ? p.ink
              : p.surfaceRaised,
        ),
        labelStyle: text.labelMedium?.copyWith(
          color: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.onInk : p.ink,
          ),
        ),
        checkmarkColor: p.onInk,
        showCheckmark: true,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.ink),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SharedAxisPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Type helpers that the M3 scale has no role for.
abstract final class AppType {
  /// Small label over a figure inside a card ("এই মাসের বাকি"): 12 sp w600,
  /// tracked 0.6 for English, untracked for Bangla (tracking breaks
  /// conjuncts). Not a kicker above a heading: headings carry themselves.
  static TextStyle overline(BuildContext context) {
    final bn = Localizations.localeOf(context).languageCode == 'bn';
    return Theme.of(context).textTheme.labelSmall!.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: bn ? 0 : 0.6,
      color: context.palette.inkSecondary,
    );
  }

  /// [style] for a figure: keeps tight tracking for Latin digits, resets it
  /// for Bangla digits.
  static TextStyle figure(TextStyle style, {required bool banglaDigits}) =>
      banglaDigits ? style.copyWith(letterSpacing: 0) : style;
}
