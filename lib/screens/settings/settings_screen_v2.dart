import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

const _pushEnabledKey = 'settings_push_enabled';
const _emailEnabledKey = 'settings_email_enabled';
const _messageEnabledKey = 'settings_message_enabled';
const _debateEnabledKey = 'settings_debate_enabled';

class SettingsScreenV2 extends ConsumerStatefulWidget {
  const SettingsScreenV2({super.key});

  @override
  ConsumerState<SettingsScreenV2> createState() => _SettingsScreenV2State();
}

class _SettingsScreenV2State extends ConsumerState<SettingsScreenV2> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _messageEnabled = true;
  bool _debateEnabled = true;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pushEnabled = prefs.getBool(_pushEnabledKey) ?? true;
      _emailEnabled = prefs.getBool(_emailEnabledKey) ?? true;
      _messageEnabled = prefs.getBool(_messageEnabledKey) ?? true;
      _debateEnabled = prefs.getBool(_debateEnabledKey) ?? true;
      _prefsLoaded = true;
    });
  }

  Future<void> _setBoolPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _setTheme(ThemeMode mode) async {
    await ref.read(themeModeProvider.notifier).setThemeMode(mode);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Theme changed to ${_themeLabel(mode)}.')),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.backgroundColor(isDark);
    final cardBg = AppColors.cardBackground(isDark);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          'Settings',
          style: AppTextStyles.headlineM.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: !_prefsLoaded
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.accentCyan,
                strokeWidth: 2,
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.accentIndigo.withValues(alpha: 0.2),
                        backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                            ? Text(
                                (user?.displayName ?? 'U').substring(0, 1).toUpperCase(),
                                style: AppTextStyles.headlineS.copyWith(color: AppColors.textPrimary),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Versz User',
                              style: AppTextStyles.bodyL.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@${user?.username ?? 'user'}',
                              style: AppTextStyles.bodyS.copyWith(color: AppColors.mutedGray),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => context.push('/edit-profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentCyan,
                          side: const BorderSide(color: AppColors.accentCyan),
                        ),
                        child: const Text('Edit'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _sectionTitle('Account'),
                _tile(
                  icon: Icons.person_rounded,
                  label: 'Edit Profile',
                  subtitle: 'Update your photo, banner and personal details',
                  onTap: () => context.push('/edit-profile'),
                ),
                _tile(
                  icon: Icons.people_alt_rounded,
                  label: 'Connections',
                  subtitle: 'See your followers, friends and pending requests',
                  onTap: () => context.push('/connections'),
                ),
                _tile(
                  icon: Icons.lock_rounded,
                  label: 'Change Password',
                  subtitle: 'Open the recovery flow for password reset',
                  onTap: () => context.push('/forgot'),
                ),
                const SizedBox(height: 20),
                _sectionTitle('Notifications'),
                _switchTile(
                  icon: Icons.notifications_active_rounded,
                  label: 'Push Notifications',
                  subtitle: 'Alerts for mentions, activity and invites',
                  value: _pushEnabled,
                  onChanged: (value) async {
                    setState(() => _pushEnabled = value);
                    await _setBoolPref(_pushEnabledKey, value);
                  },
                ),
                _switchTile(
                  icon: Icons.mail_rounded,
                  label: 'Email Updates',
                  subtitle: 'Important account and summary emails',
                  value: _emailEnabled,
                  onChanged: (value) async {
                    setState(() => _emailEnabled = value);
                    await _setBoolPref(_emailEnabledKey, value);
                  },
                ),
                _switchTile(
                  icon: Icons.message_rounded,
                  label: 'Message Alerts',
                  subtitle: 'Unread direct messages and replies',
                  value: _messageEnabled,
                  onChanged: (value) async {
                    setState(() => _messageEnabled = value);
                    await _setBoolPref(_messageEnabledKey, value);
                  },
                ),
                _switchTile(
                  icon: Icons.how_to_vote_rounded,
                  label: 'Debate Activity',
                  subtitle: 'Votes, comments and debate momentum',
                  value: _debateEnabled,
                  onChanged: (value) async {
                    setState(() => _debateEnabled = value);
                    await _setBoolPref(_debateEnabledKey, value);
                  },
                ),
                const SizedBox(height: 20),
                _sectionTitle('Appearance'),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.dark_mode_rounded, color: AppColors.accentCyan),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Theme Mode',
                                  style: AppTextStyles.bodyM.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Current: ${_themeLabel(themeMode)}',
                                  style: AppTextStyles.bodyS.copyWith(color: AppColors.mutedGray),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _themeChoice('System', ThemeMode.system, themeMode),
                          _themeChoice('Dark', ThemeMode.dark, themeMode),
                          _themeChoice('Light', ThemeMode.light, themeMode),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _sectionTitle('App'),
                _tile(
                  icon: Icons.info_outline_rounded,
                  label: 'About Versz',
                  subtitle: 'What the app is about and how it works',
                  onTap: () => context.push('/about'),
                ),
                _tile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  subtitle: 'How your data is collected and used',
                  onTap: () => context.push('/privacy-policy'),
                ),
                _tile(
                  icon: Icons.gavel_rounded,
                  label: 'Terms & Conditions',
                  subtitle: 'Rules and terms for using Versz',
                  onTap: () => context.push('/terms'),
                ),
                _tile(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  subtitle: 'Contact support@versz.app for help',
                  onTap: () => _showInfo('Email support@versz.app for account or app help.'),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (!context.mounted) return;
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorRed.withValues(alpha: 0.18),
                      foregroundColor: AppColors.errorRed,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log Out'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelL.copyWith(
          color: AppColors.mutedGray,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.cardBackground(isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.accentIndigo.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.accentCyan),
        ),
        title: Text(
          label,
          style: AppTextStyles.bodyM.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodyS.copyWith(color: AppColors.mutedGray),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.mutedGray, size: 16),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.cardBackground(isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accentIndigo.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.accentCyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyM.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyS.copyWith(color: AppColors.mutedGray),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accentCyan,
            activeTrackColor: AppColors.accentCyan.withValues(alpha: 0.35),
            inactiveThumbColor: AppColors.mutedGray,
            inactiveTrackColor: AppColors.darkSurface,
          ),
        ],
      ),
    );
  }

  Widget _themeChoice(String label, ThemeMode mode, ThemeMode currentMode) {
    final selected = currentMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.cardBackground(isDark);

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _setTheme(mode),
      labelStyle: AppTextStyles.bodyS.copyWith(
        color: selected ? AppColors.textPrimary : AppColors.mutedGray,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: AppColors.accentPurple.withValues(alpha: 0.22),
      backgroundColor: cardBg,
      side: BorderSide(
        color: selected ? AppColors.accentCyan : AppColors.darkBorder,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }
}
