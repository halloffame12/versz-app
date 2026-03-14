import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class OnboardingUsernameScreen extends ConsumerStatefulWidget {
  const OnboardingUsernameScreen({super.key});

  @override
  ConsumerState<OnboardingUsernameScreen> createState() => _OnboardingUsernameScreenState();
}

class _OnboardingUsernameScreenState extends ConsumerState<OnboardingUsernameScreen> {
  final _usernameController = TextEditingController();
  bool _isAvailable = false;
  bool _isChecking = false;
  String? _usernameError;
  Timer? _debounce;

  @override
  void dispose() {
    _usernameController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _checkUsername(String username) {
    final normalized = username.trim();
    _debounce?.cancel();

    if (normalized.length < 3) {
      setState(() {
        _isChecking = false;
        _isAvailable = false;
        _usernameError = 'Use at least 3 characters';
      });
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(normalized)) {
      setState(() {
        _isChecking = false;
        _isAvailable = false;
        _usernameError = 'Only letters, numbers, and underscores';
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() {
        _isChecking = true;
        _usernameError = null;
      });

      final notifier = ref.read(authProvider.notifier);
      final available = await notifier.checkUsernameAvailable(normalized.toLowerCase());

      if (!mounted) return;
      setState(() {
        _isAvailable = available;
        _isChecking = false;
        _usernameError = available ? null : 'Username is already taken';
      });
    });
  }

  void _continue() async {
    final username = _usernameController.text.trim().toLowerCase();
    if (!_isAvailable || username.isEmpty) return;

    final notifier = ref.read(authProvider.notifier);
    await notifier.setUsername(username);
    
    if (mounted && ref.read(authProvider).error == null) {
      context.go('/onboarding/interests', extra: username);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                color: AppColors.primaryYellow,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Text('Create Username', style: AppTextStyles.h1.copyWith(color: AppColors.primaryBlack)),
                    const SizedBox(height: 8),
                    Text('This is how people find you', style: AppTextStyles.bodyMedium.copyWith(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              Container(
                color: isDark ? AppColors.darkBackground : AppColors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Choose Username', style: AppTextStyles.h2),
                    const SizedBox(height: 8),
                    Text('3+ characters, letters and numbers only', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _usernameController,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        prefixText: '@',
                        filled: true,
                        fillColor: AppColors.darkSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.darkBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.darkBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentCyan, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: _checkUsername,
                    ),
                    const SizedBox(height: 16),
                    if (_isChecking)
                      Padding(padding: const EdgeInsets.all(8), child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                    else if (_usernameController.text.length >= 3)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Icon(_isAvailable ? Icons.check_circle : Icons.cancel, color: _isAvailable ? AppColors.successGreen : AppColors.errorRed),
                            const SizedBox(width: 8),
                            Text(
                              _isAvailable ? 'Username available' : (_usernameError ?? 'Username unavailable'),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: _isAvailable ? AppColors.successGreen : AppColors.errorRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),
                    if (authState.error != null && !authState.error!.contains('Username'))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.errorRed.withValues(alpha: 0.1), border: Border.all(color: AppColors.errorRed, width: 2), borderRadius: BorderRadius.circular(6)),
                          child: Text(authState.error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.errorRed)),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: (_isAvailable && !authState.isLoading) ? _continue : null,
                      child: authState.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text('Continue', style: AppTextStyles.buttonLarge),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
