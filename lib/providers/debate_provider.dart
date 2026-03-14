import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:convert';
import '../core/services/appwrite_service.dart';
import '../models/debate.dart';
import '../core/constants/appwrite_constants.dart';
import 'package:appwrite/appwrite.dart';

final debateProvider = StateNotifierProvider<DebateNotifier, DebateState>((ref) {
  return DebateNotifier(AppwriteService());
});

enum DebateFeedType { forYou, trending, following }

const _noChange = Object();

class DebateState {
  final List<Debate> debates;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final DebateFeedType feedType;
  final String? selectedCategoryId;
  final String? lastDocumentId;
  final Map<String, int?> userVotes; // debateId -> 1 | -1 | null
  final Set<String> likedDebateIds;
  final Set<String> savedDebateIds;
  final String? error;

  DebateState({
    this.debates = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.feedType = DebateFeedType.forYou,
    this.selectedCategoryId,
    this.lastDocumentId,
    this.userVotes = const {},
    this.likedDebateIds = const {},
    this.savedDebateIds = const {},
    this.error,
  });

  DebateState copyWith({
    List<Debate>? debates,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    DebateFeedType? feedType,
    Object? selectedCategoryId = _noChange,
    Object? lastDocumentId = _noChange,
    Map<String, int?>? userVotes,
    Set<String>? likedDebateIds,
    Set<String>? savedDebateIds,
    Object? error = _noChange,
  }) {
    return DebateState(
      debates: debates ?? this.debates,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      feedType: feedType ?? this.feedType,
      selectedCategoryId: identical(selectedCategoryId, _noChange)
          ? this.selectedCategoryId
          : selectedCategoryId as String?,
      lastDocumentId: identical(lastDocumentId, _noChange)
          ? this.lastDocumentId
          : lastDocumentId as String?,
      userVotes: userVotes ?? this.userVotes,
      likedDebateIds: likedDebateIds ?? this.likedDebateIds,
      savedDebateIds: savedDebateIds ?? this.savedDebateIds,
      error: identical(error, _noChange) ? this.error : error as String?,
    );
  }
}

class DebateNotifier extends StateNotifier<DebateState> {
  final AppwriteService _appwrite;
  static const int _pageSize = 20;
  RealtimeSubscription? _debatesSubscription;
  RealtimeSubscription? _interactionsSubscription;
  Timer? _realtimeRefreshDebounce;
  bool _refreshingFromRealtime = false;

  DebateNotifier(this._appwrite) : super(DebateState()) {
    _subscribeRealtime();
  }

  Future<bool> _antiSpamAllows(String userId, String action) async {
    try {
      final execution = await _appwrite.functions.createExecution(
        functionId: 'anti-spam-check',
        body: jsonEncode({'userId': userId, 'action': action}),
        xasync: false,
      );
      final decoded = jsonDecode(execution.responseBody);
      if (decoded is Map<String, dynamic>) {
        return decoded['allowed'] != false;
      }
      return true;
    } catch (_) {
      // Fail-open: anti-spam check should not hard-block on transport errors.
      return true;
    }
  }

  Future<void> _awardXp({
    required String userId,
    required String action,
    String? referenceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _appwrite.functions.createExecution(
        functionId: 'update-xp',
        body: jsonEncode({
          'userId': userId,
          'action': action,
          if (referenceId != null) 'referenceId': referenceId,
          if (metadata != null) 'metadata': metadata,
        }),
        xasync: true,
      );
    } catch (_) {
      // Non-fatal: primary action should succeed even if XP pipeline is down.
    }
  }

  void _subscribeRealtime() {
    final debatesChannel =
        'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.debatesCollection}.documents';
    final votesChannel =
        'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.votesCollection}.documents';
    final likesChannel =
        'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.likes}.documents';
    final commentsChannel =
        'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.commentsCollection}.documents';
    final savesChannel =
        'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.saves}.documents';

    _debatesSubscription = _appwrite.realtime.subscribe([debatesChannel]);
    _debatesSubscription!.stream.listen((_) => _scheduleRealtimeRefresh());

    _interactionsSubscription =
        _appwrite.realtime.subscribe([votesChannel, likesChannel, commentsChannel, savesChannel]);
    _interactionsSubscription!.stream.listen((_) => _scheduleRealtimeRefresh());
  }

