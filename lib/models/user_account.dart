import 'package:equatable/equatable.dart';

/// User model representing a Versz user.
/// Reads camelCase schema, with snake_case fallback for legacy docs.
class UserAccount extends Equatable {
  final String id; // Appwrite account.$id
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? coverImage;
  final String? bio;
  final String? website;
  final int xp;
  final int weeklyXp;
  final int followersCount;
  final int followingCount;
  final int connectionsCount;
  final int debatesCreated;
  final int totalVotes;
  final int currentStreak;
  final int longestStreak;
  final double winRate;
  final bool isVerified;
  final bool isOnline;
  final bool isPrivate;
  final String messagingPrivacy;
  final Map<String, dynamic>? notifPrefs;
  final String? lastVoteDate;
  final String? lastSeen;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserAccount({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.coverImage,
    this.bio,
    this.website,
    this.xp = 0,
    this.weeklyXp = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.connectionsCount = 0,
    this.debatesCreated = 0,
    this.totalVotes = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.winRate = 0.0,
    this.isVerified = false,
    this.isOnline = false,
    this.isPrivate = false,
    this.messagingPrivacy = 'everyone',
    this.notifPrefs,
    this.lastVoteDate,
    this.lastSeen,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Appwrite document
  factory UserAccount.fromMap(Map<String, dynamic> map) {
    final dynamic rawNotifPrefs = map['notifPrefs'] ?? map['notif_prefs'];
    Map<String, dynamic>? notifPrefs;
    if (rawNotifPrefs is Map) {
      notifPrefs = Map<String, dynamic>.from(rawNotifPrefs);
    }

    return UserAccount(
      id: map['\$id'] ?? '',
      username: map['username'] ?? '',
      displayName: map['displayName'] ?? map['display_name'] ?? '',
      avatarUrl: map['avatarUrl'] ?? map['avatar_url'],
      coverImage: map['coverImage'] ?? map['cover_image'],
      bio: map['bio'],
      website: map['website'],
      xp: (map['xp'] ?? 0) as int,
      weeklyXp: (map['weeklyXp'] ?? map['weekly_xp'] ?? 0) as int,
      followersCount: (map['followersCount'] ?? map['followers_count'] ?? 0) as int,
      followingCount: (map['followingCount'] ?? map['following_count'] ?? 0) as int,
      connectionsCount: (map['connectionsCount'] ?? map['connections_count'] ?? 0) as int,
      debatesCreated: (map['debatesCreated'] ?? map['debates_created'] ?? 0) as int,
      totalVotes: (map['totalVotes'] ?? map['total_votes'] ?? 0) as int,
      currentStreak: (map['currentStreak'] ?? map['current_streak'] ?? 0) as int,
      longestStreak: (map['longestStreak'] ?? map['longest_streak'] ?? 0) as int,
      winRate: (map['winRate'] ?? map['win_rate'] ?? 0.0) as double,
      isVerified: (map['isVerified'] ?? map['is_verified'] ?? false) as bool,
      isOnline: (map['isOnline'] ?? map['is_online'] ?? false) as bool,
      isPrivate: (map['isPrivate'] ?? map['is_private'] ?? false) as bool,
      messagingPrivacy: (map['messagingPrivacy'] ?? map['messaging_privacy'] ?? 'everyone') as String,
      notifPrefs: notifPrefs,
      lastVoteDate: map['lastVoteDate'] ?? map['last_vote_date'],
      lastSeen: map['lastSeen'] ?? map['last_seen'],
      fcmToken: map['fcmToken'] ?? map['fcm_token'],
      createdAt: DateTime.parse(
        map['createdAt'] ?? map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] ?? map['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Convert to Appwrite document format
  Map<String, dynamic> toMap() => {
    'username': username,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'coverImage': coverImage,
    'bio': bio,
    'website': website,
    'xp': xp,
    'weeklyXp': weeklyXp,
    'followersCount': followersCount,
    'followingCount': followingCount,
    'connectionsCount': connectionsCount,
    'debatesCreated': debatesCreated,
    'totalVotes': totalVotes,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'winRate': winRate,
    'isVerified': isVerified,
    'isOnline': isOnline,
    'isPrivate': isPrivate,
    'messagingPrivacy': messagingPrivacy,
    'notifPrefs': notifPrefs,
    'lastVoteDate': lastVoteDate,
    'lastSeen': lastSeen,
    'fcmToken': fcmToken,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Create a copy with modifications
  UserAccount copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? coverImage,
    String? bio,
    String? website,
    int? xp,
    int? weeklyXp,
    int? followersCount,
    int? followingCount,
    int? connectionsCount,
    int? debatesCreated,
    int? totalVotes,
    int? currentStreak,
    int? longestStreak,
    double? winRate,
    bool? isVerified,
    bool? isOnline,
    bool? isPrivate,
    String? messagingPrivacy,
    String? fcmToken,
    DateTime? updatedAt,
  }) {
    return UserAccount(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverImage: coverImage ?? this.coverImage,
      bio: bio ?? this.bio,
      website: website ?? this.website,
      xp: xp ?? this.xp,
      weeklyXp: weeklyXp ?? this.weeklyXp,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      connectionsCount: connectionsCount ?? this.connectionsCount,
      debatesCreated: debatesCreated ?? this.debatesCreated,
      totalVotes: totalVotes ?? this.totalVotes,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      winRate: winRate ?? this.winRate,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      isPrivate: isPrivate ?? this.isPrivate,
      messagingPrivacy: messagingPrivacy ?? this.messagingPrivacy,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    username,
    displayName,
    xp,
    weeklyXp,
    isOnline,
    updatedAt,
  ];
}
