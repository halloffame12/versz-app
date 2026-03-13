import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/appwrite_constants.dart';
import '../core/services/appwrite_service.dart';
import '../models/user_account.dart';

enum ConnectionStatus { none, follow, pending, connected, blocked }

class ConnectionState {
  final Map<String, ConnectionStatus> statusByUser;
  final Map<String, bool> pendingIncomingByUser;
  final List<UserAccount> connectedUsers;
  final List<UserAccount> receivedPendingUsers;
  final List<UserAccount> sentPendingUsers;
  final bool isLoading;
  final String? error;

  const ConnectionState({
    this.statusByUser = const {},
    this.pendingIncomingByUser = const {},
    this.connectedUsers = const [],
    this.receivedPendingUsers = const [],
    this.sentPendingUsers = const [],
    this.isLoading = false,
    this.error,
  });

  ConnectionState copyWith({
    Map<String, ConnectionStatus>? statusByUser,
    Map<String, bool>? pendingIncomingByUser,
    List<UserAccount>? connectedUsers,
    List<UserAccount>? receivedPendingUsers,
    List<UserAccount>? sentPendingUsers,
    bool? isLoading,
    String? error,
  }) {
    return ConnectionState(
      statusByUser: statusByUser ?? this.statusByUser,
      pendingIncomingByUser: pendingIncomingByUser ?? this.pendingIncomingByUser,
      connectedUsers: connectedUsers ?? this.connectedUsers,
      receivedPendingUsers: receivedPendingUsers ?? this.receivedPendingUsers,
      sentPendingUsers: sentPendingUsers ?? this.sentPendingUsers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final connectionProvider = StateNotifierProvider<ConnectionNotifier, ConnectionState>((ref) {
  return ConnectionNotifier(AppwriteService());
});

final connectionStatusProvider = Provider.family<ConnectionStatus, String>((ref, userId) {
  return ref.watch(connectionProvider).statusByUser[userId] ?? ConnectionStatus.none;
});

final connectionPendingIncomingProvider = Provider.family<bool, String>((ref, userId) {
  return ref.watch(connectionProvider).pendingIncomingByUser[userId] ?? false;
});

final pendingConnectionCountProvider = Provider<int>((ref) {
  return ref.watch(connectionProvider).receivedPendingUsers.length;
});

class ConnectionNotifier extends StateNotifier<ConnectionState> {
  final AppwriteService _appwrite;

  ConnectionNotifier(this._appwrite) : super(const ConnectionState());

  Future<void> fetchStatus(String otherUserId) async {
    try {
      final me = await _appwrite.account.get();
      final existing = await _findConnection(me.$id, otherUserId);

      final updated = Map<String, ConnectionStatus>.from(state.statusByUser);
      final incoming = Map<String, bool>.from(state.pendingIncomingByUser);

      if (existing == null) {
        updated[otherUserId] = ConnectionStatus.none;
        incoming[otherUserId] = false;
      } else {
        final status = _parseStatus(existing.data['status']?.toString());
        updated[otherUserId] = status;
        final receiverId = existing.data['receiverId']?.toString();
        incoming[otherUserId] = status == ConnectionStatus.pending && receiverId == me.$id;
      }

      state = state.copyWith(statusByUser: updated, pendingIncomingByUser: incoming, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> isConnectedWith(String otherUserId) async {
    try {
      final me = await _appwrite.account.get();
      final existing = await _findConnection(me.$id, otherUserId);
      if (existing == null) return false;
      return existing.data['status'] == 'connected';
    } catch (_) {
      return false;
    }
  }

  Future<void> follow(String otherUserId) async {
    await _upsertStatus(otherUserId, ConnectionStatus.follow);
  }

  Future<void> unfollow(String otherUserId) async {
    await _removeConnection(otherUserId);
  }

  Future<void> sendConnectionRequest(String otherUserId) async {
    await _upsertStatus(otherUserId, ConnectionStatus.pending);
  }

  Future<void> withdrawRequest(String otherUserId) async {
    await _removeConnection(otherUserId);
  }

  Future<void> acceptRequest(String otherUserId) async {
    final me = await _appwrite.account.get();
    final existing = await _findConnection(me.$id, otherUserId);
    if (existing == null) return;

    await _appwrite.databases.updateDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.connections,
      documentId: existing.$id,
      data: {
        'status': 'connected',
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );

    await fetchStatus(otherUserId);
    await fetchPendingRequests();
    await fetchConnectedUsers();
  }

  Future<void> declineRequest(String otherUserId) async {
    await _removeConnection(otherUserId);
    await fetchPendingRequests();
  }

  Future<void> blockUser(String otherUserId) async {
    await _upsertStatus(otherUserId, ConnectionStatus.blocked);
  }

  Future<void> removeConnection(String otherUserId) async {
    await _removeConnection(otherUserId);
    await fetchConnectedUsers();
  }

  Future<void> fetchConnectedUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final me = await _appwrite.account.get();
      final res = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.connections,
        queries: [
          Query.equal('status', 'connected'),
          Query.or([
            Query.equal('requesterId', me.$id),
            Query.equal('receiverId', me.$id),
          ]),
          Query.limit(100),
        ],
      );

      final users = <UserAccount>[];
      for (final doc in res.documents) {
        final requester = doc.data['requesterId']?.toString();
        final receiver = doc.data['receiverId']?.toString();
        final other = requester == me.$id ? receiver : requester;
        if (other == null) continue;
        final user = await _getUser(other);
        if (user != null) users.add(user);
      }

      state = state.copyWith(connectedUsers: users, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchPendingRequests() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final me = await _appwrite.account.get();
      final res = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.connections,
        queries: [
          Query.equal('status', 'pending'),
          Query.or([
            Query.equal('requesterId', me.$id),
            Query.equal('receiverId', me.$id),
          ]),
          Query.limit(100),
        ],
      );

      final received = <UserAccount>[];
      final sent = <UserAccount>[];

      for (final doc in res.documents) {
        final requester = doc.data['requesterId']?.toString();
        final receiver = doc.data['receiverId']?.toString();
        if (requester == null || receiver == null) continue;

        if (receiver == me.$id) {
          final user = await _getUser(requester);
          if (user != null) received.add(user);
        } else if (requester == me.$id) {
          final user = await _getUser(receiver);
          if (user != null) sent.add(user);
        }
      }

      state = state.copyWith(
        receivedPendingUsers: received,
        sentPendingUsers: sent,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _upsertStatus(String otherUserId, ConnectionStatus status) async {
    try {
      final me = await _appwrite.account.get();
      final existing = await _findConnection(me.$id, otherUserId);
      final statusString = _statusToString(status);

      if (existing == null) {
        await _appwrite.databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.connections,
          documentId: ID.unique(),
          data: {
            'requesterId': me.$id,
            'receiverId': otherUserId,
            'status': statusString,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
      } else {
        await _appwrite.databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.connections,
          documentId: existing.$id,
          data: {
            'status': statusString,
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
      }

      await fetchStatus(otherUserId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _removeConnection(String otherUserId) async {
    try {
      final me = await _appwrite.account.get();
      final existing = await _findConnection(me.$id, otherUserId);
      if (existing != null) {
        await _appwrite.databases.deleteDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.connections,
          documentId: existing.$id,
        );
      }

      final updated = Map<String, ConnectionStatus>.from(state.statusByUser);
      final incoming = Map<String, bool>.from(state.pendingIncomingByUser);
      updated[otherUserId] = ConnectionStatus.none;
      incoming[otherUserId] = false;
      state = state.copyWith(statusByUser: updated, pendingIncomingByUser: incoming, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<dynamic> _findConnection(String myId, String otherUserId) async {
    final res = await _appwrite.databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.connections,
      queries: [
        Query.or([
          Query.and([
            Query.equal('requesterId', myId),
            Query.equal('receiverId', otherUserId),
          ]),
          Query.and([
            Query.equal('requesterId', otherUserId),
            Query.equal('receiverId', myId),
          ]),
        ]),
        Query.limit(1),
      ],
    );

    if (res.documents.isEmpty) return null;
    return res.documents.first;
  }

  Future<UserAccount?> _getUser(String userId) async {
    try {
      final doc = await _appwrite.databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId,
      );
      return UserAccount.fromMap(doc.data);
    } catch (_) {
      return null;
    }
  }

  ConnectionStatus _parseStatus(String? status) {
    switch (status) {
      case 'follow':
        return ConnectionStatus.follow;
      case 'pending':
        return ConnectionStatus.pending;
      case 'connected':
        return ConnectionStatus.connected;
      case 'blocked':
        return ConnectionStatus.blocked;
      default:
        return ConnectionStatus.none;
    }
  }

  String _statusToString(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.follow:
        return 'follow';
      case ConnectionStatus.pending:
        return 'pending';
      case ConnectionStatus.connected:
        return 'connected';
      case ConnectionStatus.blocked:
        return 'blocked';
      case ConnectionStatus.none:
        return 'follow';
    }
  }
}