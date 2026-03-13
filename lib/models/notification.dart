import 'package:equatable/equatable.dart';

class VerszNotification extends Equatable {
  final String id;
  final String userId;
  final String? senderId;
  final String type;
  final String title;
  final String body;
  final String? payload;
  final bool isRead;
  final DateTime createdAt;

  const VerszNotification({
    required this.id,
    required this.userId,
    this.senderId,
    required this.type,
    this.title = '',
    this.body = '',
    this.payload,
    this.isRead = false,
    required this.createdAt,
  });

  factory VerszNotification.fromMap(Map<String, dynamic> map) {
    return VerszNotification(
      id: map['\$id'] ?? '',
      userId: map['userId'] ?? '',
      senderId: map['senderId']?.toString(),
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      payload: map['payload']?.toString(),
      isRead: map['read'] ?? false,
      createdAt: DateTime.parse(map['\$createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'senderId': senderId,
      'type': type,
      'title': title,
      'body': body,
      'payload': payload,
      'read': isRead,
    };
  }

  VerszNotification copyWith({
    String? id,
    String? userId,
    String? senderId,
    String? type,
    String? title,
    String? body,
    String? payload,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return VerszNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      payload: payload ?? this.payload,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get content => body;

  @override
  List<Object?> get props => [
    id, userId, senderId, type, title, body, payload, isRead, createdAt,
  ];
}
