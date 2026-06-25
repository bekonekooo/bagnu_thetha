class ReportModel {
  final String id;
  final String targetType;
  final String targetId;
  final String reason;
  final String status;
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id']?.toString() ?? '',
      targetType: map['target_type']?.toString() ?? '',
      targetId: map['target_id']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
      status: map['status']?.toString() ?? 'open',
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
