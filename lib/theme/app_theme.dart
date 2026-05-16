// ============================================================
// RAWBY — Premium Design System
// OLED black + glassmorphism + electric green
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData build({
    required String mode,
    required String accent,
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

      scaffoldBackgroundColor: isDark ? const Color(0xFF080808) : RawbyPalette.lightBg,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
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

      // Primary buttons — glow effect built via decoration, not theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary.withValues(alpha: 0.6), width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: colors.primary.withValues(alpha: 0.04),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // Clean dark inputs — no yellow, no weird fills
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF111111) : const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RawbyPalette.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RawbyPalette.danger, width: 1.5),
        ),
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF555555) : const Color(0xFF999999),
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFF666666) : const Color(0xFF888888),
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

      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF141414) : RawbyPalette.lightCard,
        selectedColor: colors.primary.withValues(alpha: 0.15),
        labelStyle: TextStyle(
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
        iconColor: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
        textColor: isDark ? RawbyPalette.textDark : RawbyPalette.textLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        linearTrackColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE),
        linearMinHeight: 3,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFF111111),
        contentTextStyle: const TextStyle(
          color: Color(0xFFF5F5F5),
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        titleTextStyle: TextStyle(
          color: isDark ? RawbyPalette.textDark : RawbyPalette.textLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 0,
      ),

      textTheme: _buildTextTheme(isDark),

      iconTheme: IconThemeData(
        color: isDark ? const Color(0xFF777777) : const Color(0xFF999999),
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
      onSecondary: Colors.black,
      tertiary: const Color(0xFF7C4DFF),
      onTertiary: Colors.white,
      surface: const Color(0xFF080808),
      onSurface: const Color(0xFFF0F0F0),
      surfaceContainerHighest: const Color(0xFF141414),
      surfaceContainerHigh: const Color(0xFF111111),
      onSurfaceVariant: const Color(0xFF777777),
      outline: const Color(0xFF1F1F1F),
      outlineVariant: const Color(0xFF1A1A1A),
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
    final base = isDark ? const Color(0xFFF0F0F0) : RawbyPalette.textLight;
    final muted = isDark ? const Color(0xFF888888) : RawbyPalette.textMutedLight;

    return TextTheme(
      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: base, letterSpacing: -2, height: 1.05),
      displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: base, letterSpacing: -1.5, height: 1.1),
      displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: base, letterSpacing: -0.8, height: 1.15),
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: base, letterSpacing: -0.5, height: 1.2),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: base, letterSpacing: -0.3, height: 1.25),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: base, letterSpacing: -0.2, height: 1.3),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: base, letterSpacing: -0.1, height: 1.4),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: base, letterSpacing: 0, height: 1.4),
      titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: muted, letterSpacing: 0.1, height: 1.4),
      bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: base, height: 1.6),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: base, height: 1.55),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: muted, height: 1.5),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: base, letterSpacing: 0.1),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: muted, letterSpacing: 0.2),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: muted, letterSpacing: 0.8),
    );
  }
}

/// Spring-physics-feel page transition (like Framer Motion spring)
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
      curve: const Cubic(0.34, 1.56, 0.64, 1.0), // spring overshoot
    );
    final fadeOut = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeIn,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(spring),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.95).animate(fadeOut),
          child: child,
        ),
      ),
    );
  }
}
