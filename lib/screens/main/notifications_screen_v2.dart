import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class NotificationsScreenV2 extends ConsumerStatefulWidget {
  const NotificationsScreenV2({super.key});

  @override
  ConsumerState<NotificationsScreenV2> createState() => _NotificationsScreenV2State();
}

class _NotificationsScreenV2State extends ConsumerState<NotificationsScreenV2> with TickerProviderStateMixin {
  late AnimationController _listAnimation;

  @override
  void initState() {
    super.initState();
    _listAnimation = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _listAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.backgroundColor(isDark);
    final cardBg = AppColors.cardBackground(isDark);

    final notifications = [
      {
        'type': 'like',
        'icon': Icons.favorite_rounded,
        'color': Colors.red,
        'title': 'Alex liked your debate',
        'subtitle': '"Should AI have constitutional rights?"',
        'timestamp': '2m ago',
        'read': false,
      },
      {
        'type': 'follow',
        'icon': Icons.person_add_rounded,
        'color': AppColors.accentPurple,
        'title': 'Jordan started following you',
        'subtitle': 'Your profile attracted great interest',
        'timestamp': '15m ago',
        'read': false,
      },
      {
        'type': 'comment',
        'icon': Icons.comment_rounded,
        'color': AppColors.accentCyan,
        'title': 'Casey commented on your debate',
        'subtitle': 'Great point! I had the same thought...',
        'timestamp': '1h ago',
        'read': true,
      },
      {
        'type': 'connection',
        'icon': Icons.connect_without_contact_rounded,
        'color': AppColors.accentIndigo,
        'title': 'Morgan accepted your connection request',
        'subtitle': 'You are now connected',
        'timestamp': '3h ago',
        'read': true,
      },
      {
        'type': 'trending',
        'icon': Icons.trending_up_rounded,
        'color': Colors.green,
        'title': 'Your debate is trending',
        'subtitle': '"Is remote work the future?" has 1.2K views',
        'timestamp': '5h ago',
        'read': true,
      },
      {
        'type': 'badge',
        'icon': Icons.emoji_events_rounded,
        'color': Colors.amber,
        'title': 'New achievement: Debate Master',
        'subtitle': 'You\'ve won 10 debates in a row!',
        'timestamp': '1d ago',
        'read': true,
      },
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppColors.accentPurple, AppColors.accentIndigo, AppColors.accentCyan],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'NOTIFICATIONS',
            style: AppTextStyles.headlineL.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.accentIndigo.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'Mark all',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accentCyan,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final notif = notifications[index];
          final read = notif['read'] as bool;
          final color = notif['color'] as Color;
          final title = notif['title'] as String;
          final subtitle = notif['subtitle'] as String;
          final timestamp = notif['timestamp'] as String;
          final icon = notif['icon'] as IconData;

          return AnimatedBuilder(
            animation: _listAnimation,
            builder: (context, _) {
              final startTime = index * 0.08;
              final endTime = startTime + 0.3;
              final animProgress = _listAnimation.value;
              
              late double animValue;
              if (animProgress < startTime) {
                animValue = 0.0;
              } else if (animProgress > endTime) {
                animValue = 1.0;
              } else {
                animValue = ((animProgress - startTime) / (endTime - startTime));
                animValue = Curves.easeOut.transform(animValue);
              }

              return Transform.translate(
                offset: Offset(0, (1 - animValue) * 50),
                child: Opacity(
                  opacity: animValue,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: read
                          ? cardBg
                            : AppColors.accentPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: read
                              ? AppColors.accentIndigo.withValues(alpha: 0.3)
                              : AppColors.accentPurple.withValues(alpha: 0.5),
                          width: read ? 1 : 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withValues(alpha: 0.2),
                                  color.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: color.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.bodyM.copyWith(
                                          fontWeight: read ? FontWeight.w500 : FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyS.copyWith(
                                    color: AppColors.mutedGray,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  timestamp,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.mutedGray.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Unread indicator
                          if (!read)
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.accentPurple, AppColors.accentIndigo],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                        ],
                      ),
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
