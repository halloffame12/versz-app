import 'package:equatable/equatable.dart';

class UserBadge extends Equatable {
  final String id;
  final String userId;
  final String badgeId;
  final String earnedAt;

  const UserBadge({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
  });

  factory UserBadge.fromMap(Map<String, dynamic> map) {
    return UserBadge(
      id: map['\$id'] ?? '',
      userId: map['user_id'] ?? '',
      badgeId: map['badge_id'] ?? '',
      earnedAt: map['earned_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'badge_id': badgeId,
      'earned_at': earnedAt,
    };
  }

  @override
  List<Object?> get props => [id, userId, badgeId, earnedAt];
}
