import 'package:flutter/material.dart';

class AppColors {
  // Brand (subtle neo-brutalism)
  static const Color primary = Color(0xFF171717); // Ink
  static const Color accent = Color(0xFF2A8AF6); // Electric blue accent
  static const Color accentLight = Color(0xFF76B5FF);

  // Status
  static const Color success = Color(0xFF1E9E6E);
  static const Color error = Color(0xFFE14F4F);
  static const Color warning = Color(0xFFD79B2C);

  // Surfaces
  static const Color background = Color(0xFFF4F1E6); // Warm paper
  static const Color surface = Color(0xFFFFFCF3);
  static const Color surfaceLight = Color(0xFFEDE6D3);
  static const Color glassWhite = Color(0x26FFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF191919);
  static const Color textSecondary = Color(0xFF464646);
  static const Color textMuted = Color(0xFF747474);

  // Specialized
  static const Color agree = Color(0xFF1E9E6E);
  static const Color disagree = Color(0xFFE14F4F);

  // Gradients
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFFFFCF3), Color(0xFFF0E8D4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF232323), Color(0xFF111111)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x7AFFFFFF), Color(0x33FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF2A8AF6), Color(0xFF76B5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFFF4F1E6), Color(0xFFEDE6D3)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
