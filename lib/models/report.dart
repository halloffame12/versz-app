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
      reporterId: map['reporterId'] ?? '',
      targetId: map['targetId'] ?? '',
      targetType: map['targetType'] ?? '',
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['\$createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'targetId': targetId,
      'targetType': targetType,
      'reason': reason,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id, reporterId, targetId, targetType, reason, status, createdAt,
      ];
}
