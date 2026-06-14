class TrainingSessionModel {
  final String id;
  final String trainingId;
  final String sessionDate;
  final String startTime;
  final String endTime;
  final int sortOrder;
  final DateTime? createdAt;

  const TrainingSessionModel({
    required this.id,
    required this.trainingId,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    required this.sortOrder,
    required this.createdAt,
  });

  factory TrainingSessionModel.fromMap(Map<String, dynamic> map) {
    return TrainingSessionModel(
      id: map['id']?.toString() ?? '',
      trainingId: map['training_id']?.toString() ?? '',
      sessionDate: map['session_date']?.toString() ?? '',
      startTime: map['start_time']?.toString() ?? '',
      endTime: map['end_time']?.toString() ?? '',
      sortOrder: map['sort_order'] is int
          ? map['sort_order'] as int
          : int.tryParse(map['sort_order']?.toString() ?? '0') ?? 0,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toInsertMap({
    required String trainingId,
    required int sortOrder,
  }) {
    return {
      'training_id': trainingId,
      'session_date': sessionDate,
      'start_time': startTime,
      'end_time': endTime,
      'sort_order': sortOrder,
    };
  }

  String get formattedDate {
    final parsedDate = DateTime.tryParse(sessionDate);

    if (parsedDate == null) {
      return sessionDate;
    }

    final day = parsedDate.day.toString().padLeft(2, '0');
    final month = parsedDate.month.toString().padLeft(2, '0');
    final year = parsedDate.year.toString();

    return '$day.$month.$year';
  }

  String cleanTime(String value) {
    if (value.length >= 5) {
      return value.substring(0, 5);
    }

    return value;
  }

  String get formattedTimeRange {
    return '${cleanTime(startTime)} - ${cleanTime(endTime)}';
  }

  DateTime? get startDateTime {
    final cleanStartTime = cleanTime(startTime);
    return DateTime.tryParse('${sessionDate}T$cleanStartTime:00');
  }

  DateTime? get endDateTime {
    final cleanEndTime = cleanTime(endTime);
    return DateTime.tryParse('${sessionDate}T$cleanEndTime:00');
  }
}