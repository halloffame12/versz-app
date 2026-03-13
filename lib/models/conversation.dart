import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Maps to v3 chats collection.
/// Schema: chatId, participants (array), isGroup, groupName, groupAvatar,
///   adminIds, lastMessage, lastMessageType, lastMessageSenderId,
///   lastMessageTime, unreadCounts, createdAt, updatedAt
class Conversation extends Equatable {
  final String id;
  // Extracted from the participants array for easy access.
  final String participant1;
  final String participant2;
  final String? participant1Name;
  final String? participant2Name;
  final String? participant1Avatar;
  final String? participant2Avatar;
  final int unreadCount1;
  final int unreadCount2;
  final String? lastMessage;
  final String? lastMessageAt;

  const Conversation({
    required this.id,
    required this.participant1,
    required this.participant2,
    this.participant1Name,
    this.participant2Name,
    this.participant1Avatar,
    this.participant2Avatar,
    this.unreadCount1 = 0,
    this.unreadCount2 = 0,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory Conversation.fromMap(Map<String, dynamic> map) {
    // Parse participants: v3 uses an array of user IDs.
    String p1 = '', p2 = '';
    final rawParticipants = map['participants'];
    if (rawParticipants is List && rawParticipants.length >= 2) {
      p1 = rawParticipants[0].toString();
      p2 = rawParticipants[1].toString();
    } else if (rawParticipants is String && rawParticipants.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawParticipants) as List;
        p1 = decoded.isNotEmpty ? decoded[0].toString() : '';
        p2 = decoded.length > 1 ? decoded[1].toString() : '';
      } catch (_) {}
    }
    return Conversation(
      id: map['\$id'] ?? '',
      participant1: p1,
      participant2: p2,
      unreadCount1: 0,
      unreadCount2: 0,
      lastMessage: map['lastMessage'],
      lastMessageAt: map['lastMessageTime']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': [participant1, participant2],
      'isGroup': false,
      'lastMessage': lastMessage ?? '',
      'lastMessageTime': lastMessageAt ?? DateTime.now().toIso8601String(),
      'unreadCounts': jsonEncode({participant1: unreadCount1, participant2: unreadCount2}),
    };
  }

  Conversation copyWith({
    String? id,
    String? participant1,
    String? participant2,
    String? participant1Name,
    String? participant2Name,
    String? participant1Avatar,
    String? participant2Avatar,
    int? unreadCount1,
    int? unreadCount2,
    String? lastMessage,
    String? lastMessageAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      participant1: participant1 ?? this.participant1,
      participant2: participant2 ?? this.participant2,
      participant1Name: participant1Name ?? this.participant1Name,
      participant2Name: participant2Name ?? this.participant2Name,
      participant1Avatar: participant1Avatar ?? this.participant1Avatar,
      participant2Avatar: participant2Avatar ?? this.participant2Avatar,
      unreadCount1: unreadCount1 ?? this.unreadCount1,
      unreadCount2: unreadCount2 ?? this.unreadCount2,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }

  @override
  List<Object?> get props => [
      id,
      participant1,
      participant2,
      participant1Name,
      participant2Name,
      participant1Avatar,
      participant2Avatar,
      unreadCount1,
      unreadCount2,
      lastMessage,
      lastMessageAt,
    ];
}
