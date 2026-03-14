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
  RealtimeSubscription? _subscription;
  String? _currentUserId;

  NotificationNotifier(this._appwrite) : super(NotificationState()) {
    initialize();
  }

  Future<void> initialize() async {
    await _loadNotifications();
    await _subscribeToRealtime();
  }

  Future<void> _loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _appwrite.account.get();
      _currentUserId = user.$id;

      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.notificationsCollection,
        queries: [
          Query.equal('userId', user.$id),
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

  Future<void> _subscribeToRealtime() async {
    try {
      if (_currentUserId == null) {
        final user = await _appwrite.account.get();
        _currentUserId = user.$id;
      }

      _subscription?.close();
      final channel = 'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.notificationsCollection}.documents';
      _subscription = _appwrite.realtime.subscribe([channel]);
      _subscription!.stream.listen((event) {
        final payload = event.payload;
        if ((payload['userId']?.toString() ?? '') != _currentUserId) {
          return;
        }

        final notification = VerszNotification.fromMap(payload);
        final exists = state.notifications.any((n) => n.id == notification.id);
        List<VerszNotification> next;

        if (event.events.any((e) => e.contains('.delete'))) {
          next = state.notifications.where((n) => n.id != notification.id).toList();
        } else if (exists) {
          next = state.notifications
              .map((n) => n.id == notification.id ? notification : n)
              .toList();
        } else {
          next = [notification, ...state.notifications];
        }

        final unread = next.where((n) => !n.isRead).length;
        state = state.copyWith(notifications: next, unreadCount: unread);
      });
    } catch (_) {
      // Keep provider functional even if realtime subscription fails.
    }
  }

  // Public method for refreshing notifications from UI
  Future<void> fetchUserNotifications() async {
    await _loadNotifications();
  }

  Future<void> createNotification({
    required String userId,
    required String type,
    String? senderId,
    String? title,
    String? body,
    String? payload,
  }) async {
    try {
      await _appwrite.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.notificationsCollection,
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'senderId': senderId,
          'type': type,
          'title': title ?? '',
          'body': body ?? '',
          'payload': payload,
          'read': false,
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _appwrite.databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.notificationsCollection,
        documentId: notificationId,
        data: {'read': true},
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
          data: {'read': true},
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

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }
}