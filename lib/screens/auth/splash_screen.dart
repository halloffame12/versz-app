import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  static const String _brand = 'VERSZ';
  late final AnimationController _pulseController;
  late final AnimationController _barController;
  bool _showTagline = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
    _init();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _barController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      await Future.delayed(const Duration(milliseconds: 850));
      if (mounted) {
        setState(() => _showTagline = true);
      }

      await Future.delayed(const Duration(milliseconds: 950));

      // Trigger auth check — the router's refreshListenable will handle
      // navigation automatically once authProvider emits the new state.
      await ref.read(authProvider.notifier).checkAuthStatus();
    } catch (e) {
      // checkAuthStatus handles its own errors; nothing to do here.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1 + (_pulseController.value * 0.04);
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_brand.length, (index) {
                        final begin = (index * 0.12).clamp(0.0, 1.0);
                        final end = (begin + 0.35).clamp(0.0, 1.0);
                        final opacity = CurvedAnimation(
                          parent: _pulseController,
                          curve: Interval(begin, end, curve: Curves.easeOut),
                        ).value;

                        return Opacity(
                          opacity: opacity,
                          child: Transform.translate(
                            offset: Offset(0, (1 - opacity) * 8),
                            child: Text(
                              _brand[index],
                              style: AppTextStyles.displayXL.copyWith(
                                fontSize: 64,
                                color: AppColors.electricYellow,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: _showTagline ? 1 : 0,
                    child: Text(
                      'Pick a Side.',
                      style: AppTextStyles.bodyL.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.mutedGray,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.68),
              child: SizedBox(
                width: 120,
                height: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Container(color: AppColors.darkBorder),
                      AnimatedBuilder(
                        animation: _barController,
                        builder: (context, child) {
                          final x = (_barController.value * 140) - 30;
                          return Transform.translate(
                            offset: Offset(x, 0),
                            child: child,
                          );
                        },
                        child: Container(
                          width: 30,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.electricYellow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
