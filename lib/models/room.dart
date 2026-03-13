import 'package:equatable/equatable.dart';

class Room extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String creatorId;
  final String? iconUrl;
  final String? bannerUrl;
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
      creatorId: map['creator_id'] ?? '',
      iconUrl: map['icon_url'],
      bannerUrl: map['banner_url'],
      membersCount: map['members_count'] ?? 0,
      createdAt: DateTime.parse(map['\$createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'creator_id': creatorId,
      'icon_url': iconUrl,
      'banner_url': bannerUrl,
      'members_count': membersCount,
    };
  }

  @override
  List<Object?> get props => [
        id, name, description, creatorId, iconUrl, bannerUrl, membersCount, createdAt,
      ];

  int? get memberCount => membersCount > 0 ? membersCount : null;
}

class RoomMember extends Equatable {
  final String id;
  final String roomId;
  final String userId;
  final String role; // 'admin', 'moderator', 'member'
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
      roomId: map['room_id'] ?? '',
      userId: map['user_id'] ?? '',
      role: map['role'] ?? 'member',
      createdAt: DateTime.parse(map['\$createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'room_id': roomId,
      'user_id': userId,
      'role': role,
    };
  }

  @override
  List<Object?> get props => [id, roomId, userId, role, createdAt];
}
