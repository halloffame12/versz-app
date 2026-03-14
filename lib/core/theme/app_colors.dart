import 'package:flutter/material.dart';

/// NEW MODERN GRADIENT THEME - PURPLE/INDIGO/CYAN
/// Primary colors with maximum contrast for readability
class AppColors {
  // *** PRIMARY BACKGROUND COLORS ***
  static const Color darkBackground = Color(0xFF0B0B0F); // Primary dark black
  static const Color darkBg = Color(0xFF0B0B0F); // Alias
  static const Color darkBg2 = Color(0xFF0D0D12); // Alternative dark black

  // *** CARD & SURFACE COLORS ***
  static const Color darkCardBg = Color(0xFF111827); // Dark slate for cards
  static const Color darkSurface = Color(0xFF1F2937); // Surface elements
  static const Color darkSurfaceHigh = Color(0xFF2D3748); // Higher surfaces

  // *** PRIMARY ACCENT COLORS - PURPLE/INDIGO GRADIENT ***
  static const Color accentPurple = Color(0xFF6C5CE7); // Purple - PRIMARY
  static const Color accentIndigo = Color(0xFF4F46E5); // Indigo - PRIMARY
  static const Color primaryPurple = Color(0xFF6C5CE7); // Alias
  static const Color royalBlue = Color(0xFF4F46E5); // Alias - Indigo

  // *** SECONDARY ACCENT - CYAN/BLUE GLOW ***
  static const Color accentCyan = Color(0xFF06B6D4); // Cyan - HIGHLIGHT
  static const Color accentBlue = Color(0xFF22D3EE); // Light cyan
  static const Color accentTeal = Color(0xFF0891B2); // Teal
  static const Color neonCyan = Color(0xFF06B6D4); // Bright cyan

  // *** TEXT COLORS - HIGH CONTRAST ***
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white
  static const Color textSecondary = Color(0xFF9CA3AF); // Muted gray
  static const Color textMuted = Color(0xFF6B7280); // More muted gray
  static const Color darkText = Color(0xFF0B0B0F); // For light backgrounds

  // *** STATUS COLORS ***
  static const Color successGreen = Color(0xFF10B981); // Green - Agree/Success
  static const Color agreeGreen = Color(0xFF10B981); // Agree side
  static const Color errorRed = Color(0xFFEF4444); // Red - Error/Disagree
  static const Color disagreeRed = Color(0xFFEF4444); // Disagree side
  static const Color warningOrange = Color(0xFFFB923C); // Warning
  static const Color aiPurple = Color(0xFF6C5CE7); // AI indicator

  // *** ALIASES FOR COMPATIBILITY ***
  static const Color primaryYellow = accentCyan; // Swap to cyan
  static const Color primaryBlack = darkBackground;
  static const Color voidBlack = darkBg2;
  static const Color electricYellow = accentCyan; // Legacy alias
  static const Color accentOrange = warningOrange;
  static const Color trendingRed = errorRed;

  // *** STATUS ALIASES ***
  static const Color success = successGreen;
  static const Color error = errorRed;
  static const Color warning = warningOrange;
  static const Color agree = agreeGreen;
  static const Color disagree = disagreeRed;

  // *** BORDERS & DIVIDERS ***
  static const Color darkBorder = Color(0xFF374151); // Subtle borders
  static const Color darkBorderHi = Color(0xFF4B5563); // Prominent borders
  static const Color borderGray = Color(0xFF374151); // Border color
  static const Color mutedGray = Color(0xFF6B7280); // Muted text

  // *** SURFACES ***
  static const Color surface = Color(0xFF1F2937); // Alternative surface
  static const Color background = darkBackground;
  static const Color card = darkCardBg;
  static const Color surfaceLight = Color(0xFF2A3142); // Subtle BG
  static const Color darkTextSub = Color(0xFF9CA3AF); // Subtext

  // *** CHROME/SPECIAL ACCENTS ***
  static const Color chromeGold = Color(0xFFDAA520); // Gold accent
  static const Color chromeSilver = Color(0xFFC0C0C0); // Silver accent
  static const Color chromeBronze = Color(0xFFCD7F32); // Bronze
  static const Color hotPink = Color(0xFFFF2D78); // Hot pink

  // *** LIGHT MODE COLORS ***
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF5F5F0);
  static const Color lightGray = Color(0xFFEEEEEE);
  static const Color mediumGray = Color(0xFFB0B0B0);
  static const Color inkBlack = Color(0xFF0B0B0F);

  // *** SEMANTIC ALIASES ***
  static const Color accent = accentPurple;
  static const Color primary = accentPurple;
  static const Color liked = errorRed;
  static const Color commented = accentCyan;
  static const Color saved = accentCyan;

  // *** GRADIENTS - MAIN THEME ***
  // Main gradient: Purple → Indigo → Cyan
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment(0, 0),
    end: Alignment(1, 1),
    colors: [accentPurple, accentIndigo, accentCyan],
  );

  // Linear gradient for bars/backgrounds
  static const LinearGradient primaryGradientLinear = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [accentPurple, accentIndigo],
  );

  // Hero gradient for buttons/highlights
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPurple, accentIndigo, accentCyan],
    stops: [0.0, 0.5, 1.0],
  );

  // Premium gradient
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPurple, accentIndigo, accentCyan],
  );

  // Accent gradient
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPurple, accentCyan],
  );

  // Warm gradient
  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warningOrange, errorRed],
  );

  // Background gradient
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBackground, darkBg2],
  );

  // *** THEME HELPERS ***
  static Color textColor(bool isDark) => isDark ? textPrimary : darkText;
  
  static Color backgroundColor(bool isDark) => isDark ? darkBackground : offWhite;
  
  static Color cardBackground(bool isDark) => isDark ? darkCardBg : white;
  
  static Color borderColor(bool isDark) => isDark ? darkBorder : borderGray;
  
  static Color mutedTextColor(bool isDark) => isDark ? textMuted : mutedGray;
  
  static Color opaque(Color color, double alpha) =>
      color.withValues(alpha: alpha);
}