  void _scheduleRealtimeRefresh() {
    _realtimeRefreshDebounce?.cancel();
    _realtimeRefreshDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (_refreshingFromRealtime || state.isLoading) return;
      _refreshingFromRealtime = true;
      try {
        await fetchDebates(
          categoryId: state.selectedCategoryId,
          feedType: state.feedType,
          refresh: true,
        );
      } finally {
        _refreshingFromRealtime = false;
      }
    });
  }

  Future<void> fetchDebates({
    String? categoryId,
    DebateFeedType feedType = DebateFeedType.forYou,
    bool refresh = true,
  }) async {
    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        isLoadingMore: false,
        hasMore: true,
        debates: const [],
        lastDocumentId: null,
        feedType: feedType,
        selectedCategoryId: categoryId,
        error: null,
      );
    } else {
      if (state.isLoadingMore || !state.hasMore) return;
      state = state.copyWith(isLoadingMore: true, error: null);
    }

    try {
      final effectiveCategoryId = categoryId ?? state.selectedCategoryId;
      final effectiveFeedType = refresh ? feedType : state.feedType;

      final queries = <String>[Query.limit(_pageSize)];

      if (effectiveFeedType == DebateFeedType.trending) {
        queries.add(Query.orderDesc('trendingScore'));
        queries.add(Query.orderDesc('\$createdAt'));
      } else {
        queries.add(Query.orderDesc('\$createdAt'));
      }

      if (effectiveCategoryId != null) {
        queries.add(Query.equal('category', effectiveCategoryId));
      }

      if (effectiveFeedType == DebateFeedType.following) {
        final user = await _appwrite.account.get();
        final followingIds = await _loadFollowingIds(user.$id);

        if (followingIds.isEmpty) {
          state = state.copyWith(
            debates: const [],
            isLoading: false,
            isLoadingMore: false,
            hasMore: false,
            error: null,
          );
          return;
        }

        queries.add(Query.equal('creatorId', followingIds));
      }

      final cursor = refresh ? null : state.lastDocumentId;
      if (cursor != null && cursor.isNotEmpty) {
        queries.add(Query.cursorAfter(cursor));
      }

      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.debatesCollection,
        queries: queries,
      );

      final fetched = response.documents.map((doc) => Debate.fromMap(doc.data)).toList();
      final merged = refresh ? fetched : [...state.debates, ...fetched];
      final interactions = await _loadInteractionState(merged);

      state = state.copyWith(
        debates: merged,
        isLoading: false,
        isLoadingMore: false,
        hasMore: fetched.length == _pageSize,
        lastDocumentId: response.documents.isNotEmpty ? response.documents.last.$id : state.lastDocumentId,
        feedType: effectiveFeedType,
        selectedCategoryId: effectiveCategoryId,
        userVotes: interactions.userVotes,
        likedDebateIds: interactions.likedDebateIds,
        savedDebateIds: interactions.savedDebateIds,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    await fetchDebates(refresh: false);
  }

  Future<void> castDebateVoteOptimistic(String debateId, int value) async {
    final previousDebates = List<Debate>.from(state.debates);
    final previousUserVotes = Map<String, int?>.from(state.userVotes);
    final oldVote = previousUserVotes[debateId];
    final newVote = oldVote == value ? null : value;

    int upDelta = 0;
    int downDelta = 0;
    if (oldVote == 1) upDelta -= 1;
    if (oldVote == -1) downDelta -= 1;
    if (newVote == 1) upDelta += 1;
    if (newVote == -1) downDelta += 1;

    final patchedDebates = state.debates.map((d) {
      if (d.id != debateId) return d;
      return d.copyWith(
        upvotes: (d.upvotes + upDelta).clamp(0, 1 << 30),
        downvotes: (d.downvotes + downDelta).clamp(0, 1 << 30),
      );
    }).toList();

    final patchedVotes = Map<String, int?>.from(state.userVotes);
    patchedVotes[debateId] = newVote;
    state = state.copyWith(debates: patchedDebates, userVotes: patchedVotes, error: null);

    try {
      final user = await _appwrite.account.get();
      final allowed = await _antiSpamAllows(user.$id, 'vote_cast');
      if (!allowed) {
        throw Exception('Rate limit reached. Please wait and try again.');
      }
      final execution = await _appwrite.functions.createExecution(
        functionId: 'cast-vote',
        body: jsonEncode({
          'userId': user.$id,
          'debateId': debateId,
          'side': newVote == null ? null : (newVote == 1 ? 'agree' : 'disagree'),
        }),
        xasync: false,
      );

      final decoded = jsonDecode(execution.responseBody);
      if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
        throw Exception('Vote update failed');
      }

      final agreeCount = (decoded['agreeCount'] as num?)?.toInt();
      final disagreeCount = (decoded['disagreeCount'] as num?)?.toInt();
      if (agreeCount != null && disagreeCount != null) {
        final synced = state.debates.map((d) {
          if (d.id != debateId) return d;
          return d.copyWith(upvotes: agreeCount, downvotes: disagreeCount);
        }).toList();
        state = state.copyWith(debates: synced);
      }
    } catch (e) {
      state = state.copyWith(
        debates: previousDebates,
        userVotes: previousUserVotes,
        error: e.toString(),
      );
    }
  }

  Future<void> toggleLikeOptimistic(String debateId) async {
    final oldLiked = Set<String>.from(state.likedDebateIds);
    final isLiked = oldLiked.contains(debateId);

    final newLiked = Set<String>.from(oldLiked);
    if (isLiked) {
      newLiked.remove(debateId);
    } else {
      newLiked.add(debateId);
    }

    state = state.copyWith(likedDebateIds: newLiked, error: null);

    try {
      final user = await _appwrite.account.get();
      final likesCollection = AppwriteConstants.likes;
      final existing = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: likesCollection,
        queries: [
          Query.equal('debateId', debateId),
          Query.equal('userId', user.$id),
          Query.limit(1),
        ],
      );

      if (existing.documents.isNotEmpty) {
        await _appwrite.databases.deleteDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: likesCollection,
          documentId: existing.documents.first.$id,
        );
      } else {
        await _appwrite.databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: likesCollection,
          documentId: ID.unique(),
          data: {
            'debateId': debateId,
            'userId': user.$id,
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      state = state.copyWith(likedDebateIds: oldLiked, error: e.toString());
    }
  }

  Future<void> toggleSaveOptimistic(String debateId) async {
    final oldSaved = Set<String>.from(state.savedDebateIds);
    final isSaved = oldSaved.contains(debateId);
    final newSaved = Set<String>.from(oldSaved);
    if (isSaved) {
      newSaved.remove(debateId);
    } else {
      newSaved.add(debateId);
    }
    state = state.copyWith(savedDebateIds: newSaved, error: null);

    try {
      final user = await _appwrite.account.get();
      final saveCollection = await _resolveSaveCollection();

      final existing = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: saveCollection,
        queries: [
          Query.equal('userId', user.$id),
          Query.equal('debateId', debateId),
          Query.limit(1),
        ],
      );

      if (existing.documents.isNotEmpty) {
        await _appwrite.databases.deleteDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: saveCollection,
          documentId: existing.documents.first.$id,
        );
      } else {
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
      }
    } catch (e) {
      state = state.copyWith(savedDebateIds: oldSaved, error: e.toString());
    }
  }

  Future<({Map<String, int?> userVotes, Set<String> likedDebateIds, Set<String> savedDebateIds})>
      _loadInteractionState(List<Debate> debates) async {
    if (debates.isEmpty) {
      return (userVotes: <String, int?>{}, likedDebateIds: <String>{}, savedDebateIds: <String>{});
    }

    try {
      final user = await _appwrite.account.get();
      final debateIds = debates.map((d) => d.id).toList();

      final votesRes = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.votesCollection,
        queries: [
          Query.equal('userId', user.$id),
          Query.equal('debateId', debateIds),
          Query.limit(200),
        ],
      );

      final userVotes = <String, int?>{};
      for (final doc in votesRes.documents) {
        final debateId = doc.data['debateId'] as String?;
        final side = doc.data['side']?.toString();
        final value = side == 'agree' ? 1 : (side == 'disagree' ? -1 : null);
        if (debateId != null) userVotes[debateId] = value;
      }

      final likes = <String>{};
      try {
        final likesRes = await _appwrite.databases.listDocuments(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.likes,
          queries: [
            Query.equal('userId', user.$id),
            Query.equal('debateId', debateIds),
            Query.limit(200),
          ],
        );
        for (final doc in likesRes.documents) {
          final id = doc.data['debateId'] as String?;
          if (id != null) likes.add(id);
        }
      } catch (_) {
        // likes collection may not exist in legacy deployments
      }

      final saves = <String>{};
      final saveCollection = await _resolveSaveCollection();
      final savesRes = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: saveCollection,
        queries: [
          Query.equal('userId', user.$id),
          Query.equal('debateId', debateIds),
          Query.limit(200),
        ],
      );
      for (final doc in savesRes.documents) {
        final id = doc.data['debateId'] as String?;
        if (id != null) saves.add(id);
      }

      return (userVotes: userVotes, likedDebateIds: likes, savedDebateIds: saves);
    } catch (_) {
      return (
        userVotes: Map<String, int?>.from(state.userVotes),
        likedDebateIds: Set<String>.from(state.likedDebateIds),
        savedDebateIds: Set<String>.from(state.savedDebateIds),
      );
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

  Future<void> createDebate(Debate debate) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final allowed = await _antiSpamAllows(debate.creatorId, 'debate_created');
      if (!allowed) {
        throw Exception('Daily debate creation limit reached. Please try again later.');
      }
      final documentId = ID.unique();
      String creatorName = 'Unknown';
      String? creatorAvatar;
      try {
        final profile = await _appwrite.databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollection,
          documentId: debate.creatorId,
        );
        creatorName =
            (profile.data['displayName'] ?? profile.data['username'] ?? creatorName).toString();
        creatorAvatar = profile.data['avatar']?.toString();
      } catch (_) {
        // Fall back to a safe required value for creator_name.
      }

      await _appwrite.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.debatesCollection,
        documentId: documentId,
        data: {
          'title': debate.title,
          'topic': debate.title,
          'description': debate.description,
          'categoryId': debate.categoryId,
          'category': debate.categoryId,
          'creatorId': debate.creatorId,
          'creatorName': creatorName,
          'creatorAvatar': creatorAvatar,
          'mediaType': debate.mediaType,
          'mediaUrl': debate.mediaUrl,
          'imageUrl': debate.mediaUrl,
          'agreeCount': 0,
          'disagreeCount': 0,
          'upvotes': 0,
          'downvotes': 0,
          'commentCount': 0,
          'viewCount': 0,
          'likeCount': 0,
          'status': 'active',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      await _awardXp(userId: debate.creatorId, action: 'debate_created', referenceId: documentId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<List<String>> _loadFollowingIds(String userId) async {
    try {
      final connectionsRes = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.connections,
        queries: [
          Query.equal('requesterId', userId),
          Query.equal('status', ['follow', 'connected']),
          Query.limit(100),
        ],
      );

      final ids = connectionsRes.documents
          .map((doc) => doc.data['receiverId'] as String?)
          .whereType<String>()
          .toList();
      if (ids.isNotEmpty) return ids;
    } catch (_) {
      return const [];
    }

    return const [];
  }

  @override
  void dispose() {
    _realtimeRefreshDebounce?.cancel();
    _debatesSubscription?.close();
    _interactionsSubscription?.close();
    super.dispose();
  }
}
