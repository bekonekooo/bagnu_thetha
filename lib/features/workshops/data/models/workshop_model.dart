import 'package:flutter_application_1/features/workshops/data/models/workshop_day_model.dart';

class WorkshopModel {
  final String id;
  final String teacherId;
  final String createdBy;

  final String title;
  final String description;
  final String imageUrl;
  final String category;

  final int durationDays;

  final double price;
  final String currency;
  final int? capacity;

  final bool isActive;

  final String teacherName;
  final String teacherImageUrl;
  final String teacherSpecialty;

  final List<WorkshopDayModel> days;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WorkshopModel({
    required this.id,
    required this.teacherId,
    required this.createdBy,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.durationDays,
    required this.price,
    required this.currency,
    required this.capacity,
    required this.isActive,
    required this.teacherName,
    required this.teacherImageUrl,
    required this.teacherSpecialty,
    required this.days,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkshopModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final teacherMap = map['teachers'];
    final rawDays = map['workshop_days'];

    final parsedDays = rawDays is List
        ? rawDays.map((item) {
            return WorkshopDayModel.fromMap(
              Map<String, dynamic>.from(
                item as Map,
              ),
            );
          }).toList()
        : <WorkshopDayModel>[];

    parsedDays.sort(
      (a, b) => a.dayNumber.compareTo(b.dayNumber),
    );

    return WorkshopModel(
      id: map['id']?.toString() ?? '',
      teacherId:
          map['teacher_id']?.toString() ?? '',
      createdBy:
          map['created_by']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description:
          map['description']?.toString() ?? '',
      imageUrl:
          map['image_url']?.toString() ?? '',
      category:
          map['category']?.toString() ?? '',
      durationDays: map['duration_days'] is int
          ? map['duration_days'] as int
          : int.tryParse(
                map['duration_days']?.toString() ?? '1',
              ) ??
              1,
      price:
          double.tryParse(map['price']?.toString() ?? '0') ??
              0,
      currency:
          map['currency']?.toString() ?? 'try',
      capacity: map['capacity'] == null
          ? null
          : int.tryParse(
              map['capacity'].toString(),
            ),
      isActive: map['is_active'] == true,
      teacherName: teacherMap is Map
          ? teacherMap['name']?.toString() ?? ''
          : '',
      teacherImageUrl: teacherMap is Map
          ? teacherMap['image_url']?.toString() ?? ''
          : '',
      teacherSpecialty: teacherMap is Map
          ? teacherMap['specialty']?.toString() ?? ''
          : '',
      days: parsedDays,
      createdAt: DateTime.tryParse(
        map['created_at']?.toString() ?? '',
      ),
      updatedAt: DateTime.tryParse(
        map['updated_at']?.toString() ?? '',
      ),
    );
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

  String get durationLabel {
    return '$durationDays Günlük Atölye';
  }

  String get capacityLabel {
    if (capacity == null) {
      return 'Sınırsız Katılım';
    }

    return '$capacity Kişilik';
  }
}