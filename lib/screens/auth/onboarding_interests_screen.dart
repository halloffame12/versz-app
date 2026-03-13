import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';

class OnboardingInterestsScreen extends ConsumerStatefulWidget {
  final String username;

  const OnboardingInterestsScreen({super.key, required this.username});

  @override
  ConsumerState<OnboardingInterestsScreen> createState() => _OnboardingInterestsScreenState();
}

class _OnboardingInterestsScreenState extends ConsumerState<OnboardingInterestsScreen> {
  final Set<String> _selected = <String>{};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(categoryProvider.notifier).fetchCategories());
  }

  Future<void> _complete() async {
    await ref.read(authProvider.notifier).completeOnboarding(
          username: widget.username,
          interests: _selected.toList(),
        );

    if (!mounted) return;
    final state = ref.read(authProvider);
    if (state.status == AuthStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: VerszPalette.red,
          content: Text(state.errorMessage ?? 'Something went wrong. Try again.'),
        ),
      );
      return;
    }

    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);
    final isBusy = categoryState.isLoading || ref.watch(authProvider).status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: VerszPalette.offWhite,
      appBar: AppBar(title: const Text('Pick Interests')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pick at least 3 interests',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'We use these to personalize your feed.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            if (categoryState.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (categoryState.categories.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No categories found. Pull to retry.'),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: categoryState.categories.map((category) {
                      final isSelected = _selected.contains(category.id);
                      return FilterChip(
                        selected: isSelected,
                        label: Text('${category.emoji} ${category.name}'),
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selected.add(category.id);
                            } else {
                              _selected.remove(category.id);
                            }
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: VerszPalette.yellow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: const BorderSide(color: VerszPalette.black, width: 2),
                        ),
                        checkmarkColor: VerszPalette.black,
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Selected: ${_selected.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selected.length >= 3 && !isBusy) ? _complete : null,
                child: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Finish'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
