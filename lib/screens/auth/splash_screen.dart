import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/verz_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // Wait for a minimum duration to show the logo
      await Future.delayed(const Duration(seconds: 2));
      
      // Check if session exists
      await ref.read(authProvider.notifier).checkSession();
      
      if (mounted) {
        final authState = ref.read(authProvider);
        if (authState.status == AuthStatus.authenticated) {
          if (authState.needsOnboarding) {
            context.go('/onboarding/username');
          } else {
            context.go('/home');
          }
        } else {
          context.go('/login');
        }
      }
    } catch (e) {
      // If session check fails, go to login
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.darkGradient,
        ),
        child: const Center(
          child: VerzLogo(),
        ),
      ),
    );
  }
}
