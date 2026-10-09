import 'package:flutter/material.dart';

import 'tokens.dart';

const _font = 'HindSiliguri';
const _tabular = [FontFeature.tabularFigures()];

abstract final class AppTheme {
  /// [accent] overrides the turmeric token (platform branding).
  static ThemeData light({Color? accent}) =>
      _build(AppPalette.light.copyWith(accent: accent), Brightness.light);
  static ThemeData dark({Color? accent}) =>
      _build(AppPalette.dark.copyWith(accent: accent), Brightness.dark);

  static TextTheme _textTheme(AppPalette p) {
    TextStyle s(double size, double height, FontWeight w, {Color? color}) =>
        TextStyle(
          fontFamily: _font,
          fontSize: size,
          height: height,
          fontWeight: w,
          letterSpacing: 0,
          color: color ?? p.ink,
        );
    return TextTheme(
      displaySmall: s(
        34,
        1.15,
        FontWeight.w600,
      ).copyWith(fontFeatures: _tabular),
      headlineSmall: s(24, 1.25, FontWeight.w600),
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
          side: WidgetStateProperty.resolveWith(
            (s) => BorderSide(
              color: s.contains(WidgetState.disabled)
                  ? p.borderStrong.withValues(alpha: 0.38)
                  : p.borderStrong,
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
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        modalElevation: 4,
        shadowColor: p.ink.withValues(alpha: 0.10),
        showDragHandle: true,
        dragHandleColor: p.borderStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: p.surfaceMuted,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelMedium?.copyWith(
            color: s.contains(WidgetState.selected) ? p.ink : p.inkSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? p.ink : p.inkSecondary,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.onInk),
        actionTextColor: p.onInk,
        elevation: 4,
        shape: smShape,
      ),
      dividerTheme: DividerThemeData(
        color: p.border,
        thickness: AppSize.hairline,
        space: AppSize.hairline,
      ),
      chipTheme: ChipThemeData(
        shape: smShape,
        side: BorderSide(color: p.border),
        backgroundColor: p.surface,
        selectedColor: p.surfaceMuted,
        labelStyle: text.labelMedium,
        showCheckmark: false,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.ink),
    );
  }
}
