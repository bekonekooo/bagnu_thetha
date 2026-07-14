class WorkshopDayModel {
  final String id;
  final String workshopId;
  final int dayNumber;
  final String title;
  final String description;
  final String contentType;
  final String contentUrl;
  final String durationText;
  final DateTime? createdAt;

  const WorkshopDayModel({
    required this.id,
    required this.workshopId,
    required this.dayNumber,
    required this.title,
    required this.description,
    required this.contentType,
    required this.contentUrl,
    required this.durationText,
    required this.createdAt,
  });

  factory WorkshopDayModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return WorkshopDayModel(
      id: map['id']?.toString() ?? '',
      workshopId: map['workshop_id']?.toString() ?? '',
      dayNumber: map['day_number'] is int
          ? map['day_number'] as int
          : int.tryParse(
                map['day_number']?.toString() ?? '1',
              ) ??
              1,
      title: map['title']?.toString() ?? '',
      description:
          map['description']?.toString() ?? '',
      contentType:
          map['content_type']?.toString() ?? 'audio',
      contentUrl:
          map['content_url']?.toString() ?? '',
      durationText:
          map['duration_text']?.toString() ?? '',
      createdAt: DateTime.tryParse(
        map['created_at']?.toString() ?? '',
      ),
    );
  }

  bool get isAudio => contentType == 'audio';

  bool get isVideo => contentType == 'video';

  bool get isLink => contentType == 'link';

  String get contentTypeLabel {
    switch (contentType) {
      case 'audio':
        return 'Ses';
      case 'video':
        return 'Video';
      case 'link':
        return 'Bağlantı';
      default:
        return 'İçerik';
    }
  }
}