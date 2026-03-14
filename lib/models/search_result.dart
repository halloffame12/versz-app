import 'package:equatable/equatable.dart';
import 'debate.dart';
import 'user_account.dart';

class SearchResult extends Equatable {
  final String id;
  final String type; // 'debate', 'user', 'hashtag'
  final String title;
  final String? description;
  final String? imageUrl;
  final int? score; // relevance score
  final DateTime? timestamp;

  // Embedded objects
  final Debate? debate;
  final UserAccount? user;
  final Hashtag? hashtag;

  const SearchResult({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.imageUrl,
    this.score,
    this.timestamp,
    this.debate,
    this.user,
    this.hashtag,
  });

  factory SearchResult.fromDebate(Debate debate) => SearchResult(
    id: debate.id,
    type: 'debate',
    title: debate.title,
    description: debate.description,
    imageUrl: debate.mediaUrl,
    score: debate.upvotes + debate.downvotes,
    timestamp: debate.createdAt,
    debate: debate,
  );

  factory SearchResult.fromUser(UserAccount user) => SearchResult(
    id: user.id,
    type: 'user',
    title: user.displayName,
    description: user.bio,
    imageUrl: user.avatarUrl,
    score: user.followersCount,
    timestamp: user.createdAt,
    user: user,
  );

  factory SearchResult.fromHashtag(Hashtag hashtag) => SearchResult(
    id: hashtag.id,
    type: 'hashtag',
    title: hashtag.name,
    description: 'Mentioned ${hashtag.count} times',
    score: hashtag.count,
    timestamp: hashtag.lastUsed,
    hashtag: hashtag,
  );

  @override
  List<Object?> get props => [id, type, title, description, imageUrl, score, timestamp];
}

class Hashtag extends Equatable {
  final String id;
  final String name;
  final int count;
  final DateTime lastUsed;

  const Hashtag({
    required this.id,
    required this.name,
    required this.count,
    required this.lastUsed,
  });

  factory Hashtag.fromMap(Map<String, dynamic> map) => Hashtag(
    id: map['\$id'] ?? '',
    name: map['name'] ?? '',
    count: (map['count'] ?? 0) as int,
    lastUsed: map['lastUsed'] != null
        ? DateTime.parse(map['lastUsed'])
        : DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'count': count,
    'lastUsed': lastUsed.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, name, count, lastUsed];
}
