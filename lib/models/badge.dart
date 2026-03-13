import 'package:equatable/equatable.dart';

/// v3 badges schema: badgeId, userId, badgeType, awardedAt
class UserBadge extends Equatable {
  final String id;
  final String userId;
  final String badgeType;
  final String awardedAt;

  const UserBadge({
    required this.id,
    required this.userId,
    required this.badgeType,
    required this.awardedAt,
  });

  factory UserBadge.fromMap(Map<String, dynamic> map) {
    return UserBadge(
      id: map['\$id'] ?? '',
      userId: map['userId'] ?? '',
      badgeType: map['badgeType'] ?? '',
      awardedAt: map['awardedAt'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'badgeType': badgeType,
      'awardedAt': awardedAt,
    };
  }

  String get badgeId => badgeType;

  @override
  List<Object?> get props => [id, userId, badgeType, awardedAt];
}
