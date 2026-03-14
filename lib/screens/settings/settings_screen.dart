import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/appwrite_constants.dart';
import '../../core/services/appwrite_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final AppwriteService _appwrite = AppwriteService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  bool _isPrivate = false;
  String _messagingPrivacy = 'everyone';
  bool _pushDebates = true;
  bool _pushConnections = true;
  bool _pushMessages = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = ref.read(authProvider).user?.id;
      if (userId == null) {
        setState(() {
          _error = 'You are not logged in.';
          _isLoading = false;
        });
        return;
      }

      final response = await _appwrite.databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId,
      );

      final data = response.data;
      final rawPrefs = data['notif_prefs'];
      final prefs = rawPrefs is Map ? Map<String, dynamic>.from(rawPrefs) : <String, dynamic>{};

      setState(() {
        _isPrivate = (data['is_private'] ?? false) == true;
        final privacy = (data['messaging_privacy'] ?? 'everyone').toString();
        _messagingPrivacy = privacy == 'followers' ? 'followers' : 'everyone';
        _pushDebates = prefs['debates'] != false;
        _pushConnections = prefs['connections'] != false;
        _pushMessages = prefs['messages'] != false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load settings: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;

    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await _appwrite.databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId,
        data: {
          'is_private': _isPrivate,
          'messaging_privacy': _messagingPrivacy,
          'notif_prefs': {
            'debates': _pushDebates,
            'connections': _pushConnections,
            'messages': _pushMessages,
          },
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved.')),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
        _error = 'Failed to save settings: $e';
      });
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Settings',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.darkBorder),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow, strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.errorRed),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _sectionCard(
                  title: 'Privacy',
                  icon: Icons.shield_rounded,
                  color: AppColors.accentBlue,
                  children: [
                    _neonSwitch(
                      icon: Icons.lock_person_rounded,
                      title: 'Private Account',
                      subtitle: 'Only approved followers see your activity',
                      value: _isPrivate,
                      color: AppColors.accentBlue,
                      onChanged: (v) => setState(() => _isPrivate = v),
                    ),
                    const SizedBox(height: 4),
                    Container(height: 1, color: AppColors.darkBorder),
                    const SizedBox(height: 12),
                    Text(
                      'WHO CAN MESSAGE YOU',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _privacyChip('everyone', 'Everyone', AppColors.accentTeal),
                        const SizedBox(width: 10),
                        _privacyChip('followers', 'Followers only', AppColors.accentBlue),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  title: 'Notifications',
                  icon: Icons.notifications_rounded,
                  color: AppColors.accentOrange,
                  children: [
                    _neonSwitch(
                      icon: Icons.gavel_rounded,
                      title: 'Debate updates',
                      subtitle: 'Votes, comments on your debates',
                      value: _pushDebates,
                      color: AppColors.accentOrange,
                      onChanged: (v) => setState(() => _pushDebates = v),
                    ),
                    Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 4), color: AppColors.darkBorder),
                    _neonSwitch(
                      icon: Icons.people_rounded,
                      title: 'Connection requests',
                      subtitle: 'New followers and connections',
                      value: _pushConnections,
                      color: AppColors.primaryYellow,
                      onChanged: (v) => setState(() => _pushConnections = v),
                    ),
                    Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 4), color: AppColors.darkBorder),
                    _neonSwitch(
                      icon: Icons.chat_bubble_rounded,
                      title: 'Direct messages',
                      subtitle: 'DMs and group room messages',
                      value: _pushMessages,
                      color: AppColors.accentTeal,
                      onChanged: (v) => setState(() => _pushMessages = v),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  title: 'Appearance',
                  icon: Icons.palette_rounded,
                  color: AppColors.primaryYellow,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryYellow.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.dark_mode_rounded, color: AppColors.primaryYellow, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Theme', style: AppTextStyles.labelMedium),
                              Text(
                                'Always dark neon — built different',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryYellow.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryYellow.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'DARK',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primaryYellow,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Save button
                GestureDetector(
                  onTap: _isSaving ? null : _saveSettings,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: _isSaving
                          ? LinearGradient(colors: [AppColors.darkSurface, AppColors.darkSurface])
                          : const LinearGradient(
                              colors: [AppColors.primaryYellow, AppColors.accentOrange],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _isSaving
                          ? []
                          : [
                              BoxShadow(
                                color: AppColors.primaryYellow.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              )
                            ],
                    ),
                    child: Center(
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textMuted,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_rounded, color: AppColors.primaryBlack, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Save Changes',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.primaryBlack,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Log out button
                GestureDetector(
                  onTap: _logout,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.35)),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.logout_rounded, color: AppColors.errorRed, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Log Out',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.errorRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _privacyChip(String value, String label, Color color) {
    final selected = _messagingPrivacy == value;
    return GestureDetector(
      onTap: () => setState(() => _messagingPrivacy = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : AppColors.darkSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.6) : AppColors.darkBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? color : AppColors.textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _neonSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelMedium),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
            activeTrackColor: color.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.darkBorder,
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
