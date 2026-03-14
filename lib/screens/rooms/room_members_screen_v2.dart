import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/room.dart';

class RoomMembersScreenV2 extends ConsumerWidget {
  final Room room;

  const RoomMembersScreenV2({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.backgroundColor(isDark);
    final cardBg = AppColors.cardBackground(isDark);

    final members = [
      {'name': 'Alex Chen', 'username': '@alexchen', 'role': 'Admin', 'status': 'online', 'icon': '👨‍💼'},
      {'name': 'Jordan Smith', 'username': '@jordansmith', 'role': 'Moderator', 'status': 'online', 'icon': '👩‍💼'},
      {'name': 'Casey Davis', 'username': '@caseydavis', 'role': 'Member', 'status': 'offline', 'icon': '👨‍🎓'},
      {'name': 'Morgan Lee', 'username': '@morganlee', 'role': 'Member', 'status': 'online', 'icon': '👩‍🎓'},
      {'name': 'Riley Brown', 'username': '@rileybrown', 'role': 'Member', 'status': 'offline', 'icon': '👨‍🚀'},
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Icon(Icons.arrow_back_rounded, color: AppColors.accentCyan),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              room.name,
              style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            Text(
              '${members.length} members',
              style: AppTextStyles.bodyS.copyWith(color: AppColors.mutedGray),
            ),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final member = members[index];
          final isOnline = member['status'] == 'online';

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
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.accentPrimary, AppColors.accentPrimaryDark],
                                ),
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Center(
                                child: Text(member['icon'] as String, style: const TextStyle(fontSize: 28)),
                              ),
                            ),
                            if (isOnline)
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(color: cardBg, width: 2),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    member['name'] as String,
                                    style: AppTextStyles.bodyL.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: member['role'] == 'Admin'
                                          ? AppColors.accentPurple.withValues(alpha: 0.2)
                                          : AppColors.accentIndigo.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      member['role'] as String,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: member['role'] == 'Admin' ? Colors.purple : AppColors.accentIndigo,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                member['username'] as String,
                                style: AppTextStyles.bodyS.copyWith(color: AppColors.mutedGray),
                              ),
                            ],
                          ),
                        ),

                        // Status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? Colors.green.withValues(alpha: 0.1)
                                : AppColors.mutedGray.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isOnline
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : AppColors.mutedGray.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            isOnline ? 'Online' : 'Offline',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isOnline ? Colors.green : AppColors.mutedGray,
                              fontWeight: FontWeight.w600,
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
