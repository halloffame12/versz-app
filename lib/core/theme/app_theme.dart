import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class VerszPalette {
  // Compatibility aliases for older screens.
  static const Color yellow = AppColors.accent;
  static const Color black = AppColors.primary;
  static const Color blue = AppColors.accent;
  static const Color white = AppColors.surface;
  static const Color offWhite = AppColors.background;
  static const Color body = AppColors.textPrimary;
  static const Color muted = AppColors.textMuted;
  static const Color red = AppColors.error;
  static const Color green = AppColors.success;
  static const Color orange = AppColors.warning;
}

class AppTheme {
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(14));

  static ThemeData light() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.surface,
        secondary: AppColors.accent,
        onSecondary: AppColors.surface,
        error: AppColors.error,
        onError: AppColors.surface,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.h1,
        headlineMedium: AppTextStyles.h2,
        titleLarge: AppTextStyles.h3,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: _radius,
          side: const BorderSide(color: AppColors.primary, width: 1.7),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: _radius,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.85), width: 1.6),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: AppColors.accent, width: 2),
        ),
        hintStyle: AppTextStyles.bodySmall,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(44, 44),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          textStyle: AppTextStyles.labelLarge,
          shape: const RoundedRectangleBorder(
            borderRadius: _radius,
            side: BorderSide(color: AppColors.primary, width: 1.7),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: _radius),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.surface),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData dark() {
    // Keep visual language consistent and accessible across modes.
    return light();
  }
}
