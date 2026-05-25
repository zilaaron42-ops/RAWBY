// ============================================================
// RAWBY — Theme System
// Builds ThemeData for light/dark × cinema/green/grey/basic
// Inter (body) + Playfair Display (display) via google_fonts.
// Spring page transitions for app-wide motion.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData build({
    required String mode, // 'light' or 'dark'
    required String accent, // 'cinema', 'green', 'grey', 'basic'
  }) {
    final isDark = mode == 'dark';
    final colors = AccentColors.forAccent(accent);
    final colorScheme = isDark ? _darkColorScheme(colors) : _lightColorScheme(colors);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: isDark ? Brightness.dark : Brightness.light,

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SpringPageTransitionsBuilder(),
          TargetPlatform.iOS: _SpringPageTransitionsBuilder(),
          TargetPlatform.fuchsia: _SpringPageTransitionsBuilder(),
          TargetPlatform.linux: _SpringPageTransitionsBuilder(),
          TargetPlatform.macOS: _SpringPageTransitionsBuilder(),
          TargetPlatform.windows: _SpringPageTransitionsBuilder(),
        },
      ),

      scaffoldBackgroundColor: colorScheme.surface,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),

      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF141414) : RawbyPalette.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? const Color(0xFF1F1F1F) : RawbyPalette.lightBorder,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary.withValues(alpha: 0.4), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? const Color(0xFF1A1B1F)
            : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? RawbyPalette.darkBorder : RawbyPalette.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? RawbyPalette.darkBorder : RawbyPalette.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: RawbyPalette.danger, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: isDark
              ? RawbyPalette.textMutedDark
              : RawbyPalette.textMutedLight,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: isDark
              ? RawbyPalette.textMutedDark
              : RawbyPalette.textMutedLight,
          fontSize: 14,
        ),
        prefixIconColor: isDark ? const Color(0xFF555555) : const Color(0xFF888888),
        suffixIconColor: isDark ? const Color(0xFF555555) : const Color(0xFF888888),
      ),

      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE),
        thickness: 1,
        space: 1,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark
            ? RawbyPalette.darkSurface.withValues(alpha: 0.92)
            : RawbyPalette.lightSurface.withValues(alpha: 0.92),
        selectedItemColor: colors.primary,
        unselectedItemColor: isDark
            ? RawbyPalette.textMutedDark
            : RawbyPalette.textMutedLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor:
            isDark ? RawbyPalette.darkSurface : RawbyPalette.lightSurface,
        selectedIconTheme: IconThemeData(color: colors.primary, size: 22),
        unselectedIconTheme: IconThemeData(
          color: isDark
              ? RawbyPalette.textMutedDark
              : RawbyPalette.textMutedLight,
          size: 22,
        ),
        selectedLabelTextStyle: GoogleFonts.inter(
          color: colors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          color: isDark
              ? RawbyPalette.textMutedDark
              : RawbyPalette.textMutedLight,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: colors.primary.withValues(alpha: 0.12),
        elevation: 0,
        minWidth: 72,
        minExtendedWidth: 200,
      ),

      chipTheme: ChipThemeData(
        backgroundColor:
            isDark ? RawbyPalette.darkCard : RawbyPalette.lightCard,
        selectedColor: colors.primary.withValues(alpha: 0.18),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          color: isDark ? RawbyPalette.textDark : RawbyPalette.textLight,
        ),
        side: BorderSide(
          color: isDark ? const Color(0xFF1F1F1F) : RawbyPalette.lightBorder,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: isDark
            ? RawbyPalette.textMutedDark
            : RawbyPalette.textMutedLight,
        textColor: isDark ? RawbyPalette.textDark : RawbyPalette.textLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.primary;
          return isDark ? const Color(0xFF333333) : const Color(0xFFCCCCCC);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primary.withValues(alpha: 0.4);
          }
          return isDark ? const Color(0xFF1F1F1F) : const Color(0xFFEEEEEE);
        }),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor:
            isDark ? RawbyPalette.darkBorder : RawbyPalette.lightBorder,
        linearMinHeight: 6,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? RawbyPalette.darkCard : RawbyPalette.textLight,
        contentTextStyle: GoogleFonts.inter(
          color: isDark ? RawbyPalette.textDark : RawbyPalette.lightBg,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor:
            isDark ? RawbyPalette.darkCard : RawbyPalette.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 12,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: isDark ? RawbyPalette.textDark : RawbyPalette.textLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      textTheme: _buildTextTheme(isDark),

      iconTheme: IconThemeData(
        color:
            isDark ? RawbyPalette.textMutedDark : RawbyPalette.textMutedLight,
        size: 20,
      ),
    );
  }

  static ColorScheme _darkColorScheme(AccentColors colors) {
    return ColorScheme.dark(
      primary: colors.primary,
      onPrimary: Colors.black,
      primaryContainer: colors.primaryDark,
      onPrimaryContainer: colors.onPrimary,
      secondary: colors.primaryLight,
      onSecondary: Colors.white,
      surface: const Color(0xFF0A0B0D),
      onSurface: RawbyPalette.textDark,
      surfaceContainerHighest: RawbyPalette.darkCard,
      onSurfaceVariant: RawbyPalette.textMutedDark,
      outline: RawbyPalette.darkBorder,
      outlineVariant: RawbyPalette.darkBorder.withValues(alpha: 0.5),
      error: RawbyPalette.danger,
      onError: Colors.white,
      shadow: Colors.black,
    );
  }

  static ColorScheme _lightColorScheme(AccentColors colors) {
    return ColorScheme.light(
      primary: colors.primary,
      onPrimary: Colors.black,
      primaryContainer: colors.primaryLight.withValues(alpha: 0.2),
      onPrimaryContainer: colors.primaryDark,
      secondary: colors.primaryLight,
      onSecondary: Colors.white,
      surface: RawbyPalette.lightBg,
      onSurface: RawbyPalette.textLight,
      surfaceContainerHighest: RawbyPalette.lightCard,
      onSurfaceVariant: RawbyPalette.textMutedLight,
      outline: RawbyPalette.lightBorder,
      outlineVariant: RawbyPalette.lightBorder.withValues(alpha: 0.5),
      error: RawbyPalette.danger,
      onError: Colors.white,
      shadow: Colors.black.withValues(alpha: 0.1),
    );
  }

  static TextTheme _buildTextTheme(bool isDark) {
    final baseColor = isDark ? RawbyPalette.textDark : RawbyPalette.textLight;
    final mutedColor = isDark
        ? RawbyPalette.textMutedDark
        : RawbyPalette.textMutedLight;
    final display = GoogleFonts.playfairDisplayTextTheme();
    final body = GoogleFonts.interTextTheme();

    return TextTheme(
      displayLarge: display.displayLarge!.copyWith(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: baseColor,
        letterSpacing: -1.5,
        height: 1.05,
      ),
      displayMedium: display.displayMedium!.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: baseColor,
        letterSpacing: -1.0,
        height: 1.1,
      ),
      displaySmall: display.displaySmall!.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineLarge: display.headlineLarge!.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: -0.4,
        height: 1.2,
      ),
      headlineMedium: body.headlineMedium!.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: baseColor,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      headlineSmall: body.headlineSmall!.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: baseColor,
        letterSpacing: -0.1,
        height: 1.35,
      ),
      titleLarge: body.titleLarge!.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: baseColor,
        letterSpacing: -0.1,
        height: 1.4,
      ),
      titleMedium: body.titleMedium!.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: 0.05,
        height: 1.4,
      ),
      titleSmall: body.titleSmall!.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: mutedColor,
        letterSpacing: 0.6,
        height: 1.4,
      ),
      bodyLarge: body.bodyLarge!.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.55,
      ),
      bodyMedium: body.bodyMedium!.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.5,
      ),
      bodySmall: body.bodySmall!.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mutedColor,
        height: 1.45,
      ),
      labelLarge: body.labelLarge!.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: baseColor,
        letterSpacing: 0.2,
      ),
      labelMedium: body.labelMedium!.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: mutedColor,
        letterSpacing: 0.3,
      ),
      labelSmall: body.labelSmall!.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: mutedColor,
        letterSpacing: 0.6,
      ),
    );
  }
}

/// Spring-physics overshoot transition. Smooth, slightly bouncy.
class _SpringPageTransitionsBuilder extends PageTransitionsBuilder {
  const _SpringPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final spring = CurvedAnimation(
      parent: animation,
      curve: const Cubic(0.34, 1.32, 0.64, 1.0),
    );
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(spring),
        child: child,
      ),
    );
  }
}
