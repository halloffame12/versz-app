import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String id;
  final String? chatId;
  final String? conversationId;
  final String? roomId;
  final String senderId;
  final String content;
  final String type; // v3: 'text', 'image', 'video', 'audio', 'debate'
  final String messageType; // legacy alias for type
  final String status; // v3: 'sent', 'delivered', 'read'
  final bool isRead;
  final DateTime createdAt;

  const Message({
    required this.id,
    this.chatId,
    this.conversationId,
    this.roomId,
    required this.senderId,
    required this.content,
    this.type = 'text',
    this.messageType = 'text',
    this.status = 'sent',
    this.isRead = false,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    final resolvedType = (map['type'] ?? map['message_type'] ?? 'text').toString();
    final resolvedStatus = (map['status'] ?? ((map['is_read'] ?? false) ? 'read' : 'sent')).toString();
    final derivedIsRead = (map['is_read'] == true) || resolvedStatus.toLowerCase() == 'read';
    return Message(
      id: map['\$id'] ?? '',
      chatId: map['chat_id'],
      conversationId: map['conversation_id'],
      roomId: map['room_id'],
      senderId: map['sender_id'] ?? '',
      content: map['content'] ?? '',
      type: resolvedType,
      messageType: resolvedType,
      status: resolvedStatus,
      isRead: derivedIsRead,
      createdAt: DateTime.parse(map['\$createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chat_id': chatId,
      'conversation_id': conversationId,
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
      'type': type,
      'message_type': messageType,
      'status': status,
      'is_read': isRead,
    };
  }

  @override
  List<Object?> get props => [
        id, chatId, conversationId, roomId, senderId, content, type, messageType, status, isRead, createdAt,
      ];
}
