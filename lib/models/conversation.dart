import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  final String id;
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
    return Conversation(
      id: map['\$id'] ?? '',
      participant1: map['participant_1'] ?? '',
      participant2: map['participant_2'] ?? '',
      participant1Name: map['participant_1_name'],
      participant2Name: map['participant_2_name'],
      participant1Avatar: map['participant_1_avatar'],
      participant2Avatar: map['participant_2_avatar'],
      unreadCount1: map['unread_count_1'] ?? 0,
      unreadCount2: map['unread_count_2'] ?? 0,
      lastMessage: map['last_message'],
      lastMessageAt: map['last_message_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participant_1': participant1,
      'participant_2': participant2,
      'participant_1_name': participant1Name,
      'participant_2_name': participant2Name,
      'participant_1_avatar': participant1Avatar,
      'participant_2_avatar': participant2Avatar,
      'unread_count_1': unreadCount1,
      'unread_count_2': unreadCount2,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt,
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
