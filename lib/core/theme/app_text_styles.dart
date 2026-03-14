import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Versz V5 typography system.
class AppTextStyles {
  // Display
  static TextStyle get displayXL => GoogleFonts.spaceGrotesk(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get displayL => GoogleFonts.spaceGrotesk(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: AppColors.textPrimary,
      );

  static TextStyle get displayM => GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  // Headlines
  static TextStyle get headlineL => GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineM => GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineS => GoogleFonts.spaceGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // Body
  static TextStyle get bodyL => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyM => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyS => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.mutedGray,
      );

  // Labels
  static TextStyle get labelL => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: AppColors.mutedGray,
      );

  static TextStyle get labelM => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: AppColors.mutedGray,
      );

  static TextStyle get labelS => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: AppColors.mutedGray,
      );

  // Caps
  static TextStyle get capsL => GoogleFonts.spaceGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get capsM => GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
        color: AppColors.textPrimary,
      );

  // Mono
  static TextStyle get monoL => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get monoM => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get monoS => GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  // Compatibility aliases
  static TextStyle get h0 => displayXL;

  static TextStyle get h1 => GoogleFonts.spaceGrotesk(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle get h2 => GoogleFonts.spaceGrotesk(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle get h3 => GoogleFonts.spaceGrotesk(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get h4 => GoogleFonts.spaceGrotesk(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // ══════════════════════════════════════════════
  // BODY TEXT — Inter Regular/Medium
  // ══════════════════════════════════════════════
  
  static TextStyle get bodyLarge => bodyL;

  static TextStyle get bodyMedium => bodyM;

  static TextStyle get bodySmall => bodyS;

  // ══════════════════════════════════════════════
  // LABELS — Space Grotesk Bold with letter-spacing
  // ══════════════════════════════════════════════
  
  static TextStyle get labelLarge => labelL;

  static TextStyle get labelMedium => labelM;

  static TextStyle get labelSmall => labelS;

  static TextStyle get labelXSmall => GoogleFonts.spaceGrotesk(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.mutedGray,
    letterSpacing: 1.5,
    height: 1.2,
  );

  // ══════════════════════════════════════════════
  // BUTTON TEXT — Space Grotesk Bold
  // ══════════════════════════════════════════════
  
  static TextStyle get buttonLarge => GoogleFonts.spaceGrotesk(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get buttonMedium => GoogleFonts.spaceGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get buttonSmall => GoogleFonts.spaceGrotesk(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  // ══════════════════════════════════════════════
  // DARK MODE VARIANTS
  // ══════════════════════════════════════════════
  
  static TextStyle h1Dark() => h1.copyWith(color: AppColors.textPrimary);
  static TextStyle h2Dark() => h2.copyWith(color: AppColors.textPrimary);
  static TextStyle h3Dark() => h3.copyWith(color: AppColors.textPrimary);
  static TextStyle bodyLargeDark() => bodyLarge.copyWith(color: AppColors.textPrimary);
  static TextStyle bodyMediumDark() => bodyMedium.copyWith(color: AppColors.textPrimary);
  static TextStyle bodySmallDark() => bodySmall.copyWith(color: AppColors.mutedGray);
  static TextStyle labelLargeDark() => labelLarge.copyWith(color: AppColors.mutedGray);
}


