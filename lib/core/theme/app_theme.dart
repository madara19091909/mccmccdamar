import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color space = Color(0xFF070B1A);
  static const Color spaceSurface = Color(0xFF111833);
  static const Color violet = Color(0xFF8B7CFF);
  static const Color cyan = Color(0xFF4FE3D6);
  static const Color pink = Color(0xFFFF7AC6);
  static const Color gold = Color(0xFFFFC857);
}

class AppTheme {
  const AppTheme._();

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.violet,
      onPrimary: Color(0xFF0B0720),
      secondary: AppColors.cyan,
      onSecondary: Color(0xFF00201E),
      surface: AppColors.spaceSurface,
      onSurface: Color(0xFFEDEBFF),
      error: Color(0xFFFF6B6B),
    );
    return _build(scheme, AppColors.space);
  }

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: Color(0xFF5B4BDB),
      onPrimary: Colors.white,
      secondary: Color(0xFF0E9F94),
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF1B1840),
      error: Color(0xFFD6336C),
    );
    return _build(scheme, const Color(0xFFF4F2FF));
  }

  static ThemeData _build(ColorScheme scheme, Color background) {
    final radius = BorderRadius.circular(16);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: scheme.onSurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface.withValues(alpha: 0.94),
        indicatorColor: scheme.primary.withValues(alpha: 0.25),
        labelTextStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.onSurface.withValues(alpha: 0.07),
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        enabledBorder:
            OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );
  }
}
