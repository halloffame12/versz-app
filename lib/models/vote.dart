import 'package:equatable/equatable.dart';

/// v3 votes schema: voteId, debateId, userId, side ('agree'|'disagree'), createdAt
class Vote extends Equatable {
  final String id;
  final String debateId;
  final String userId;
  final String side; // 'agree' or 'disagree'
  final DateTime createdAt;

  const Vote({
    required this.id,
    required this.debateId,
    required this.userId,
    required this.side,
    required this.createdAt,
  });

  factory Vote.fromMap(Map<String, dynamic> map) {
    return Vote(
      id: map['\$id'] ?? '',
      debateId: map['debateId'] ?? '',
      userId: map['userId'] ?? '',
      side: map['side'] ?? 'agree',
      createdAt: DateTime.parse(map['\$createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'debateId': debateId,
      'userId': userId,
      'side': side,
    };
  }

  @override
  List<Object?> get props => [id, debateId, userId, side, createdAt];
}
