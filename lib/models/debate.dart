import 'package:equatable/equatable.dart';

class Debate extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String categoryId;
  final String creatorId;
  final String mediaType; // 'text', 'image', 'video'
  final String? mediaUrl;
  final int upvotes;
  final int downvotes;
  final int commentCount;
  final int viewCount;
  final String? aiSummary;
  final String? winningSide;
  final String status; // 'active', 'closed'
  final DateTime createdAt;

  const Debate({
    required this.id,
    required this.title,
    this.description,
    required this.categoryId,
    required this.creatorId,
    required this.mediaType,
    this.mediaUrl,
    this.upvotes = 0,
    this.downvotes = 0,
    this.commentCount = 0,
    this.viewCount = 0,
    this.aiSummary,
    this.winningSide,
    required this.status,
    required this.createdAt,
  });

  factory Debate.fromMap(Map<String, dynamic> map) {
    final agree = (map['agree_count'] ?? map['upvotes'] ?? 0) as int;
    final disagree = (map['disagree_count'] ?? map['downvotes'] ?? 0) as int;
    return Debate(
      id: map['\$id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      categoryId: map['category_id'] ?? '',
      creatorId: map['creator_id'] ?? '',
      mediaType: map['media_type'] ?? 'text',
      mediaUrl: map['media_url'],
      upvotes: agree,
      downvotes: disagree,
      commentCount: map['comment_count'] ?? 0,
      viewCount: map['view_count'] ?? 0,
      aiSummary: map['ai_summary'],
      winningSide: map['winning_side'],
      status: map['status'] ?? 'active',
      createdAt: DateTime.parse(map['\$createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category_id': categoryId,
      'creator_id': creatorId,
      'media_type': mediaType,
      'media_url': mediaUrl,
      'agree_count': upvotes,
      'disagree_count': downvotes,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'comment_count': commentCount,
      'view_count': viewCount,
      'ai_summary': aiSummary,
      'winning_side': winningSide,
      'status': status,
    };
  }

  Debate copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryId,
    String? creatorId,
    String? mediaType,
    String? mediaUrl,
    int? upvotes,
    int? downvotes,
    int? commentCount,
    int? viewCount,
    String? aiSummary,
    String? winningSide,
    String? status,
    DateTime? createdAt,
  }) {
    return Debate(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      creatorId: creatorId ?? this.creatorId,
      mediaType: mediaType ?? this.mediaType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      commentCount: commentCount ?? this.commentCount,
      viewCount: viewCount ?? this.viewCount,
      aiSummary: aiSummary ?? this.aiSummary,
      winningSide: winningSide ?? this.winningSide,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, title, description, categoryId, creatorId,
        mediaType, mediaUrl, upvotes, downvotes,
        commentCount, viewCount, aiSummary, winningSide, status, createdAt,
      ];
}
