class AvailabilityModel {
  final String id;
  final String teacherId;
  final int weekday;
  final String timeSlot;
  final bool isActive;
  final String createdAt;

  AvailabilityModel({
    required this.id,
    required this.teacherId,
    required this.weekday,
    required this.timeSlot,
    required this.isActive,
    required this.createdAt,
  });

  factory AvailabilityModel.fromMap(Map<String, dynamic> map) {
    return AvailabilityModel(
      id: map['id']?.toString() ?? '',
      teacherId: map['teacher_id']?.toString() ?? '',
      weekday: map['weekday'] ?? 1,
      timeSlot: map['time_slot'] ?? '',
      isActive: map['is_active'] ?? true,
      createdAt: map['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'weekday': weekday,
      'time_slot': timeSlot,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }
}