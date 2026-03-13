import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String emoji;
  final String color;
  final int debateCount;

  const Category({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.debateCount = 0,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['\$id'] ?? '',
      name: map['name'] ?? '',
      emoji: map['emoji'] ?? '',
      color: map['color'] ?? '',
      debateCount: map['debate_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'emoji': emoji,
      'color': color,
      'debate_count': debateCount,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? emoji,
    String? color,
    int? debateCount,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      debateCount: debateCount ?? this.debateCount,
    );
  }

  @override
  List<Object?> get props => [id, name, emoji, color, debateCount];
}
