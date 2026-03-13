import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle get h1 => GoogleFonts.spaceGrotesk(
        fontSize: 32,
    fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
    letterSpacing: -0.8,
      );

  static TextStyle get h2 => GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
    letterSpacing: -0.4,
      );

  static TextStyle get h3 => GoogleFonts.spaceGrotesk(
        fontSize: 20,
    fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
    letterSpacing: -0.3,
      );

  static TextStyle get bodyLarge => GoogleFonts.manrope(
        fontSize: 16,
    fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.manrope(
        fontSize: 14,
    fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.manrope(
        fontSize: 12,
    fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelLarge => GoogleFonts.spaceGrotesk(
        fontSize: 14,
    fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMedium => GoogleFonts.spaceGrotesk(
        fontSize: 12,
    fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
    letterSpacing: 0.4,
      );

  static TextStyle get labelSmall => GoogleFonts.spaceGrotesk(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
    letterSpacing: 0.8,
      );
}
