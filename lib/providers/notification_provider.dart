import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/appwrite_service.dart';
import '../core/constants/appwrite_constants.dart';
import '../models/notification.dart';
import 'package:appwrite/appwrite.dart';

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(AppwriteService());
});

class NotificationState {
  final List<VerszNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<VerszNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final AppwriteService _appwrite;

  NotificationNotifier(this._appwrite) : super(NotificationState()) {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _appwrite.account.get();

      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.notificationsCollection,
        queries: [
          Query.equal('user_id', user.$id),
          Query.orderDesc('\$createdAt'),
          Query.limit(50),
        ],
      );

      final notifications = response.documents.map((doc) => VerszNotification.fromMap(doc.data)).toList();
      final unreadCount = notifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Public method for refreshing notifications from UI
  Future<void> fetchUserNotifications() async {
    await _loadNotifications();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _appwrite.databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.notificationsCollection,
        documentId: notificationId,
        data: {'is_read': true},
      );

      // Update local state
      final updatedNotifications = state.notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
      state = state.copyWith(notifications: updatedNotifications, unreadCount: unreadCount);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final unreadNotifications = state.notifications.where((n) => !n.isRead).toList();

      for (final notification in unreadNotifications) {
        await _appwrite.databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.notificationsCollection,
          documentId: notification.id,
          data: {'is_read': true},
        );
      }

      final updatedNotifications = state.notifications.map((n) {
        return n.copyWith(isRead: true);
      }).toList();

      state = state.copyWith(notifications: updatedNotifications, unreadCount: 0);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _appwrite.databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.notificationsCollection,
        documentId: notificationId,
      );

      final updatedNotifications = state.notifications.where((n) => n.id != notificationId).toList();
      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
      state = state.copyWith(notifications: updatedNotifications, unreadCount: unreadCount);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}