import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';

class AuthCallbackScreen extends ConsumerStatefulWidget {
  final bool isSuccess;

  const AuthCallbackScreen({
    super.key,
    required this.isSuccess,
  });

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleCallback());
  }

  Future<void> _handleCallback() async {
    if (!widget.isSuccess) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign-in was cancelled or failed.')),
      );
      context.go('/login');
      return;
    }

    // Check current auth status
    await ref.read(authProvider.notifier).checkAuthStatus();
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isLoggedIn) {
      // User is authenticated, go to home
      context.go('/home');
    } else {
      // Auth failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error ?? 'Sign-in could not be completed.'),
        ),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}