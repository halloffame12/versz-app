import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
          style: AppTextStyles.headlineS.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              'Privacy Policy',
              'Effective Date: January 1, 2025 · Last Updated: March 2025',
            ),
            _buildSection(
              'Introduction',
              'Welcome to Versz ("we," "us," or "our"). We are committed to protecting your privacy and handling your personal information responsibly. This Privacy Policy explains how we collect, use, share, and safeguard information about you when you use our mobile application and related services (the "Service").\n\nBy using Versz, you agree to the collection and use of information as described in this policy.',
            ),
            _buildSection(
              '1. Information We Collect',
              '**Account Information:** When you create an account, we collect your email address, display name, username, and password (stored as a secure hash). You may optionally provide a profile photo, cover image, bio, and website link.\n\n**Usage Data:** We automatically collect information about how you use the Service — including debates you create or vote on, content you view, searches you perform, features you interact with, and time spent in the app.\n\n**Device Information:** We collect information about your device, including device type, operating system, app version, and a unique device identifier.\n\n**Communications:** When you send direct messages, we store the content of those messages to deliver them. Message content is not read by our staff except when investigating reported violations.\n\n**Push Notifications:** If you grant permission, we may collect device tokens to send you push notifications.',
            ),
            _buildSection(
              '2. How We Use Your Information',
              '• To create and manage your account.\n• To operate, maintain, and improve the Service.\n• To personalize your experience and content recommendations.\n• To communicate with you about your account, updates, and support.\n• To send push notifications if you opt in.\n• To calculate XP, rankings, and leaderboard positions.\n• To enforce our Community Standards and Terms of Service.\n• To conduct analytics to understand how users use the Service.\n• To comply with legal obligations.',
            ),
            _buildSection(
              '3. Information Sharing',
              'We do not sell your personal information.\n\nWe may share your information with:\n\n• **Service Providers:** Third-party vendors who assist us in operating the Service (e.g., Appwrite for backend infrastructure, Firebase for push notifications). These providers are contractually bound to handle data securely.\n\n• **Other Users:** Your public profile information (display name, username, bio, avatar, cover image, and public debate activity) is visible to other Versz users.\n\n• **Legal Authorities:** We may disclose information when required by law or to protect the safety of users or the public.',
            ),
            _buildSection(
              '4. Data Storage & Security',
              'Your data is stored on secure servers operated by Appwrite Cloud. We implement industry-standard security measures including encryption at rest and in transit (TLS/SSL).\n\nDespite our efforts, no security system is impenetrable. We encourage you to use a strong, unique password and to report any suspected security issues to security@versz.app.',
            ),
            _buildSection(
              '5. Your Rights & Choices',
              '• **Access & Correction:** You can view and update your profile information at any time from the Edit Profile screen.\n\n• **Deletion:** You can request deletion of your account and associated data by contacting support@versz.app. We will process requests within 30 days.\n\n• **Notification Preferences:** You can manage push and email notification preferences in the Settings screen.\n\n• **Profile Visibility:** You can set your profile to private in Settings to limit visibility to approved followers only.',
            ),
            _buildSection(
              '6. Children\'s Privacy',
              'Versz is not intended for users under the age of 13. We do not knowingly collect personal information from children under 13. If you believe we have inadvertently collected data from a child, please contact us immediately at privacy@versz.app and we will delete such information promptly.',
            ),
            _buildSection(
              '7. Cookies & Tracking',
              'Our mobile app does not use browser cookies. We may use similar technologies (local storage, device identifiers) to maintain your session and remember your preferences. We do not use third-party advertising trackers.',
            ),
            _buildSection(
              '8. Changes to This Policy',
              'We may update this Privacy Policy from time to time. When we do, we will update the "Last Updated" date at the top of this page and notify you via the app for material changes. Continued use of the Service after changes constitutes acceptance of the updated policy.',
            ),
            _buildSection(
              '9. Contact Us',
              'If you have questions or concerns about this Privacy Policy or our data practices, please contact us at:\n\n📧 privacy@versz.app\n🌐 versz.app/privacy',
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accentIndigo.withValues(alpha: 0.3),
                  AppColors.accentCyan.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded, color: AppColors.accentCyan, size: 28),
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
        ],
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
              color: AppColors.accentCyan,
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
