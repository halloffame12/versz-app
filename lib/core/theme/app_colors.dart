import 'package:flutter/material.dart';

/// Versz production design palette.
/// Primary background: #FAF3E1
/// Secondary background: #F5E7C6
/// Accent: #FA8112
/// Text: #222222
class AppColors {
  // Core palette tokens
  static const Color pageBackground = Color(0xFFFAF3E1);
  static const Color surfaceBackground = Color(0xFFF5E7C6);
  static const Color accentPrimary = Color(0xFFFA8112);
  static const Color accentPrimaryDark = Color(0xFFD96B0C);
  static const Color textPrimary = Color(0xFF222222);
  static const Color textSecondary = Color(0xFF5E5548);
  static const Color textMuted = Color(0xFF7A6F5E);

  // Compatibility aliases used across legacy screens
  static const Color darkBackground = pageBackground;
  static const Color darkBg = pageBackground;
  static const Color darkBg2 = Color(0xFFF2E2BE);

  static const Color darkCardBg = surfaceBackground;
  static const Color darkSurface = Color(0xFFFFF7E9);
  static const Color darkSurfaceHigh = Color(0xFFFFFFFF);

  static const Color accentPurple = accentPrimary;
  static const Color accentIndigo = accentPrimaryDark;
  static const Color primaryPurple = accentPrimary;
  static const Color royalBlue = accentPrimaryDark;

  static const Color accentCyan = accentPrimary;
  static const Color accentBlue = accentPrimaryDark;
  static const Color accentTeal = accentPrimaryDark;
  static const Color neonCyan = accentPrimary;

  static const Color darkText = textPrimary;

  // Status colors
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color agreeGreen = successGreen;
  static const Color errorRed = Color(0xFFC62828);
  static const Color disagreeRed = errorRed;
  static const Color warningOrange = Color(0xFFEF6C00);
  static const Color aiPurple = accentPrimaryDark;

  // Additional aliases
  static const Color primaryYellow = accentPrimary;
  static const Color primaryBlack = textPrimary;
  static const Color voidBlack = textPrimary;
  static const Color electricYellow = accentPrimary;
  static const Color accentOrange = accentPrimary;
  static const Color trendingRed = errorRed;

  static const Color success = successGreen;
  static const Color error = errorRed;
  static const Color warning = warningOrange;
  static const Color agree = agreeGreen;
  static const Color disagree = disagreeRed;

  static const Color darkBorder = Color(0xFFD7C4A2);
  static const Color darkBorderHi = Color(0xFFCCB48B);
  static const Color borderGray = darkBorder;
  static const Color mutedGray = textMuted;

  static const Color surface = surfaceBackground;
  static const Color background = pageBackground;
  static const Color card = surfaceBackground;
  static const Color surfaceLight = Color(0xFFFFFAF0);
  static const Color darkTextSub = textSecondary;

  static const Color chromeGold = Color(0xFFB9842A);
  static const Color chromeSilver = Color(0xFF9E9E9E);
  static const Color chromeBronze = Color(0xFF8D5A2B);
  static const Color hotPink = Color(0xFFD81B60);

  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = pageBackground;
  static const Color lightGray = Color(0xFFEEE2C8);
  static const Color mediumGray = Color(0xFFB8A88A);
  static const Color inkBlack = textPrimary;

  static const Color accent = accentPrimary;
  static const Color primary = accentPrimary;
  static const Color liked = errorRed;
  static const Color commented = accentPrimary;
  static const Color saved = accentPrimary;

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFA344), accentPrimary],
  );

  static const LinearGradient primaryGradientLinear = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFB665), accentPrimary],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB665), accentPrimary, accentPrimaryDark],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient premiumGradient = heroGradient;

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB665), accentPrimary],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFC17B), warningOrange],
  );

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pageBackground, surfaceBackground],
  );

  static Color textColor(bool isDark) => textPrimary;

  static Color backgroundColor(bool isDark) => pageBackground;

  static Color cardBackground(bool isDark) => surfaceBackground;

  static Color borderColor(bool isDark) => darkBorder;

  static Color mutedTextColor(bool isDark) => textMuted;

  static Color opaque(Color color, double alpha) => color.withValues(alpha: alpha);
}
