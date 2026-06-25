import 'package:flutter_application_1/features/trainings/data/models/training_session_model.dart';

class TrainingModel {
  final String id;
  final String? teacherId;
  final String? createdBy;

  final String title;
  final String description;
  final String imageUrl;
  final String category;

  final String locationType;
  final String locationText;

  final double price;
  final String currency;
  final int? capacity;

  final bool isActive;
  final DateTime? createdAt;

  final String teacherName;
  final String teacherImageUrl;
  final String teacherSpecialty;

  final int likeCount;
  final double ratingAvg;
  final int ratingCount;
  final int commentCount;

  final List<TrainingSessionModel> sessions;

  const TrainingModel({
    required this.id,
    required this.teacherId,
    required this.createdBy,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.locationType,
    required this.locationText,
    required this.price,
    required this.currency,
    required this.capacity,
    required this.isActive,
    required this.createdAt,
    required this.teacherName,
    required this.teacherImageUrl,
    required this.teacherSpecialty,
    this.likeCount = 0,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.commentCount = 0,
    required this.sessions,
  });

  factory TrainingModel.fromMap(Map<String, dynamic> map) {
    final teacherMap = map['teachers'];
    final rawSessions = map['training_sessions'];

    final parsedSessions = rawSessions is List
        ? rawSessions
            .map(
              (item) => TrainingSessionModel.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList()
        : <TrainingSessionModel>[];

    parsedSessions.sort((a, b) {
      final dateCompare = a.sessionDate.compareTo(b.sessionDate);

      if (dateCompare != 0) {
        return dateCompare;
      }

      return a.startTime.compareTo(b.startTime);
    });

    return TrainingModel(
      id: map['id']?.toString() ?? '',
      teacherId: map['teacher_id']?.toString(),
      createdBy: map['created_by']?.toString(),
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      imageUrl: map['image_url']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      locationType: map['location_type']?.toString() ?? 'online',
      locationText: map['location_text']?.toString() ?? '',
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0,
      currency: map['currency']?.toString() ?? 'try',
      capacity: map['capacity'] == null
          ? null
          : int.tryParse(map['capacity'].toString()),
      isActive: map['is_active'] == true,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
      teacherName:
          teacherMap is Map ? teacherMap['name']?.toString() ?? '' : '',
      teacherImageUrl:
          teacherMap is Map ? teacherMap['image_url']?.toString() ?? '' : '',
      teacherSpecialty:
          teacherMap is Map ? teacherMap['specialty']?.toString() ?? '' : '',
      likeCount: int.tryParse(map['like_count']?.toString() ?? '0') ?? 0,
      ratingAvg: double.tryParse(map['rating_avg']?.toString() ?? '0') ?? 0,
      ratingCount: int.tryParse(map['rating_count']?.toString() ?? '0') ?? 0,
      commentCount: int.tryParse(map['comment_count']?.toString() ?? '0') ?? 0,
      sessions: parsedSessions,
    );
  }

  DateTime? get firstStartDateTime {
    if (sessions.isEmpty) return null;

    final validDates = sessions
        .map((session) => session.startDateTime)
        .whereType<DateTime>()
        .toList();

    if (validDates.isEmpty) return null;

    validDates.sort();
    return validDates.first;
  }

  DateTime? get lastEndDateTime {
    if (sessions.isEmpty) return null;

    final validDates = sessions
        .map((session) => session.endDateTime)
        .whereType<DateTime>()
        .toList();

    if (validDates.isEmpty) return null;

    validDates.sort();
    return validDates.last;
  }

  bool get isUpcoming {
    final firstStart = firstStartDateTime;

    if (firstStart == null) return false;

    return firstStart.isAfter(DateTime.now());
  }

  bool get isOngoing {
    final firstStart = firstStartDateTime;
    final lastEnd = lastEndDateTime;

    if (firstStart == null || lastEnd == null) return false;

    final now = DateTime.now();

    return !now.isBefore(firstStart) && !now.isAfter(lastEnd);
  }

  bool get isCompleted {
    final lastEnd = lastEndDateTime;

    if (lastEnd == null) return false;

    return lastEnd.isBefore(DateTime.now());
  }

  String get statusLabel {
    if (isUpcoming) return 'Yaklaşan';
    if (isOngoing) return 'Devam Eden';
    if (isCompleted) return 'Bitmiş';

    return 'Planlanıyor';
  }

  String get formattedPrice {
    if (price <= 0) {
      return 'Ücretsiz';
    }

    final cleanPrice = price % 1 == 0
        ? price.toInt().toString()
        : price.toStringAsFixed(2);

    if (currency.toLowerCase() == 'try') {
      return '₺$cleanPrice';
    }

    return '$cleanPrice ${currency.toUpperCase()}';
  }

  String get formattedLocationType {
    if (locationType == 'online') {
      return 'Online';
    }

    if (locationType == 'face_to_face') {
      return 'Yüz Yüze';
    }

    return locationType;
  }

  String get firstDateText {
    final firstStart = firstStartDateTime;

    if (firstStart == null) return 'Tarih belirtilmemiş';

    final day = firstStart.day.toString().padLeft(2, '0');
    final month = firstStart.month.toString().padLeft(2, '0');
    final year = firstStart.year.toString();

    return '$day.$month.$year';
  }
}