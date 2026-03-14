import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email address.')),
      );
      return;
    }

    await ref.read(authProvider.notifier).sendPasswordRecovery(email);
    if (!mounted) return;

    final state = ref.read(authProvider);
    if (state.error == null) {
      setState(() => _sent = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: Text('Reset Password', style: AppTextStyles.headlineM.copyWith(color: AppColors.darkText)),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkText),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.darkBorder, width: 2),
            ),
            child: !_sent
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.lock_reset_rounded, size: 52, color: AppColors.electricYellow),
                      const SizedBox(height: 14),
                      Text(
                        'Forgot your password?',
                        style: AppTextStyles.headlineL.copyWith(color: AppColors.darkText),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We\'ll send you a reset link.',
                        style: AppTextStyles.bodyM.copyWith(color: AppColors.darkTextSub),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'you@example.com',
                          hintStyle: AppTextStyles.bodyS.copyWith(color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.accentCyan),
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
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: authState.isLoading ? null : _sendLink,
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text('Send Reset Link', style: AppTextStyles.headlineS.copyWith(color: AppColors.voidBlack)),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.mark_email_read_rounded, size: 52, color: AppColors.agreeGreen),
                      const SizedBox(height: 14),
                      Text(
                        'Check your email',
                        style: AppTextStyles.headlineL.copyWith(color: AppColors.darkText),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reset link sent to ${_emailController.text.trim()}',
                        style: AppTextStyles.bodyM.copyWith(color: AppColors.darkTextSub),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: _sendLink,
                        child: Text('Resend', style: AppTextStyles.headlineS.copyWith(color: AppColors.darkText)),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
