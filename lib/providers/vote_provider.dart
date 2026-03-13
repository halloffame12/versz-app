import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/appwrite_service.dart';
import '../core/constants/appwrite_constants.dart';
import 'package:appwrite/appwrite.dart';

final voteProvider = StateNotifierProvider.family<VoteNotifier, VoteState, String>((ref, key) {
  final parts = key.split(':');
  final targetType = parts[0];
  final targetId = parts[1];
  return VoteNotifier(AppwriteService(), targetId: targetId, targetType: targetType);
});

class VoteState {
  final int? userVote; // 1, -1, or null
  final bool isLoading;
  final String? error;

  VoteState({
    this.userVote,
    this.isLoading = false,
    this.error,
  });

  VoteState copyWith({
    int? userVote,
    bool? isLoading,
    String? error,
  }) {
    return VoteState(
      userVote: userVote ?? this.userVote,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class VoteNotifier extends StateNotifier<VoteState> {
  final AppwriteService _appwrite;
  final String targetId;
  final String targetType;

  VoteNotifier(this._appwrite, {required this.targetId, required this.targetType}) : super(VoteState()) {
    _loadUserVote();
  }

  Future<void> _loadUserVote() async {
    if (targetType != 'debate') {
      state = state.copyWith(userVote: null);
      return;
    }

    try {
      final user = await _appwrite.account.get();
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.votesCollection,
        queries: [
          Query.equal('debateId', targetId),
          Query.equal('userId', user.$id),
        ],
      );

      if (response.documents.isNotEmpty) {
        final side = (response.documents.first.data['side'] ?? '').toString();
        final value = side == 'agree' ? 1 : side == 'disagree' ? -1 : 0;
        state = state.copyWith(userVote: value);
      }
    } catch (e) {
      // No vote found or error loading - that's okay
    }
  }

  Future<void> castVote(int value) async {
    if (targetType != 'debate') {
      state = state.copyWith(
        isLoading: false,
        error: 'Only debate votes are supported by the v3 schema.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _appwrite.account.get();
      final side = value == 1 ? 'agree' : 'disagree';

      // Check if user already voted
      final existingVote = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.votesCollection,
        queries: [
          Query.equal('debateId', targetId),
          Query.equal('userId', user.$id),
        ],
      );

      if (existingVote.documents.isNotEmpty) {
        final voteDoc = existingVote.documents.first;
        final oldSide = (voteDoc.data['side'] ?? '').toString();
        final oldValue = oldSide == 'agree' ? 1 : -1;
        
        if (oldValue == value) {
          // Toggle off
          await _appwrite.databases.deleteDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.votesCollection,
            documentId: voteDoc.$id,
          );
          await _updateCounts(oldValue, increment: false);
          state = state.copyWith(userVote: null, isLoading: false);
        } else {
          // Switch vote
          await _appwrite.databases.updateDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.votesCollection,
            documentId: voteDoc.$id,
            data: {'side': side},
          );
          await _updateCounts(oldValue, increment: false);
          await _updateCounts(value, increment: true);
          state = state.copyWith(userVote: value, isLoading: false);
        }
      } else {
        // Create new vote
        await _appwrite.databases.createDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.votesCollection,
            documentId: ID.unique(),
            data: {
              'userId': user.$id,
              'debateId': targetId,
              'side': side,
              'createdAt': DateTime.now().toIso8601String(),
            },
        );
        await _updateCounts(value, increment: true);
        state = state.copyWith(userVote: value, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _updateCounts(int value, {required bool increment}) async {
    try {
        final collectionId = AppwriteConstants.debatesCollection;

      final doc = await _appwrite.databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: collectionId,
        documentId: targetId,
      );

      int upvotes = doc.data['upvotes'] ?? 0;
      int downvotes = doc.data['downvotes'] ?? 0;
      int agreeCount = doc.data['agreeCount'] ?? upvotes;
      int disagreeCount = doc.data['disagreeCount'] ?? downvotes;

      if (value == 1) {
        upvotes = increment ? upvotes + 1 : upvotes - 1;
        agreeCount = increment ? agreeCount + 1 : agreeCount - 1;
      } else {
        downvotes = increment ? downvotes + 1 : downvotes - 1;
        disagreeCount = increment ? disagreeCount + 1 : disagreeCount - 1;
      }

      upvotes = upvotes.clamp(0, 1 << 30);
      downvotes = downvotes.clamp(0, 1 << 30);
      agreeCount = agreeCount.clamp(0, 1 << 30);
      disagreeCount = disagreeCount.clamp(0, 1 << 30);

      await _appwrite.databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: collectionId,
        documentId: targetId,
        data: {
          'agreeCount': agreeCount,
          'disagreeCount': disagreeCount,
          'upvotes': upvotes,
          'downvotes': downvotes,
        },
      );
    } catch (e) {
      // Log error but don't fail
    }
  }
}