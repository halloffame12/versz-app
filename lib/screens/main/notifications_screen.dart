import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/notification.dart';
import '../../providers/connection_provider.dart';
import '../../providers/notification_provider.dart' as notif_provider;
import '../../widgets/common/state_widgets.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notif_provider.notificationProvider.notifier).fetchUserNotifications();
    });
  }

  // Per-type: color, icon
  Color _typeColor(String type) {
    switch (type) {
      case 'connection_request': return AppColors.accentBlue;
      case 'connection_accepted': return AppColors.accentTeal;
      case 'follow': return AppColors.primaryYellow;
      case 'debate_comment': return AppColors.accentOrange;
      case 'debate_vote': return AppColors.accentTeal;
      case 'message': return AppColors.accentBlue;
      case 'achievement': return AppColors.primaryYellow;
      default: return AppColors.textMuted;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'connection_request': return Icons.person_add_alt_1_rounded;
      case 'connection_accepted': return Icons.handshake_rounded;
      case 'follow': return Icons.favorite_rounded;
      case 'debate_comment': return Icons.chat_bubble_rounded;
      case 'debate_vote': return Icons.how_to_vote_rounded;
      case 'message': return Icons.send_rounded;
      case 'achievement': return Icons.emoji_events_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'connection_request': return 'Connection Request';
      case 'connection_accepted': return 'Request Accepted';
      case 'follow': return 'New Follower';
      case 'debate_comment': return 'Commented on Your Debate';
      case 'debate_vote': return 'Voted on Your Debate';
      case 'message': return 'New Message';
      case 'achievement': return 'Achievement Unlocked';
      default: return 'Notification';
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notif_provider.notificationProvider);
    final unread = notificationState.unreadCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.backgroundColor(isDark);
    final cardBg = AppColors.cardBackground(isDark);
    final text = AppColors.textColor(isDark);

    return Scaffold(
      backgroundColor: bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            stretch: true,
            backgroundColor: bg,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: Navigator.of(context).canPop()
                ? IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: text, size: 20),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACTIVITY',
                    style: AppTextStyles.h2.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w900,
                      color: text,
                      fontSize: 22,
                    ),
                  ),
                  if (unread > 0)
                    Text(
                      '$unread new',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryYellow,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: bg),
                  Positioned(
                    right: -40,
                    top: -20,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.accentBlue.withValues(alpha: 0.12),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (unread > 0)
                TextButton.icon(
                  onPressed: () => ref.read(notif_provider.notificationProvider.notifier).markAllAsRead(),
                  icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.accentTeal),
                  label: Text(
                    'All read',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.accentTeal),
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
        ],
        body: notificationState.isLoading
            ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: LoadingSkeleton(itemCount: 5),
              )
            : notificationState.error != null
                ? ErrorStateWidget(
                    title: 'Couldn\'t load activity',
                    message: 'Unable to fetch your notifications.',
                    errorDetails: notificationState.error ?? 'Unknown error',
                    accentColor: AppColors.errorRed,
                    onRetry: () => ref.read(notif_provider.notificationProvider.notifier).fetchUserNotifications(),
                  )
                : notificationState.notifications.isEmpty
                    ? EmptyStateWidget(
                        title: 'All quiet for now',
                        subtitle: 'When people interact with your debates or profile, activity will show up here.',
                        icon: Icons.notifications_none_rounded,
                        iconColor: AppColors.accentBlue,
                      )
                    : RefreshIndicator(
                        color: AppColors.primaryYellow,
                      backgroundColor: cardBg,
                        onRefresh: () => ref.read(notif_provider.notificationProvider.notifier).fetchUserNotifications(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: notificationState.notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notificationState.notifications[index];
                            return _buildNotificationTile(notification);
                          },
                        ),
                      ),
      ),
    );
  }


  Widget _buildNotificationTile(VerszNotification notification) {
    final color = _typeColor(notification.type);
    final isUnread = !notification.isRead;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.cardBackground(isDark);
    final border = AppColors.borderColor(isDark);
    final text = AppColors.textColor(isDark);
    final muted = AppColors.mutedTextColor(isDark);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.4)),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_sweep_rounded, color: AppColors.errorRed),
      ),
      onDismissed: (_) => ref.read(notif_provider.notificationProvider.notifier).deleteNotification(notification.id),
      child: GestureDetector(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isUnread
                ? color.withValues(alpha: 0.07)
                : cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread ? color.withValues(alpha: 0.35) : border,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left color bar
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: isUnread ? color : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon container
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withValues(alpha: 0.3)),
                          ),
                          child: Icon(_typeIcon(notification.type), color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _typeLabel(notification.type),
                                      style: AppTextStyles.labelMedium.copyWith(
                                        fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                                        color: isUnread ? text : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    timeago.format(notification.createdAt),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.content,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (notification.type == 'connection_request' && notification.senderId != null) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: border),
                                          foregroundColor: AppColors.textSecondary,
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: () => _handleConnectionAction(notification, accept: false),
                                        child: const Text('Decline', style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.accentTeal,
                                          foregroundColor: AppColors.primaryBlack,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: () => _handleConnectionAction(notification, accept: true),
                                        child: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: AppColors.primaryYellow.withValues(alpha: 0.6), blurRadius: 6)],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleConnectionAction(VerszNotification notification, {required bool accept}) async {
    final senderId = notification.senderId;
    if (senderId == null) return;
    if (accept) {
      await ref.read(connectionProvider.notifier).acceptRequest(senderId);
    } else {
      await ref.read(connectionProvider.notifier).declineRequest(senderId);
    }
    await ref.read(notif_provider.notificationProvider.notifier).markAsRead(notification.id);
    await ref.read(notif_provider.notificationProvider.notifier).fetchUserNotifications();
  }

  Future<void> _handleNotificationTap(VerszNotification notification) async {
    if (!notification.isRead) {
      await ref.read(notif_provider.notificationProvider.notifier).markAsRead(notification.id);
    }
    if (!mounted) return;
    switch (notification.type) {
      case 'connection_request':
      case 'connection_accepted':
        context.push('/connections/pending');
        break;
      case 'follow':
        if (notification.senderId != null) context.push('/profile/${notification.senderId}');
        break;
      case 'message':
        context.push('/messages');
        break;
      default:
        break;
    }
  }
}
