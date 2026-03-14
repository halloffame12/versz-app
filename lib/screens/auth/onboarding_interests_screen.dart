import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class OnboardingInterestsScreen extends ConsumerStatefulWidget {
  final String username;
  const OnboardingInterestsScreen({super.key, this.username = 'user'});

  @override
  ConsumerState<OnboardingInterestsScreen> createState() => _OnboardingInterestsScreenState();
}

class _OnboardingInterestsScreenState extends ConsumerState<OnboardingInterestsScreen> {
  final List<String> categories = [
    'politics',
    'technology',
    'sports',
    'science',
    'entertainment',
    'philosophy',
    'health',
    'education',
    'business',
    'culture',
  ];

  late Set<String> selected;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    selected = {};
  }

  void _continue() async {
    if (selected.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least 3 interests')));
      return;
    }

    setState(() => _isSaving = true);
    final authState = ref.read(authProvider);
    final userId = authState.user?.id;

    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: User profile not loaded. Try logging in again.\nDebug: ${authState.user?.id ?? "null"}'),
          duration: const Duration(seconds: 5),
        ),
      );
      setState(() => _isSaving = false);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save selected interests
      await prefs.setStringList('selectedInterests_$userId', selected.toList());
      
      // Mark onboarding as complete - THIS IS CRITICAL FOR RETURNING USERS
      await prefs.setBool('onboardingComplete_$userId', true);
      await prefs.setBool('onboardingRequired_$userId', false);
      
      // Verify flag was set correctly
      final savedFlag = prefs.getBool('onboardingComplete_$userId');
      assert(savedFlag == true, 'Onboarding flag failed to persist');
      
      if (!mounted) return;
      setState(() => _isSaving = false);
      // Redirect to home - router will now recognize user as having completed onboarding
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving interests: $e')));
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradientLinear,
                ),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Text('What Interests You?', style: AppTextStyles.h1.copyWith(color: AppColors.primaryBlack)),
                    const SizedBox(height: 8),
                    Text(
                      'Pick at least 3 topics',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.primaryBlack.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBg : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Select Interests', style: AppTextStyles.h2),
                    const SizedBox(height: 8),
                    Text(
                      '${selected.length}/3 minimum selected',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: selected.length >= 3 ? AppColors.successGreen : AppColors.warningOrange,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: categories.map((category) {
                        final isSelected = selected.contains(category);
                        return FilterChip(
                          label: Text(
                            category[0].toUpperCase() + category.substring(1),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isSelected ? AppColors.primaryBlack : AppColors.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          backgroundColor: isDark ? AppColors.darkCardBg : AppColors.white,
                          selectedColor: AppColors.primaryYellow,
                          side: BorderSide(
                            color: isSelected ? AppColors.primaryYellow : AppColors.darkBorder,
                            width: 1.5,
                          ),
                          onSelected: (val) => setState(() => val ? selected.add(category) : selected.remove(category)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: (selected.length >= 3 && !_isSaving) ? _continue : null,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text("Let's Go!", style: AppTextStyles.buttonLarge),
                    ),
                  ],
                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
