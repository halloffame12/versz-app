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
      displayName: map['displayName'] ?? '',
      avatarUrl: map['avatar'],
      bannerUrl: map['coverImage'],
      bio: map['bio'],
      reputation: score,
      followersCount: map['followersCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      fcmToken: map['fcmToken'],
      createdAt: DateTime.parse(map['\$createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'displayName': displayName,
      'avatar': avatarUrl,
      'coverImage': bannerUrl,
      'bio': bio,
      'xp': reputation,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'fcmToken': fcmToken,
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
