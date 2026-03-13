import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/appwrite_service.dart';
import '../models/user_account.dart';
import '../core/constants/appwrite_constants.dart';
import 'package:appwrite/appwrite.dart';

final leaderboardProvider = StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier(AppwriteService());
});

class LeaderboardState {
  final List<UserAccount> entries;
  final bool isLoading;
  final String? error;

  LeaderboardState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
  });

  LeaderboardState copyWith({
    List<UserAccount>? entries,
    bool? isLoading,
    String? error,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final AppwriteService _appwrite;

  LeaderboardNotifier(this._appwrite) : super(LeaderboardState());

  Future<void> fetchLeaderboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      late final dynamic response;
      try {
        response = await _appwrite.databases.listDocuments(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollection,
          queries: [
            Query.orderDesc('xp'),
            Query.limit(50),
          ],
        );
      } catch (_) {
        response = await _appwrite.databases.listDocuments(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollection,
          queries: [
            Query.orderDesc('reputation'),
            Query.limit(50),
          ],
        );
      }
      final entries = response.documents.map((doc) => UserAccount.fromMap(doc.data)).toList();
      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
