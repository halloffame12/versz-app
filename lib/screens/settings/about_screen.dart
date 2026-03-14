import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.accentCyan),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'About Versz',
          style: AppTextStyles.headlineS.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),

            // Logo / App branding
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentLight, AppColors.accentPrimary, AppColors.accentPrimaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPrimary.withValues(alpha: 0.5),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'V',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.accentLight, AppColors.accentPrimary],
              ).createShader(bounds),
              child: Text(
                'VERSZ',
                style: AppTextStyles.headlineL.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  fontSize: 32,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: AppTextStyles.bodyS.copyWith(color: AppColors.mutedGray),
            ),

            const SizedBox(height: 32),

            _buildSection(
              title: 'What is Versz?',
              body:
                  'Versz is a debate and discussion platform built for people who love exchanging ideas. Whether you\'re passionate about technology, politics, science, culture, or everyday life topics — Versz gives you a stage to voice your perspective, engage with opposing views, and grow your thinking.\n\nWe believe that respectful debate is one of the most powerful tools for personal growth and societal progress. Versz was designed to make that experience social, fun, and rewarding.',
            ),

            _buildSection(
              title: 'How It Works',
              body:
                  'Create a debate topic and choose a side. Others join in, vote, and comment. Every debate earns you XP — the more insightful and well-received your arguments, the more you level up.\n\nConnect with people who challenge your thinking. Follow great debaters, join live rooms, and climb the leaderboard to become a top ranked voice in your community.',
            ),

            _buildSection(
              title: 'Our Mission',
              body:
                  'We created Versz because the internet needed a space where disagreement is healthy, not toxic. A place where you can argue passionately about ideas — not attack people.\n\nOur mission is to foster a global community of curious, open-minded thinkers who use evidence, logic, and empathy to explore complex questions together.',
            ),

            _buildSection(
              title: 'Community Standards',
              body:
                  'Versz is only as good as the people in it. We ask every member to debate in good faith — attack arguments, never people. Hate speech, harassment, and misinformation are not allowed and will result in account action.\n\nWe trust our community to self-moderate and our AI moderation tools help flag problematic content quickly.',
            ),

            const SizedBox(height: 24),

            // Links
            _buildLinkTile(
              context,
              icon: Icons.shield_rounded,
              label: 'Privacy Policy',
              onTap: () => context.push('/privacy-policy'),
            ),
            _buildLinkTile(
              context,
              icon: Icons.gavel_rounded,
              label: 'Terms & Conditions',
              onTap: () => context.push('/terms'),
            ),
            _buildLinkTile(
              context,
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              onTap: () async {
                final uri = Uri.parse('mailto:support@versz.app');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Column(
                children: [
                  Text(
                    '© 2025 Versz. All rights reserved.',
                    style: AppTextStyles.bodyS.copyWith(color: AppColors.mutedGray),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Made with ❤️ for curious minds.',
                    style: AppTextStyles.bodyS.copyWith(color: AppColors.mutedGray),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headlineS.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Text(
              body,
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.textSecondary,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.darkCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accentCyan, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.mutedGray, size: 14),
          ],
        ),
      ),
    );
  }
}
