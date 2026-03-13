import 'package:equatable/equatable.dart';

class UserAccount extends Equatable {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? bio;
  final int reputation;
  final int followersCount;
  final int followingCount;
  final bool isVerified;
  final String? fcmToken;
  final DateTime createdAt;

  const UserAccount({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bannerUrl,
    this.bio,
    this.reputation = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isVerified = false,
    this.fcmToken,
    required this.createdAt,
  });

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    final score = (map['xp'] ?? map['reputation'] ?? 0) as int;
    return UserAccount(
      id: map['\$id'] ?? '',
      username: map['username'] ?? '',
      displayName: map['display_name'] ?? '',
      avatarUrl: map['avatar_url'],
      bannerUrl: map['banner_url'],
      bio: map['bio'],
      reputation: score,
      followersCount: map['followers_count'] ?? 0,
      followingCount: map['following_count'] ?? 0,
      isVerified: map['is_verified'] ?? false,
      fcmToken: map['fcm_token'],
      createdAt: DateTime.parse(map['\$createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'banner_url': bannerUrl,
      'bio': bio,
      'xp': reputation,
      'reputation': reputation,
      'followers_count': followersCount,
      'following_count': followingCount,
      'is_verified': isVerified,
      'fcm_token': fcmToken,
    };
  }

  UserAccount copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bannerUrl,
    String? bio,
    int? reputation,
    int? followersCount,
    int? followingCount,
    bool? isVerified,
    String? fcmToken,
    DateTime? createdAt,
  }) {
    return UserAccount(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      bio: bio ?? this.bio,
      reputation: reputation ?? this.reputation,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isVerified: isVerified ?? this.isVerified,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, username, displayName, avatarUrl, bio,
        reputation, followersCount, followingCount,
        isVerified, fcmToken, createdAt
      ];
}
