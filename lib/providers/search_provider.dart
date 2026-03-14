import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/appwrite_service.dart';
import '../models/debate.dart';
import '../models/room.dart';
import '../models/user_account.dart';
import '../core/constants/appwrite_constants.dart';
import 'package:appwrite/appwrite.dart';

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(AppwriteService());
});

class HashtagResult {
  final String tag;
  final int debateCount;

  const HashtagResult({required this.tag, required this.debateCount});
}

class SearchState {
  final String query;
  final List<Debate> debates;
  final List<Room> rooms;
  final List<UserAccount> users;
  final List<HashtagResult> hashtags;
  final List<String> trendingSearches;
  final List<Room> trendingRooms;
  final List<String> recentSearches;
  final bool isLoading;
  final String? error;

  SearchState({
    this.query = '',
    this.debates = const [],
    this.rooms = const [],
    this.users = const [],
    this.hashtags = const [],
    this.trendingSearches = const [],
    this.trendingRooms = const [],
    this.recentSearches = const [],
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    List<Debate>? debates,
    List<Room>? rooms,
    List<UserAccount>? users,
    List<HashtagResult>? hashtags,
    List<String>? trendingSearches,
    List<Room>? trendingRooms,
    List<String>? recentSearches,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      debates: debates ?? this.debates,
      rooms: rooms ?? this.rooms,
      users: users ?? this.users,
      hashtags: hashtags ?? this.hashtags,
      trendingSearches: trendingSearches ?? this.trendingSearches,
      trendingRooms: trendingRooms ?? this.trendingRooms,
      recentSearches: recentSearches ?? this.recentSearches,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final AppwriteService _appwrite;

  SearchNotifier(this._appwrite) : super(SearchState());

  Future<void> loadDiscovery() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rooms = await getTrendingRooms();
      final terms = await getTrendingSearches();
      state = state.copyWith(
        trendingRooms: rooms,
        trendingSearches: terms,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setRecentSearches(List<String> recent) {
    state = state.copyWith(recentSearches: recent);
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(
        query: '',
        debates: const [],
        rooms: const [],
        users: const [],
        hashtags: const [],
        isLoading: false,
        error: null,
      );
      return;
    }

    state = state.copyWith(query: query, isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _searchDebates(query),
        _searchRooms(query),
        _searchUsers(query),
        _searchHashtags(query),
      ]);

      state = state.copyWith(
        debates: results[0] as List<Debate>,
        rooms: results[1] as List<Room>,
        users: results[2] as List<UserAccount>,
        hashtags: results[3] as List<HashtagResult>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearSearch() {
    state = state.copyWith(
      query: '',
      debates: const [],
      rooms: const [],
      users: const [],
      hashtags: const [],
      isLoading: false,
      error: null,
    );
  }

  Future<List<Debate>> _searchDebates(String query) async {
    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.debatesCollection,
        queries: [
          Query.search('topic', query),
          Query.limit(10),
        ],
      );
      return response.documents.map((doc) => Debate.fromMap(doc.data)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Room>> _searchRooms(String query) async {
    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomsCollection,
        queries: [
          Query.search('name', query),
          Query.limit(10),
        ],
      );
      return response.documents.map((doc) => Room.fromMap(doc.data)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<UserAccount>> _searchUsers(String query) async {
    try {
      final byUsername = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        queries: [
          Query.search('username', query),
          Query.limit(10),
        ],
      );

      final byDisplayName = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        queries: [
          Query.search('displayName', query),
          Query.limit(10),
        ],
      );

      final merged = <String, UserAccount>{};
      for (final doc in byUsername.documents) {
        final user = UserAccount.fromMap(doc.data);
        merged[user.id] = user;
      }
      for (final doc in byDisplayName.documents) {
        final user = UserAccount.fromMap(doc.data);
        merged[user.id] = user;
      }
      return merged.values.toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<HashtagResult>> _searchHashtags(String query) async {
    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.hashtags,
        queries: [
          Query.search('tag', query),
          Query.limit(15),
        ],
      );

      return response.documents.map((doc) {
        final tag = (doc.data['tag'] ?? '').toString();
        final count = (doc.data['debateCount'] ?? 0) as int;
        return HashtagResult(tag: tag, debateCount: count);
      }).where((item) => item.tag.isNotEmpty).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Room>> getTrendingRooms() async {
    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.roomsCollection,
        queries: [
          Query.orderDesc('memberCount'),
          Query.limit(5),
        ],
      );
      return response.documents.map((doc) => Room.fromMap(doc.data)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> getTrendingSearches() async {
    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.trending,
        queries: [
          Query.orderDesc('score'),
          Query.limit(8),
        ],
      );
      final terms = response.documents
          .map((doc) => (doc.data['title'] ?? '').toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
      return terms;
    } catch (_) {
      // Fallback to top debate titles if trending collection is unavailable.
      try {
        final debates = await _appwrite.databases.listDocuments(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.debatesCollection,
          queries: [Query.orderDesc('agreeCount'), Query.limit(8)],
        );
        return debates.documents
            .map((doc) => (doc.data['topic'] ?? doc.data['title'] ?? '').toString())
            .where((e) => e.trim().isNotEmpty)
            .toList();
      } catch (_) {
        return [];
      }
    }
  }
}