import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/appwrite_service.dart';
import '../core/constants/appwrite_constants.dart';
import '../models/badge.dart';
import 'package:appwrite/appwrite.dart';

enum BadgeType {
  debater, // Create 5+ debates
  commentator, // Make 10+ comments
  voter, // Cast 20+ votes
  influencer, // Get 50+ upvotes on debates
  thoughtful, // Get 20+ upvotes on comments
  peacekeeper, // Moderate 5+ reports
  firstDebate, // Create first debate
  socialButterfly, // Send 10+ messages
  trendsetter, // Get a debate to trending
  allStarDebater, // Win 10 debates (more agrees than disagrees)
}

// We'll keep BadgeModel here if it's only used for static definitions, 
// but we've moved UserBadge to models/badge.dart.
class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String icon; // emoji or icon identifier
  final String category; // 'achievement', 'milestone', 'special'
  final int unlockedCount; // How many users have this badge

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    this.unlockedCount = 0,
  });

  factory BadgeModel.fromMap(Map<String, dynamic> map) {
    return BadgeModel(
      id: map['\$id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '🏅',
      category: map['category'] ?? 'achievement',
      unlockedCount: map['unlocked_count'] ?? 0,
    );
  }
}

final badgesProvider = FutureProvider<List<BadgeModel>>((ref) async {
  return [
    BadgeModel(id: 'firstDebate', name: 'First Debate', description: 'Created your first debate', icon: '🌱', category: 'milestone'),
    BadgeModel(id: 'debater', name: 'Debater', description: 'Created 5+ debates', icon: '🎙️', category: 'achievement'),
    BadgeModel(id: 'commentator', name: 'Commentator', description: 'Posted 10+ comments', icon: '💬', category: 'achievement'),
    BadgeModel(id: 'voter', name: 'Voter', description: 'Cast 20+ votes', icon: '🗳️', category: 'achievement'),
  ];
});

final userBadgesProvider = StateNotifierProvider<UserBadgesNotifier, UserBadgesState>((ref) {
  return UserBadgesNotifier(AppwriteService());
});

class UserBadgesState {
  final List<UserBadge> badges;
  final bool isLoading;
  final String? error;

  UserBadgesState({
    this.badges = const [],
    this.isLoading = false,
    this.error,
  });

  UserBadgesState copyWith({
    List<UserBadge>? badges,
    bool? isLoading,
    String? error,
  }) {
    return UserBadgesState(
      badges: badges ?? this.badges,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class UserBadgesNotifier extends StateNotifier<UserBadgesState> {
  final AppwriteService _appwrite;

  UserBadgesNotifier(this._appwrite) : super(UserBadgesState()) {
    _loadUserBadges();
  }

  Future<void> _loadUserBadges() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _appwrite.account.get();

      final userBadgesResponse = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.badgesCollection,
        queries: [
          Query.equal('user_id', user.$id),
          Query.orderDesc('\$createdAt'),
        ],
      );

      final badges = <UserBadge>[];
      for (final doc in userBadgesResponse.documents) {
        try {
              final badgeId = doc.data['badge_id'] as String;
          // Find the badge model from static list for caching/display purposes
          final allBadges = [
            BadgeModel(id: 'firstDebate', name: 'First Debate', description: 'Created your first debate', icon: '🌱', category: 'milestone'),
            BadgeModel(id: 'debater', name: 'Debater', description: 'Created 5+ debates', icon: '🎙️', category: 'achievement'),
            BadgeModel(id: 'commentator', name: 'Commentator', description: 'Posted 10+ comments', icon: '💬', category: 'achievement'),
            BadgeModel(id: 'voter', name: 'Voter', description: 'Cast 20+ votes', icon: '🗳️', category: 'achievement'),
          ];
          
          final _ = allBadges.firstWhere(
            (b) => b.id == badgeId,
            orElse: () => BadgeModel(id: badgeId, name: 'Unknown', description: '', icon: '🏅', category: 'unknown')
          );
          
          badges.add(UserBadge.fromMap(doc.data));
        } catch (e) {
          // Badge not found or deleted
        }
      }

      state = state.copyWith(badges: badges, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> checkAndUnlockBadges(String userId) async {
    try {
      // Get user stats
      final debatesResponse = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.debatesCollection,
        queries: [
          Query.equal('user_id', userId),
        ],
      );

      final commentsResponse = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.commentsCollection,
        queries: [
          Query.equal('user_id', userId),
        ],
      );

      final votesResponse = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.votesCollection,
        queries: [
          Query.equal('user_id', userId),
        ],
      );

      int debateCount = debatesResponse.total;
      int commentCount = commentsResponse.total;
      int voteCount = votesResponse.total;

      // Check badges to unlock
      final badgesToCheck = [
        ('firstDebate', debateCount >= 1),
        ('debater', debateCount >= 5),
        ('commentator', commentCount >= 10),
        ('voter', voteCount >= 20),
      ];

      for (final (badgeName, isUnlocked) in badgesToCheck) {
        if (isUnlocked) {
          await _unlockBadgeByName(userId, badgeName);
        }
      }

      await _loadUserBadges();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _unlockBadgeByName(String userId, String badgeName) async {
    try {
      // Find badge by name
      final badgesResponse = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.badgesCollection,
        queries: [
          Query.search('name', badgeName),
        ],
      );

      if (badgesResponse.documents.isEmpty) {
        return;
      }

      final badge = badgesResponse.documents.first;
      final badgeId = badge.$id;

      // Check if already unlocked
      final existing = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.badgesCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.equal('badge_id', badgeId),
        ],
      );

      if (existing.documents.isNotEmpty) {
        return; // Already unlocked
      }

      // Unlock badge
      await _appwrite.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.badgesCollection,
        documentId: ID.unique(),
        data: {
          'user_id': userId,
          'badge_id': badgeId,
          'earned_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> unlockBadge(String userId, String badgeId) async {
    try {
      // Check if already unlocked
      final existing = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.badgesCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.equal('badge_id', badgeId),
        ],
      );

      if (existing.documents.isNotEmpty) {
        return; // Already unlocked
      }

      await _appwrite.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.badgesCollection,
        documentId: ID.unique(),
        data: {
          'user_id': userId,
          'badge_id': badgeId,
          'earned_at': DateTime.now().toIso8601String(),
        },
      );

      await _loadUserBadges();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}