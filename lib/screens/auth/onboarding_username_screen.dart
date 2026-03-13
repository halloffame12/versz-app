import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class OnboardingUsernameScreen extends ConsumerStatefulWidget {
  const OnboardingUsernameScreen({super.key});

  @override
  ConsumerState<OnboardingUsernameScreen> createState() => _OnboardingUsernameScreenState();
}

class _OnboardingUsernameScreenState extends ConsumerState<OnboardingUsernameScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  bool _isChecking = false;
  bool _isAvailable = false;
  String? _error;

  static final RegExp _usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,30}$');

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _error = null;
      _isAvailable = false;
    });

    if (!_usernameRegex.hasMatch(value.trim())) {
      setState(() {
        _error = 'Use 3-30 letters, numbers, or underscores only.';
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isChecking = true);
      final isAvailable = await ref.read(authProvider.notifier).isUsernameAvailable(value.trim());
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _isAvailable = isAvailable;
        _error = isAvailable ? null : 'Username already taken.';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _isAvailable && !_isChecking;

    return Scaffold(
      backgroundColor: VerszPalette.offWhite,
      appBar: AppBar(
        title: const Text('Choose Username'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your @username',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This helps others find and mention you.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              onChanged: _onChanged,
              decoration: InputDecoration(
                prefixText: '@',
                suffixIcon: _isChecking
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _controller.text.isEmpty
                        ? null
                        : Icon(
                            _isAvailable ? Icons.check_circle : Icons.cancel,
                            color: _isAvailable ? VerszPalette.green : VerszPalette.red,
                          ),
                errorText: _error,
                hintText: 'your_username',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Rules: 3-30 chars, letters, numbers, underscores only',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canContinue
                    ? () => context.push('/onboarding/interests', extra: _controller.text.trim().toLowerCase())
                    : null,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
