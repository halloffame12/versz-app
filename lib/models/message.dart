import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String id;
  final String? chatId;
  final String senderId;
  final String? senderName;
  final String? senderAvatar;
  final String content;
  final String type; // 'text', 'image', 'video', 'audio', 'debate'
  final String status; // 'sent', 'delivered', 'read', 'sending', 'failed'
  final bool isRead;
  final DateTime createdAt;

  const Message({
    required this.id,
    this.chatId,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.content,
    this.type = 'text',
    this.status = 'sent',
    this.isRead = false,
    required this.createdAt,
  });

  // Legacy read-only aliases kept so existing widget code doesn't break.
  String? get conversationId => chatId;
  String? get roomId => chatId;
  String get messageType => type;

  factory Message.fromMap(Map<String, dynamic> map) {
    final resolvedType = (map['type'] ?? 'text').toString();
    final resolvedStatus = (map['status'] ?? 'sent').toString();
    final derivedIsRead = resolvedStatus.toLowerCase() == 'read' || map['isRead'] == true;
    return Message(
      id: map['\$id'] ?? '',
      chatId: map['chatId'],
      senderId: map['senderId'] ?? '',
      senderName: map['senderName']?.toString(),
      senderAvatar: map['senderAvatar']?.toString(),
      content: map['content'] ?? '',
      type: resolvedType,
      status: resolvedStatus,
      isRead: derivedIsRead,
      createdAt: DateTime.parse(map['\$createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'type': type,
      'status': status,
    };
  }

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    String? type,
    String? status,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, chatId, senderId, senderName, senderAvatar,
        content, type, status, isRead, createdAt,
      ];
}
