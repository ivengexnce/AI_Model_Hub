import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double page = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

abstract final class Radii {
  static const double sm = 10;
  static const double md = 14;
}

/// Horizontal page gutter; also centres content on wide screens.
double pageGutter(BuildContext context, {double maxWidth = 720}) {
  final w = MediaQuery.sizeOf(context).width;
  final side = (w - maxWidth) / 2;
  return side > Space.page ? side : Space.page;
}

abstract final class AppTheme {
  static ThemeData get light => _build(_lightScheme);
  static ThemeData get dark => _build(_darkScheme);

  /// Monospace style for metrics and technical values.
  static TextStyle mono({
    double size = 13,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: -0.3,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFF7A4D),
    onPrimary: Color(0xFF1A0B05),
    secondary: Color(0xFF9A9A9F),
    onSecondary: Color(0xFF0F0F11),
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF1A0505),
    surface: Color(0xFF0F0F11),
    onSurface: Color(0xFFEDEDEA),
    onSurfaceVariant: Color(0xFF9A9A9F),
    outline: Color(0xFF3A3A40),
    outlineVariant: Color(0xFF26262A),
    surfaceContainerLowest: Color(0xFF0B0B0C),
    surfaceContainerLow: Color(0xFF151517),
    surfaceContainer: Color(0xFF1A1A1D),
    surfaceContainerHigh: Color(0xFF222226),
    surfaceContainerHighest: Color(0xFF2A2A2F),
  );

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFC9401A),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF6B6860),
    onSecondary: Color(0xFFFFFFFF),
    error: Color(0xFFC42B2F),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFF7F5F0),
    onSurface: Color(0xFF161614),
    onSurfaceVariant: Color(0xFF6B6860),
    outline: Color(0xFFBFBBB0),
    outlineVariant: Color(0xFFE0DCD0),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFDFCF9),
    surfaceContainer: Color(0xFFF1EEE7),
    surfaceContainerHigh: Color(0xFFEAE6DD),
    surfaceContainerHighest: Color(0xFFE2DED4),
  );

  static TextTheme _textTheme(TextTheme base, ColorScheme c) {
    final t = GoogleFonts.interTextTheme(base)
        .apply(bodyColor: c.onSurface, displayColor: c.onSurface);
    TextStyle? s(
      TextStyle? style,
      double size,
      FontWeight w, {
      double? height,
      double? spacing,
      Color? color,
    }) => style?.copyWith(
      fontSize: size,
      fontWeight: w,
      height: height,
      letterSpacing: spacing,
      color: color,
    );
    return t.copyWith(
      displaySmall: s(
        t.displaySmall,
        34,
        FontWeight.w600,
        height: 1.1,
        spacing: -1.2,
      ),
      headlineMedium: s(
        t.headlineMedium,
        28,
        FontWeight.w600,
        height: 1.15,
        spacing: -0.8,
      ),
      headlineSmall: s(
        t.headlineSmall,
        22,
        FontWeight.w600,
        height: 1.2,
        spacing: -0.4,
      ),
      titleLarge: s(
        t.titleLarge,
        18,
        FontWeight.w600,
        height: 1.25,
        spacing: -0.2,
      ),
      titleMedium: s(
        t.titleMedium,
        16,
        FontWeight.w600,
        height: 1.3,
        spacing: -0.1,
      ),
      titleSmall: s(t.titleSmall, 14, FontWeight.w600, height: 1.3),
      bodyLarge: s(t.bodyLarge, 16, FontWeight.w400, height: 1.5),
      bodyMedium: s(t.bodyMedium, 14, FontWeight.w400, height: 1.5),
      bodySmall: s(
        t.bodySmall,
        12.5,
        FontWeight.w400,
        height: 1.45,
        color: c.onSurfaceVariant,
      ),
      labelLarge: s(t.labelLarge, 14, FontWeight.w600),
      labelMedium: s(t.labelMedium, 12, FontWeight.w600, spacing: 0.2),
      labelSmall: s(t.labelSmall, 11, FontWeight.w600, spacing: 0.9),
    );
  }

  static ThemeData _build(ColorScheme c) {
    final base = ThemeData(useMaterial3: true, colorScheme: c);
    final text = _textTheme(base.textTheme, c);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.sm),
    );

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      scaffoldBackgroundColor: c.surface,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleMedium,
      ),
      dividerTheme: DividerThemeData(
        color: c.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: border(c.outlineVariant),
        enabledBorder: border(c.outlineVariant),
        focusedBorder: border(c.primary, 1.5),
        errorBorder: border(c.error),
        focusedErrorBorder: border(c.error, 1.5),
        labelStyle: text.bodyMedium?.copyWith(color: c.onSurfaceVariant),
        floatingLabelStyle: text.bodySmall?.copyWith(color: c.onSurfaceVariant),
        hintStyle: text.bodyMedium?.copyWith(
          color: c.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: c.error),
        prefixIconColor: c.onSurfaceVariant,
        suffixIconColor: c.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape: shape,
          elevation: 0,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 50),
          foregroundColor: c.onSurface,
          side: BorderSide(color: c.outline),
          shape: shape,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.onSurface,
          shape: shape,
          textStyle: text.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        elevation: 2,
        highlightElevation: 2,
        extendedTextStyle: text.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.onSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.surface),
        actionTextColor: c.primary,
        shape: shape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(color: c.outlineVariant),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.onSurfaceVariant),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        textStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          side: BorderSide(color: c.outlineVariant),
        ),
      ),
    );
  }
}
