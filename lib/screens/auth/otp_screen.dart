import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final TextEditingController _emailController = TextEditingController();
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    final pending = ref.read(authProvider).pendingOtpEmail;
    if (pending != null && pending.isNotEmpty) {
      _emailController.text = pending;
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    _emailController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  void _verifyOtp() async {
    if (_otpCode.length != 6 || int.tryParse(_otpCode) == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid 6-digit OTP code.')));
      return;
    }

    final notifier = ref.read(authProvider.notifier);
    await notifier.verifyOTP(_otpCode);

    if (mounted && ref.read(authProvider).isLoggedIn) {
      context.go('/home');
    }
  }

  Future<void> _requestOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email first')),
      );
      return;
    }

    final notifier = ref.read(authProvider.notifier);
    await notifier.createOTP(email);

    if (!mounted) return;
    _startResendCountdown();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _resendCountdown <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _resendCountdown--);
    });
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
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradientLinear,
                ),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Text('Versz',
                        style: AppTextStyles.h0.copyWith(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 8),
                    Text('Verify Your Email',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        )),
                  ],
                ),
              ),
              Container(
                color: isDark
                    ? AppColors.darkBackground
                    : AppColors.background,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Enter Code',
                        style: AppTextStyles.h2.copyWith(
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Email for OTP',
                        labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
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
                    const SizedBox(height: 8),
                    Text(
                      authState.pendingOtpEmail == null
                          ? 'Request a code first, then enter it below.'
                          : 'We sent a 6-digit code to ${authState.pendingOtpEmail}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.mutedGray : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (i) {
                        return SizedBox(
                          width: 50,
                          child: TextField(
                            controller: _otpControllers[i],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              counterText: '',
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            ),
                            onChanged: (val) {
                              if (val.isNotEmpty && i < 5) {
                                FocusScope.of(context).nextFocus();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),
                    if (authState.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withValues(alpha: 0.1),
                          border: Border.all(
                              color: AppColors.errorRed, width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(authState.error!,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.errorRed)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton(
                      onPressed: authState.isLoading
                        ? null
                        : (authState.pendingOtpEmail == null ? _requestOtp : _verifyOtp),
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                        : Text(
                          authState.pendingOtpEmail == null ? 'Send OTP Code' : 'Verify Code',
                          style: AppTextStyles.buttonLarge,
                        ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Text("Didn't receive code?",
                              style: AppTextStyles.bodySmall),
                          const SizedBox(height: 8),
                          if (_resendCountdown > 0)
                            Text('Resend in ${_resendCountdown}s',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.accentBlue))
                          else
                            GestureDetector(
                              onTap: _requestOtp,
                              child: Text(
                                'Request / Resend Code',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.accentBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
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
