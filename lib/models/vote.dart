import 'package:equatable/equatable.dart';

class Vote extends Equatable {
  final String id;
  final String userId;
  final String targetId;
  final String targetType; // 'debate', 'comment'
  final int value; // 1 for upvote, -1 for downvote
  final DateTime createdAt;

  const Vote({
    required this.id,
    required this.userId,
    required this.targetId,
    required this.targetType,
    required this.value,
    required this.createdAt,
  });

  factory Vote.fromMap(Map<String, dynamic> map) {
    return Vote(
      id: map['\$id'] ?? '',
      userId: map['user_id'] ?? '',
      targetId: map['target_id'] ?? '',
      targetType: map['target_type'] ?? '',
      value: map['value'] ?? 0,
      createdAt: DateTime.parse(map['\$createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'target_id': targetId,
      'target_type': targetType,
      'value': value,
    };
  }

  @override
  List<Object?> get props => [id, userId, targetId, targetType, value, createdAt];
}
