import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id;
  final String debateId;
  final String userId;
  final String username;
  final String? userAvatar;
  final String? parentId;
  final String content;
  final String? side;
  final int upvotes;
  final int downvotes;
  final int replyCount;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.debateId,
    required this.userId,
    this.username = '',
    this.userAvatar,
    this.parentId,
    required this.content,
    this.side,
    this.upvotes = 0,
    this.downvotes = 0,
    this.replyCount = 0,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['\$id'] ?? '',
      debateId: map['debateId'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      userAvatar: map['userAvatar'],
      parentId: map['parentId'],
      content: map['content'] ?? '',
      side: map['side'],
      upvotes: map['upvotes'] ?? 0,
      downvotes: map['downvotes'] ?? 0,
      replyCount: map['replyCount'] ?? 0,
      createdAt: DateTime.parse(map['\$createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'debateId': debateId,
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'parentId': parentId,
      'content': content,
      'side': side,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'replyCount': replyCount,
    };
  }

  Comment copyWith({
    String? id,
    String? debateId,
    String? userId,
    String? username,
    String? userAvatar,
    String? parentId,
    String? content,
    String? side,
    int? upvotes,
    int? downvotes,
    int? replyCount,
    DateTime? createdAt,
  }) {
    return Comment(
      id: id ?? this.id,
      debateId: debateId ?? this.debateId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      parentId: parentId ?? this.parentId,
      content: content ?? this.content,
      side: side ?? this.side,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      replyCount: replyCount ?? this.replyCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, debateId, userId, username, userAvatar, parentId, content, side,
        upvotes, downvotes, replyCount, createdAt,
      ];
}
