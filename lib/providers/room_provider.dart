import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  RoomNotifier(this._appwrite) : super(RoomState());

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
      await _appwrite.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomsCollection,
        documentId: ID.unique(),
        data: {
          'name': room.name,
          'description': room.description,
          'creator_id': room.creatorId,
          'icon_url': room.iconUrl,
          'banner_url': room.bannerUrl,
          'members_count': 1, // Creator is first member
        },
      );
      await fetchRooms();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
