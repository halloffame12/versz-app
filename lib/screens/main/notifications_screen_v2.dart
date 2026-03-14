import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/notification.dart';
import '../../providers/notification_provider.dart';

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

  /// Maps notification type string â†’ (icon, color).
  (IconData, Color) _iconForType(String type) {
    switch (type) {
      case 'like':
        return (Icons.favorite_rounded, AppColors.errorRed);
      case 'follow':
        return (Icons.person_add_rounded, AppColors.accentPrimary);
      case 'comment':
        return (Icons.comment_rounded, AppColors.accentPrimaryDark);
      case 'connection':
        return (Icons.connect_without_contact_rounded, AppColors.successGreen);
      case 'trending':
        return (Icons.trending_up_rounded, AppColors.successGreen);
      case 'achievement':
        return (Icons.emoji_events_rounded, Colors.amber);
      case 'vote':
        return (Icons.how_to_vote_rounded, AppColors.accentPrimary);
      case 'message':
        return (Icons.message_rounded, AppColors.accentPrimaryDark);
      default:
        return (Icons.notifications_rounded, AppColors.accentPrimary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.backgroundColor(isDark);
    final cardBg = AppColors.cardBackground(isDark);
    final notifState = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.accentLight, AppColors.accentPrimary],
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
          if (notifState.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: GestureDetector(
                  onTap: () => ref.read(notificationProvider.notifier).markAllAsRead(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.accentPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      'Mark all',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.accentPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: notifState.isLoading && notifState.notifications.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.accentPrimary,
                strokeWidth: 2,
              ),
            )
          : notifState.error != null && notifState.notifications.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.errorRed, size: 48),
                        const SizedBox(height: 12),
                        Text('Could not load notifications',
                            style: AppTextStyles.bodyM
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(notificationProvider.notifier)
                              .fetchUserNotifications(),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentPrimary),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : notifState.notifications.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_none_rounded,
                                color: AppColors.mutedGray, size: 64),
                            const SizedBox(height: 16),
                            Text('No notifications yet',
                                style: AppTextStyles.headlineS
                                    .copyWith(color: AppColors.textPrimary)),
                            const SizedBox(height: 8),
                            Text('Activity and updates will appear here',
                                style: AppTextStyles.bodyS
                                    .copyWith(color: AppColors.mutedGray)),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.accentPrimary,
                      backgroundColor: cardBg,
                      onRefresh: () => ref
                          .read(notificationProvider.notifier)
                          .fetchUserNotifications(),
                      child: ListView.separated(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        itemCount: notifState.notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _buildNotifTile(
                            context,
                            notifState.notifications[index],
                            index,
                            cardBg,
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildNotifTile(
    BuildContext context,
    VerszNotification notif,
    int index,
    Color cardBg,
  ) {
    final (icon, color) = _iconForType(notif.type);
    final read = notif.isRead;

    return AnimatedBuilder(
      animation: _listAnimation,
      builder: (context, _) {
        final startTime = (index * 0.08).clamp(0.0, 0.7);
        final endTime = (startTime + 0.3).clamp(0.0, 1.0);
        final animProgress = _listAnimation.value;

        double animValue;
        if (animProgress < startTime) {
          animValue = 0.0;
        } else if (animProgress > endTime) {
          animValue = 1.0;
        } else {
          animValue = (animProgress - startTime) / (endTime - startTime);
          animValue = Curves.easeOut.transform(animValue);
        }

        return Transform.translate(
          offset: Offset(0, (1 - animValue) * 50),
          child: Opacity(
            opacity: animValue.clamp(0.0, 1.0),
            child: GestureDetector(
              onTap: () {
                if (!read) {
                  ref.read(notificationProvider.notifier).markAsRead(notif.id);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: read
                      ? cardBg
                      : AppColors.accentPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: read
                        ? AppColors.darkBorder
                        : AppColors.accentPrimary.withValues(alpha: 0.4),
                    width: read ? 1 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notif.title.isNotEmpty ? notif.title : notif.type,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyM.copyWith(
                              fontWeight:
                                  read ? FontWeight.w500 : FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (notif.body.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              notif.body,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyS
                                  .copyWith(color: AppColors.mutedGray),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            timeago.format(notif.createdAt),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.mutedGray.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!read)
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accentPrimary,
                          shape: BoxShape.circle,
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
  }
}
