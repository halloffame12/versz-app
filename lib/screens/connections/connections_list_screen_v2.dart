import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ConnectionsListScreenV2 extends ConsumerWidget {
  const ConnectionsListScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.backgroundColor(isDark);
    final cardBg = AppColors.cardBackground(isDark);

    final connections = [
      {'name': 'Alex Chen', 'username': '@alexchen', 'mutual': 23, 'status': 'connected'},
      {'name': 'Jordan Smith', 'username': '@jordansmith', 'mutual': 18, 'status': 'connected'},
      {'name': 'Casey Davis', 'username': '@caseydavis', 'mutual': 12, 'status': 'connected'},
      {'name': 'Morgan Lee', 'username': '@morganlee', 'mutual': 8, 'status': 'connected'},
      {'name': 'Riley Brown', 'username': '@rileybrown', 'mutual': 5, 'status': 'connected'},
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppColors.accentLight, AppColors.accentPrimary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'CONNECTIONS',
            style: AppTextStyles.headlineL.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        centerTitle: false,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Icon(Icons.arrow_back_rounded, color: AppColors.accentCyan),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        itemCount: connections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final conn = connections[index];

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 500 + (index * 100)),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, (1 - value) * 40),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accentIndigo.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.accentPrimary, AppColors.accentPrimaryDark],
                            ),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Center(
                            child: Text((index + 1).toString().padLeft(2, '0'), style: AppTextStyles.labelL.copyWith(color: AppColors.textPrimary)),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                conn['name'] as String,
                                style: AppTextStyles.bodyL.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    conn['username'] as String,
                                    style: AppTextStyles.bodyS.copyWith(color: AppColors.mutedGray),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentCyan.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${conn['mutual']} mutual',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.accentCyan,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Action
                        ScaleTransition(
                          scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: AlwaysStoppedAnimation(1.0),
                              curve: Curves.elasticOut,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accentCyan.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.accentCyan.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'Message',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.accentCyan,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
