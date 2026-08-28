class MeditationModel {
  final String id;
  final String? createdBy;
  final String title;
  final String description;
  final String type;
  final String category;
  final String durationText;
  final String mediaUrl;
  final String thumbnailUrl;
  final bool isActive;
  final bool isPlusOnly;
  final int viewCount;
  final int sortOrder;
  final DateTime? createdAt;

  const MeditationModel({
    required this.id,
    required this.createdBy,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.durationText,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.isActive,
    required this.isPlusOnly,
    required this.viewCount,
    required this.sortOrder,
    required this.createdAt,
  });

  factory MeditationModel.fromMap(Map<String, dynamic> map) {
    return MeditationModel(
      id: map['id']?.toString() ?? '',
      createdBy: map['created_by']?.toString(),
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      type: map['type']?.toString() ?? 'audio',
      category: map['category']?.toString() ?? '',
      durationText: map['duration_text']?.toString() ?? '',
      mediaUrl: map['media_url']?.toString() ?? '',
      thumbnailUrl: map['thumbnail_url']?.toString() ?? '',
      isActive: map['is_active'] == true,
      isPlusOnly: map['is_plus_only'] == true,
      viewCount: _readInt(map['view_count']),
      sortOrder: map['sort_order'] is int
          ? map['sort_order'] as int
          : int.tryParse(map['sort_order']?.toString() ?? '0') ?? 0,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  bool get isAudio => type == 'audio';
  bool get isVideo => type == 'video';
  bool get isLink => type == 'link';

  String get typeLabel {
    switch (type) {
      case 'audio':
        return 'Ses';
      case 'video':
        return 'Video';
      case 'link':
        return 'Link';
      default:
        return 'İçerik';
    }
  }
}
