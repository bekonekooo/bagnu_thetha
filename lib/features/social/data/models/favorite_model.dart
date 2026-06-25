class FavoriteModel {
  final String id;
  final String targetType;
  final String targetId;
  final DateTime createdAt;

  const FavoriteModel({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
  });

  factory FavoriteModel.fromMap(Map<String, dynamic> map) {
    return FavoriteModel(
      id: map['id']?.toString() ?? '',
      targetType: map['target_type']?.toString() ?? '',
      targetId: map['target_id']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
