import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/connection_provider.dart';
import '../../providers/notification_provider.dart' as notif_provider;
import '../../models/notification.dart';
import 'package:timeago/timeago.dart' as timeago;

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

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notif_provider.notificationProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.background.withValues(alpha: 0.8),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              title: Text(
                'NOTIFICATIONS',
                style: AppTextStyles.h2.copyWith(
                  letterSpacing: 4,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.premiumGradient,
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (notificationState.unreadCount > 0)
                IconButton(
                  icon: const Icon(Icons.done_all_rounded, color: Colors.white),
                  onPressed: () {
                    ref.read(notif_provider.notificationProvider.notifier).markAllAsRead();
                  },
                  tooltip: 'Mark all as read',
                ),
              const SizedBox(width: 8),
            ],
          ),
        ],
        body: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          child: notificationState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : notificationState.notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  itemCount: notificationState.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notificationState.notifications[index];
                    return _buildPremiumNotificationTile(notification);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceLight.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.2), width: 2),
              ),
              child: const Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            Text('No Notifications', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            Text(
              'You\'re all caught up! When people interact with you, it will show up here.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumNotificationTile(VerszNotification notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (direction) {
        ref.read(notif_provider.notificationProvider.notifier).deleteNotification(notification.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.transparent : AppColors.surfaceLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notification.isRead ? AppColors.surfaceLight.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.surface,
                  child: Icon(_getNotificationIcon(notification.type), color: AppColors.primary, size: 24),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 1),
                    ),
                    child: Icon(_getNotificationIcon(notification.type), size: 12, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _getNotificationTitle(notification.type),
                          style: AppTextStyles.labelLarge.copyWith(
                            fontSize: 16,
                            fontWeight: notification.isRead ? FontWeight.bold : FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(notification.createdAt),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: notification.isRead ? AppColors.textMuted : AppColors.primary,
                          fontSize: 10,
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.content,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: notification.isRead ? AppColors.textSecondary : Colors.white,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_isConnectionRequest(notification) && notification.senderId != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => _handleConnectionAction(notification, accept: false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.textMuted),
                            foregroundColor: AppColors.textSecondary,
                          ),
                          child: const Text('Decline'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _handleConnectionAction(notification, accept: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.background,
                          ),
                          child: const Text('Accept'),
                        ),
                      ],
                    ),
                  ],
                  if (_isConnectionAccepted(notification) && notification.senderId != null) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        context.push('/messages');
                      },
                      icon: const Icon(Icons.message_rounded, size: 16),
                      label: const Text('Message'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!notification.isRead) ...[
              const SizedBox(width: 12),
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.primary, blurRadius: 4, spreadRadius: 0),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getNotificationTitle(String type) {
    switch (type) {
      case 'connection_request':
        return 'Connection Request';
      case 'connection_accepted':
        return 'Request Accepted';
      case 'debate_comment':
        return 'New Comment';
      case 'comment_upvote':
        return 'Comment Liked';
      case 'debate_upvote':
        return 'Debate Upvoted';
      case 'message':
        return 'New Message';
      case 'follow':
        return 'New Follower';
      default:
        return 'Notification';
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'connection_request':
        return Icons.person_add_alt_1_rounded;
      case 'connection_accepted':
        return Icons.handshake_rounded;
      case 'debate_comment':
        return Icons.comment;
      case 'comment_upvote':
        return Icons.thumb_up;
      case 'debate_upvote':
        return Icons.trending_up;
      case 'message':
        return Icons.message;
      case 'follow':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  bool _isConnectionRequest(VerszNotification notification) {
    return notification.type == 'connection_request';
  }

  bool _isConnectionAccepted(VerszNotification notification) {
    return notification.type == 'connection_accepted';
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
}
