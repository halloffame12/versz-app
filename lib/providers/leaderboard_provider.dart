import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/appwrite_service.dart';
import '../models/user_account.dart';
import '../core/constants/appwrite_constants.dart';
import 'package:appwrite/appwrite.dart';

final leaderboardProvider = StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier(AppwriteService());
});

enum LeaderboardPeriod { weekly, monthly, allTime }

class LeaderboardState {
  final List<UserAccount> entries;
  final bool isLoading;
  final LeaderboardPeriod period;
  final String? error;
  /// Per-period cache so switching tabs doesn't discard already-loaded data.
  final Map<LeaderboardPeriod, List<UserAccount>> cache;

  LeaderboardState({
    this.entries = const [],
    this.isLoading = false,
    this.period = LeaderboardPeriod.weekly,
    this.error,
    this.cache = const {},
  });

  LeaderboardState copyWith({
    List<UserAccount>? entries,
    bool? isLoading,
    LeaderboardPeriod? period,
    String? error,
    Map<LeaderboardPeriod, List<UserAccount>>? cache,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      period: period ?? this.period,
      error: error ?? this.error,
      cache: cache ?? this.cache,
    );
  }

  List<UserAccount> entriesFor(LeaderboardPeriod p) => cache[p] ?? entries;
}

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final AppwriteService _appwrite;

  LeaderboardNotifier(this._appwrite) : super(LeaderboardState());

  Future<void> fetchLeaderboard({LeaderboardPeriod? period}) async {
    final targetPeriod = period ?? state.period;
    state = state.copyWith(isLoading: true, period: targetPeriod, error: null);
    try {
      late final dynamic response;
      try {
        response = await _appwrite.databases.listDocuments(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollection,
          queries: [
            Query.limit(50),
          ],
        );
      } catch (_) {
        response = await _appwrite.databases.listDocuments(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollection,
          queries: [
            Query.limit(50),
          ],
        );
      }

      final List<UserAccount> rawEntries =
          response.documents.map<UserAccount>((doc) => UserAccount.fromMap(doc.data)).toList();
      final entries = [...rawEntries]
        ..sort((a, b) => _scoreFor(b, targetPeriod).compareTo(_scoreFor(a, targetPeriod)));

      final updatedCache = Map<LeaderboardPeriod, List<UserAccount>>.from(state.cache)
        ..[targetPeriod] = entries;
      state = state.copyWith(entries: entries, isLoading: false, cache: updatedCache);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  int scoreFor(UserAccount user) => _scoreFor(user, state.period);

  int _scoreFor(UserAccount user, LeaderboardPeriod period) {
    switch (period) {
      case LeaderboardPeriod.weekly:
        return user.weeklyXp;
      case LeaderboardPeriod.monthly:
        final estimatedMonthly = user.weeklyXp * 4;
        return estimatedMonthly > 0 ? estimatedMonthly : user.xp;
      case LeaderboardPeriod.allTime:
        return user.xp;
    }
  }
}
