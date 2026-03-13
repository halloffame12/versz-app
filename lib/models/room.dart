import 'package:equatable/equatable.dart';

/// Maps to v3 communities collection.
/// Schema: communityId, name, description, banner, avatar, creatorId,
///   category, memberCount, debateCount, isPrivate, createdAt, updatedAt
class Room extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String creatorId;
  final String? iconUrl;   // maps to 'avatar'
  final String? bannerUrl; // maps to 'banner'
  final int membersCount;
  final DateTime createdAt;

  const Room({
    required this.id,
    required this.name,
    this.description,
    required this.creatorId,
    this.iconUrl,
    this.bannerUrl,
    this.membersCount = 0,
    required this.createdAt,
  });

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['\$id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      creatorId: map['creatorId'] ?? '',
      iconUrl: map['avatar'],
      bannerUrl: map['banner'],
      membersCount: map['memberCount'] ?? 0,
      createdAt: DateTime.parse(map['\$createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'avatar': iconUrl,
      'banner': bannerUrl,
      'memberCount': membersCount,
    };
  }

  @override
  List<Object?> get props => [
        id, name, description, creatorId, iconUrl, bannerUrl, membersCount, createdAt,
      ];

  int? get memberCount => membersCount > 0 ? membersCount : null;
}

/// Maps to v3 community_members collection.
/// Schema: memberId, communityId, userId, role, status, joinedAt
class RoomMember extends Equatable {
  final String id;
  final String roomId;   // maps to 'communityId'
  final String userId;
  final String role;
  final DateTime createdAt;

  const RoomMember({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.role,
    required this.createdAt,
  });

  factory RoomMember.fromMap(Map<String, dynamic> map) {
    return RoomMember(
      id: map['\$id'] ?? '',
      roomId: map['communityId'] ?? '',
      userId: map['userId'] ?? '',
      role: map['role'] ?? 'member',
      createdAt: DateTime.parse(map['\$createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'communityId': roomId,
      'userId': userId,
      'role': role,
    };
  }

  @override
  List<Object?> get props => [id, roomId, userId, role, createdAt];
}
