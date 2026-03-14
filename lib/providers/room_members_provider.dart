import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_account.dart';
import '../core/services/appwrite_service.dart';
import '../core/constants/appwrite_constants.dart';
import 'package:appwrite/appwrite.dart';

final roomMembersProvider = StateNotifierProvider.family<RoomMembersNotifier, RoomMembersState, String>(
  (ref, roomId) {
    return RoomMembersNotifier(AppwriteService(), roomId);
  },
);

class RoomMembersState {
  final List<UserAccount> members;
  final bool isLoading;
  final String? error;
  final int totalCount;

  RoomMembersState({
    this.members = const [],
    this.isLoading = false,
    this.error,
    this.totalCount = 0,
  });

  RoomMembersState copyWith({
    List<UserAccount>? members,
    bool? isLoading,
    String? error,
    int? totalCount,
  }) {
    return RoomMembersState(
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class RoomMembersNotifier extends StateNotifier<RoomMembersState> {
  final AppwriteService _appwrite;
  final String _roomId;

  RoomMembersNotifier(this._appwrite, this._roomId) : super(RoomMembersState()) {
    _loadMembers();
  }

  Future<void> fetchMembers() async {
    await _loadMembers();
  }

  Future<void> _loadMembers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomMembersCollection,
        queries: [
          Query.equal('communityId', _roomId),
          Query.limit(100),
        ],
      );

      final memberIds = response.documents.map((doc) => doc.data['userId'] as String).toList();
      
      // Fetch user profiles
      final members = <UserAccount>[];
      for (final memberId in memberIds) {
        try {
          final profile = await _appwrite.databases.getDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.usersCollection,
            documentId: memberId,
          );
          members.add(UserAccount.fromMap(profile.data));
        } catch (e) {
          // User profile not found
        }
      }

      state = state.copyWith(
        members: members,
        totalCount: memberIds.length,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addMember(String userId) async {
    try {
      final existing = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomMembersCollection,
        queries: [
          Query.equal('communityId', _roomId),
          Query.equal('userId', userId),
          Query.limit(1),
        ],
      );
      if (existing.documents.isNotEmpty) {
        await _loadMembers();
        return;
      }

      await _appwrite.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomMembersCollection,
        documentId: ID.unique(),
        data: {
          'communityId': _roomId,
          'userId': userId,
          'role': 'member',
          'status': 'active',
          'joinedAt': DateTime.now().toIso8601String(),
        },
      );

      // Update room member count
      final room = await _appwrite.databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomsCollection,
        documentId: _roomId,
      );

      final memberCount = (room.data['memberCount'] ?? 0) as int;
      await _appwrite.databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomsCollection,
        documentId: _roomId,
        data: {'memberCount': memberCount + 1},
      );

      await _loadMembers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeMember(String userId) async {
    try {
      // Find and delete the member record
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomMembersCollection,
        queries: [
          Query.equal('communityId', _roomId),
          Query.equal('userId', userId),
        ],
      );

      if (response.documents.isNotEmpty) {
        await _appwrite.databases.deleteDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.roomMembersCollection,
          documentId: response.documents.first.$id,
        );

        // Update room member count
        final room = await _appwrite.databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.roomsCollection,
          documentId: _roomId,
        );

        final memberCount = (room.data['memberCount'] ?? 0) as int;
        await _appwrite.databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.roomsCollection,
          documentId: _roomId,
          data: {'memberCount': (memberCount - 1).clamp(0, 9999999)},
        );

        await _loadMembers();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<List<UserAccount>> searchUsers(String query, {int limit = 20}) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    try {
      final res1 = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        queries: [Query.search('username', q), Query.limit(limit)],
      );

      dynamic res2;
      try {
        res2 = await _appwrite.databases.listDocuments(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollection,
          queries: [Query.search('display_name', q), Query.limit(limit)],
        );
      } catch (_) {
        res2 = null;
      }

      final merged = <String, UserAccount>{};
      for (final doc in res1.documents) {
        final user = UserAccount.fromMap(doc.data);
        if (user.id.isNotEmpty) merged[user.id] = user;
      }
      if (res2 != null) {
        for (final doc in res2.documents) {
          final user = UserAccount.fromMap(doc.data);
          if (user.id.isNotEmpty) merged[user.id] = user;
        }
      }
      return merged.values.toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> makeAdmin(String userId) async {
    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomMembersCollection,
        queries: [
          Query.equal('communityId', _roomId),
          Query.equal('userId', userId),
          Query.limit(1),
        ],
      );

      if (response.documents.isEmpty) return;

      await _appwrite.databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomMembersCollection,
        documentId: response.documents.first.$id,
        data: {
          'role': 'admin',
        },
      );

      await _loadMembers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}