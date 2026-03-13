import 'package:equatable/equatable.dart';

class Report extends Equatable {
  final String id;
  final String reporterId;
  final String targetId;
  final String targetType; // 'debate', 'comment'
  final String reason;
  final String status; // 'pending', 'resolved'
  final DateTime createdAt;

  const Report({
    required this.id,
    required this.reporterId,
    required this.targetId,
    required this.targetType,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['\$id'] ?? '',
      reporterId: map['reporter_id'] ?? '',
      targetId: map['target_id'] ?? '',
      targetType: map['target_type'] ?? '',
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['\$createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporter_id': reporterId,
      'target_id': targetId,
      'target_type': targetType,
      'reason': reason,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id, reporterId, targetId, targetType, reason, status, createdAt,
      ];
}
