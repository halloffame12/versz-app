import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../core/services/appwrite_service.dart';
import '../models/room.dart';
import '../core/constants/appwrite_constants.dart';
import 'package:appwrite/appwrite.dart';

final roomProvider = StateNotifierProvider<RoomNotifier, RoomState>((ref) {
  return RoomNotifier(AppwriteService());
});

class RoomState {
  final List<Room> rooms;
  final bool isLoading;
  final String? error;

  RoomState({
    this.rooms = const [],
    this.isLoading = false,
    this.error,
  });

  RoomState copyWith({
    List<Room>? rooms,
    bool? isLoading,
    String? error,
  }) {
    return RoomState(
      rooms: rooms ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class RoomNotifier extends StateNotifier<RoomState> {
  final AppwriteService _appwrite;
  RealtimeSubscription? _roomsSubscription;
  RealtimeSubscription? _membersSubscription;
  Timer? _realtimeRefreshDebounce;
  bool _refreshingFromRealtime = false;

  RoomNotifier(this._appwrite) : super(RoomState()) {
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    final roomsChannel =
        'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.roomsCollection}.documents';
    final membersChannel =
        'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.roomMembersCollection}.documents';

    _roomsSubscription = _appwrite.realtime.subscribe([roomsChannel]);
    _roomsSubscription!.stream.listen((_) => _scheduleRealtimeRefresh());

    _membersSubscription = _appwrite.realtime.subscribe([membersChannel]);
    _membersSubscription!.stream.listen((_) => _scheduleRealtimeRefresh());
  }

  void _scheduleRealtimeRefresh() {
    _realtimeRefreshDebounce?.cancel();
    _realtimeRefreshDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (_refreshingFromRealtime || state.isLoading) return;
      _refreshingFromRealtime = true;
      try {
        await fetchRooms();
      } finally {
        _refreshingFromRealtime = false;
      }
    });
  }

  Future<String?> currentUserId() async {
    try {
      final user = await _appwrite.account.get();
      return user.$id;
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchRooms() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomsCollection,
        queries: [
          Query.orderDesc('\$createdAt'),
          Query.limit(50),
        ],
      );
      final rooms = response.documents.map((doc) => Room.fromMap(doc.data)).toList();
      state = state.copyWith(rooms: rooms, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createRoom(Room room) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final created = await _appwrite.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomsCollection,
        documentId: ID.unique(),
        data: {
          'name': room.name,
          'description': room.description,
          'creatorId': room.creatorId,
          'avatar': room.iconUrl,
          'banner': room.bannerUrl,
          'memberCount': 1,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      await _appwrite.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomMembersCollection,
        documentId: ID.unique(),
        data: {
          'communityId': created.$id,
          'userId': room.creatorId,
          'role': 'admin',
          'status': 'active',
          'joinedAt': DateTime.now().toIso8601String(),
        },
      );

      await fetchRooms();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> joinRoom(String roomId) async {
    try {
      final me = await _appwrite.account.get();
      final existing = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomMembersCollection,
        queries: [
          Query.equal('communityId', roomId),
          Query.equal('userId', me.$id),
          Query.limit(1),
        ],
      );

      if (existing.documents.isNotEmpty) return;

      await _appwrite.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomMembersCollection,
        documentId: ID.unique(),
        data: {
          'communityId': roomId,
          'userId': me.$id,
          'role': 'member',
          'status': 'active',
          'joinedAt': DateTime.now().toIso8601String(),
        },
      );

      final room = await _appwrite.databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomsCollection,
        documentId: roomId,
      );

      final count = (room.data['memberCount'] ?? 0) as int;
      await _appwrite.databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomsCollection,
        documentId: roomId,
        data: {
          'memberCount': count + 1,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      await fetchRooms();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> leaveRoom(String roomId) async {
    try {
      final me = await _appwrite.account.get();

      final room = await _appwrite.databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomsCollection,
        documentId: roomId,
      );
      final creatorId = (room.data['creatorId'] ?? '').toString();
      if (creatorId == me.$id) {
        state = state.copyWith(error: 'Room creator cannot leave their own room.');
        return;
      }

      final existing = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomMembersCollection,
        queries: [
          Query.equal('communityId', roomId),
          Query.equal('userId', me.$id),
          Query.limit(1),
        ],
      );

      if (existing.documents.isEmpty) return;

      await _appwrite.databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomMembersCollection,
        documentId: existing.documents.first.$id,
      );

      final count = (room.data['memberCount'] ?? 0) as int;
      await _appwrite.databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomsCollection,
        documentId: roomId,
        data: {
          'memberCount': (count - 1).clamp(0, 9999999),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      await fetchRooms();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  @override
  void dispose() {
    _realtimeRefreshDebounce?.cancel();
    _roomsSubscription?.close();
    _membersSubscription?.close();
    super.dispose();
  }
}
