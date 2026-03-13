import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/verz_button.dart';
import '../../widgets/common/verz_text_field.dart';
import '../../widgets/common/verz_logo.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please accept terms to continue.')),
        );
        return;
      }
      await ref.read(authProvider.notifier).signup(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _nameController.text.trim(),
          );
      
      if (mounted) {
        final state = ref.read(authProvider);
        if (state.status == AuthStatus.authenticated) {
          if (state.needsOnboarding) {
            context.go('/onboarding/username');
          } else {
            context.go('/home');
          }
        } else if (state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? AppStrings.somethingWentWrong),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            gradient: AppColors.darkGradient,
          ),
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const VerzLogo(size: 60),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.createAccount, style: AppTextStyles.h2),
                        const SizedBox(height: 8),
                        Text(AppStrings.joinVersz, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  VerzTextField(
                    label: AppStrings.displayName,
                    hintText: 'John Doe',
                    controller: _nameController,
                    validator: (v) => Validators.required(v, 'Name'),
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(height: 20),
                  VerzTextField(
                    label: AppStrings.email,
                    hintText: 'user@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(height: 20),
                  VerzTextField(
                    label: AppStrings.password,
                    hintText: '••••••••',
                    controller: _passwordController,
                    isPassword: true,
                    validator: Validators.password,
                    keyboardType: TextInputType.visiblePassword,
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _passwordController,
                    builder: (context, value, _) => _PasswordStrengthBar(password: value.text),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptedTerms,
                        onChanged: (value) {
                          setState(() {
                            _acceptedTerms = value ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'I agree to Terms and Privacy Policy',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  VerzButton(
                    text: 'Sign Up',
                    onPressed: _signup,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTextStyles.bodySmall,
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          'Login',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final String password;

  const _PasswordStrengthBar({required this.password});

  int _strength() {
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final score = _strength();
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.green,
    ];

    return Row(
      children: List.generate(4, (index) {
        final active = index < score;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
            decoration: BoxDecoration(
              color: active ? colors[index] : Colors.grey.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
