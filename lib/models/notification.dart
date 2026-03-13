import 'package:equatable/equatable.dart';

class VerszNotification extends Equatable {
  final String id;
  final String userId;
  final String type; // 'vote', 'comment', 'reply', 'follow', 'badge', 'system'
  final String? senderId;
  final String? targetId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  const VerszNotification({
    required this.id,
    required this.userId,
    required this.type,
    this.senderId,
    this.targetId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
  });

  factory VerszNotification.fromMap(Map<String, dynamic> map) {
    return VerszNotification(
      id: map['\$id'] ?? '',
      userId: map['user_id'] ?? '',
      type: map['type'] ?? '',
      senderId: map['sender_id'],
      targetId: map['target_id'],
      content: map['content'] ?? '',
      isRead: map['is_read'] ?? false,
      createdAt: DateTime.parse(map['\$createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'type': type,
      'sender_id': senderId,
      'target_id': targetId,
      'content': content,
      'is_read': isRead,
    };
  }

  VerszNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? senderId,
    String? targetId,
    String? content,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return VerszNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      senderId: senderId ?? this.senderId,
      targetId: targetId ?? this.targetId,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, userId, type, senderId, targetId, content, isRead, createdAt,
      ];
}
