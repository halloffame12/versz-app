import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_strings.dart';

class VerzLogo extends StatelessWidget {
  final double size;
  const VerzLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.22),
            gradient: AppColors.primaryGradient,
            border: Border.all(color: AppColors.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.16),
                blurRadius: 0,
                offset: const Offset(4, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'V',
              style: AppTextStyles.h1.copyWith(
                fontSize: size * 0.6,
                color: AppColors.surface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.appName,
          style: AppTextStyles.h1.copyWith(
            letterSpacing: 4,
          ),
        ),
        Text(
          AppStrings.appTagline.toUpperCase(),
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.accent,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
