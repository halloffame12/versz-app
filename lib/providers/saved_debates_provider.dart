import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/debate.dart';
import '../core/services/appwrite_service.dart';
import '../core/constants/appwrite_constants.dart';
import 'package:appwrite/appwrite.dart';

final savedDebatesProvider = StateNotifierProvider<SavedDebatesNotifier, SavedDebatesState>((ref) {
  return SavedDebatesNotifier(AppwriteService());
});

class SavedDebatesState {
  final List<Debate> savedDebates;
  final bool isLoading;
  final String? error;

  SavedDebatesState({
    this.savedDebates = const [],
    this.isLoading = false,
    this.error,
  });

  SavedDebatesState copyWith({
    List<Debate>? savedDebates,
    bool? isLoading,
    String? error,
  }) {
    return SavedDebatesState(
      savedDebates: savedDebates ?? this.savedDebates,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SavedDebatesNotifier extends StateNotifier<SavedDebatesState> {
  final AppwriteService _appwrite;

  SavedDebatesNotifier(this._appwrite) : super(SavedDebatesState()) {
    _loadSavedDebates();
  }

  Future<void> _loadSavedDebates() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _appwrite.account.get();
      final saveCollection = await _resolveSaveCollection();

      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: saveCollection,
        queries: [
          Query.equal('userId', user.$id),
          Query.orderDesc('\$createdAt'),
          Query.limit(100),
        ],
      );

      final debateIds = response.documents.map((doc) => doc.data['debateId'] as String).toList();

      // Fetch debate details
      final debates = <Debate>[];
      for (final debateId in debateIds) {
        try {
          final debateDoc = await _appwrite.databases.getDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.debatesCollection,
            documentId: debateId,
          );
          debates.add(Debate.fromMap(debateDoc.data));
        } catch (e) {
          // Debate not found or deleted
        }
      }

      state = state.copyWith(savedDebates: debates, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveDebate(String debateId) async {
    try {
      final user = await _appwrite.account.get();
      final saveCollection = await _resolveSaveCollection();

      // Check if already saved
      final existing = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: saveCollection,
        queries: [
          Query.equal('userId', user.$id),
          Query.equal('debateId', debateId),
        ],
      );

      if (existing.documents.isNotEmpty) {
        // Already saved
        return;
      }

      await _appwrite.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: saveCollection,
        documentId: ID.unique(),
        data: {
          'userId': user.$id,
          'debateId': debateId,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      await _loadSavedDebates();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> unsaveDebate(String debateId) async {
    try {
      final user = await _appwrite.account.get();
      final saveCollection = await _resolveSaveCollection();

      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: saveCollection,
        queries: [
          Query.equal('userId', user.$id),
          Query.equal('debateId', debateId),
        ],
      );

      if (response.documents.isNotEmpty) {
        await _appwrite.databases.deleteDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: saveCollection,
          documentId: response.documents.first.$id,
        );

        await _loadSavedDebates();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> isDebateSaved(String debateId) async {
    try {
      final user = await _appwrite.account.get();
      final saveCollection = await _resolveSaveCollection();

      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: saveCollection,
        queries: [
          Query.equal('userId', user.$id),
          Query.equal('debateId', debateId),
        ],
      );

      return response.documents.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<String> _resolveSaveCollection() async {
    try {
      await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.saves,
        queries: [Query.limit(1)],
      );
      return AppwriteConstants.saves;
    } catch (_) {
      return AppwriteConstants.savedDebatesCollection;
    }
  }
}