import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accentPurple,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.white,
      textTheme: _lightTextTheme(),
      appBarTheme: AppBarThemeData.light(),
      cardTheme: _lightCardTheme(),
      dividerTheme: const DividerThemeData(color: AppColors.mutedGray, thickness: 1),
      inputDecorationTheme: _inputTheme(isDark: false),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(isDark: false),
      textButtonTheme: _textButtonTheme(),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentPurple,
        linearMinHeight: 4,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,

      // Color scheme with new purple/indigo/cyan gradient theme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentPurple,
        onPrimary: AppColors.textPrimary,
        secondary: AppColors.accentIndigo,
        onSecondary: AppColors.textPrimary,
        tertiary: AppColors.accentCyan,
        error: AppColors.disagreeRed,
        onError: AppColors.textPrimary,
        surface: AppColors.darkCardBg,
        onSurface: AppColors.textPrimary,
        outline: AppColors.mutedGray,
      ),

      textTheme: _darkTextTheme(),

      appBarTheme: AppBarThemeData.dark(),

      elevatedButtonTheme: _elevatedButtonThemeDark(),
      outlinedButtonTheme: _outlinedButtonThemeDark(),
      textButtonTheme: _textButtonThemeDark(),
      inputDecorationTheme: _inputThemeDark(),
      cardTheme: _darkCardTheme(),
      dividerTheme: DividerThemeData(
        color: AppColors.mutedGray.withValues(alpha: 0.3),
        thickness: 1,
        space: 16,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16),
          ),
          side: BorderSide(color: AppColors.mutedGray, width: 1),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentPurple,
        linearMinHeight: 4,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
    );
  }

  static TextTheme _lightTextTheme() => TextTheme(
        displayLarge: AppTextStyles.displayXL,
        displayMedium: AppTextStyles.displayL,
        displaySmall: AppTextStyles.displayM,
        headlineLarge: AppTextStyles.headlineL,
        headlineMedium: AppTextStyles.headlineM,
        headlineSmall: AppTextStyles.headlineS,
        bodyLarge: AppTextStyles.bodyL,
        bodyMedium: AppTextStyles.bodyM,
        bodySmall: AppTextStyles.bodyS,
        labelLarge: AppTextStyles.labelL,
        labelMedium: AppTextStyles.labelM,
        labelSmall: AppTextStyles.labelS,
      );

  static TextTheme _darkTextTheme() => _lightTextTheme().apply(
        bodyColor: AppColors.darkText,
        displayColor: AppColors.darkText,
      );

  static CardThemeData _lightCardTheme() => CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.accentPurple, width: 2),
        ),
      );

  static CardThemeData _darkCardTheme() => CardThemeData(
        color: AppColors.darkCardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.accentIndigo, width: 1),
        ),
      );

  static InputDecorationTheme _inputTheme({required bool isDark}) => InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkCardBg : AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDark ? AppColors.accentIndigo : AppColors.voidBlack, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDark ? AppColors.accentIndigo : AppColors.voidBlack, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accentCyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.disagreeRed, width: 2),
        ),
        hintStyle: TextStyle(color: isDark ? AppColors.mutedGray : AppColors.textSecondary),
        labelStyle: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.voidBlack),
      );

  static InputDecorationTheme _inputThemeDark() => InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accentIndigo, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accentIndigo, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accentCyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.disagreeRed, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.mutedGray),
        labelStyle: const TextStyle(color: AppColors.textPrimary),
      );

  static ElevatedButtonThemeData _elevatedButtonTheme() => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPurple,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.accentPurple, width: 2),
          ),
          textStyle: AppTextStyles.headlineS.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      );

  static ElevatedButtonThemeData _elevatedButtonThemeDark() => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPurple,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.accentPurple, width: 2),
          ),
          textStyle: AppTextStyles.headlineS.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme({required bool isDark}) => OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppColors.textPrimary : AppColors.voidBlack,
          side: BorderSide(color: isDark ? AppColors.accentIndigo : AppColors.voidBlack, width: 2),
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonThemeDark() => OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.accentIndigo, width: 2),
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

  static TextButtonThemeData _textButtonTheme() => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentCyan,
          textStyle: AppTextStyles.bodyM.copyWith(color: AppColors.accentCyan),
        ),
      );

  static TextButtonThemeData _textButtonThemeDark() => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentCyan,
          textStyle: AppTextStyles.bodyM.copyWith(color: AppColors.accentCyan),
        ),
      );
}

class AppBarThemeData {
  static AppBarTheme light() => AppBarTheme(
    backgroundColor: AppColors.white,
    foregroundColor: AppColors.darkBackground,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: AppTextStyles.h3,
    toolbarHeight: 64,
    iconTheme: const IconThemeData(color: AppColors.darkBackground, size: 24),
    actionsIconTheme: const IconThemeData(color: AppColors.darkBackground, size: 24),
  );

  static AppBarTheme dark() => AppBarTheme(
    backgroundColor: AppColors.darkBackground,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: AppTextStyles.h3Dark(),
    toolbarHeight: 64,
    iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
    actionsIconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
  );
}
