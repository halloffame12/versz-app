import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
          'Terms & Conditions',
          style: AppTextStyles.headlineS.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              'Terms & Conditions',
              'Effective Date: January 1, 2025 · Last Updated: March 2025',
            ),
            _buildSection(
              'Agreement to Terms',
              'By downloading, installing, or using the Versz application ("App"), you agree to be bound by these Terms and Conditions ("Terms"). If you do not agree, please do not use the App.\n\nVersz is provided by Versz Inc. ("Company," "we," "us," or "our"). We reserve the right to modify these Terms at any time.',
            ),
            _buildSection(
              '1. Eligibility',
              'You must be at least 13 years of age to use Versz. By using the App, you represent and warrant that:\n• You are at least 13 years old.\n• You have the legal capacity to enter into these Terms.\n• You will comply with all applicable laws in your jurisdiction.\n• You have not been previously banned from the platform.',
            ),
            _buildSection(
              '2. Your Account',
              'You are responsible for maintaining the confidentiality of your login credentials and for all activity that occurs under your account. You agree to:\n\n• Provide accurate and truthful information when creating your account.\n• Notify us immediately of any unauthorized use of your account.\n• Not share your account credentials with others.\n• Not create multiple accounts for the purpose of circumventing bans or restrictions.\n\nWe reserve the right to terminate accounts that violate these Terms.',
            ),
            _buildSection(
              '3. Acceptable Use',
              'You agree not to use Versz to:\n\n• Post hateful, threatening, harassing, or abusive content targeted at any individual or group.\n• Publish false or misleading information with the intent to deceive.\n• Spam, phish, or distribute malicious software.\n• Infringe the intellectual property rights of others.\n• Share explicit sexual content or graphic violence.\n• Engage in or promote illegal activities.\n• Impersonate others or misrepresent your identity.\n• Scrape, copy, or redistribute our content without permission.\n• Interfere with or disrupt the App\'s infrastructure.\n\nViolations may result in content removal, account suspension, or permanent ban.',
            ),
            _buildSection(
              '4. Content You Post',
              'You retain ownership of the content you create and share on Versz. By posting content, you grant us a worldwide, non-exclusive, royalty-free license to use, reproduce, process, and display your content for the purposes of operating and improving the Service.\n\nYou represent that you have all necessary rights to the content you post and that it does not violate any third-party rights.',
            ),
            _buildSection(
              '5. XP, Rankings & Leaderboards',
              'VerzXP Points ("XP") are earned through participation and are for entertainment and ranking purposes only. XP has no monetary value, cannot be exchanged for cash, and cannot be transferred between accounts.\n\nWe reserve the right to adjust, reset, or recalibrate XP calculations at any time to maintain fairness and accuracy.',
            ),
            _buildSection(
              '6. Intellectual Property',
              'All intellectual property in the App — including its design, code, branding, and original content — is owned by Versz Inc. and protected by applicable intellectual property laws.\n\nYou may not copy, modify, distribute, or create derivative works without our express written permission.',
            ),
            _buildSection(
              '7. Third-Party Services',
              'Versz integrates with third-party services (e.g., Appwrite, Firebase, Google). Your use of those services is subject to their respective terms of service and privacy policies. We are not responsible for third-party services.',
            ),
            _buildSection(
              '8. Disclaimer of Warranties',
              'VERSZ IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.\n\nWe do not guarantee that the App will be continuously available, error-free, or free of viruses.',
            ),
            _buildSection(
              '9. Limitation of Liability',
              'TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, VERSZ INC. SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING FROM YOUR USE OF OR INABILITY TO USE THE APP, EVEN IF WE HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.',
            ),
            _buildSection(
              '10. Governing Law',
              'These Terms shall be governed by and construed in accordance with the laws of the State of Delaware, United States, without regard to its conflict-of-law provisions. Any disputes shall be resolved through binding arbitration in accordance with the rules of the American Arbitration Association.',
            ),
            _buildSection(
              '11. Changes to Terms',
              'We may revise these Terms at any time. When we make material changes, we will notify you via the App and update the "Last Updated" date. Continued use of the App after changes constitutes your acceptance of the revised Terms.',
            ),
            _buildSection(
              '12. Contact',
              'For questions about these Terms, please contact us:\n\n📧 legal@versz.app\n🌐 versz.app/terms',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accentPurple.withValues(alpha: 0.2),
              AppColors.accentIndigo.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.gavel_rounded, color: AppColors.accentPurple, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headlineS.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyS.copyWith(color: AppColors.mutedGray),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headlineS.copyWith(
              color: AppColors.accentPurple,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: AppTextStyles.bodyM.copyWith(
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 4),
          Divider(color: AppColors.darkBorder, thickness: 1),
        ],
      ),
    );
  }
}
