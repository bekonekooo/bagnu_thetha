class AvailabilityModel {
  final String id;
  final String teacherId;
  final int weekday;
  final String timeSlot;
  final bool isActive;

  AvailabilityModel({
    required this.id,
    required this.teacherId,
    required this.weekday,
    required this.timeSlot,
    required this.isActive,
  });

  factory AvailabilityModel.fromMap(Map<String, dynamic> map) {
    return AvailabilityModel(
      id: map['id']?.toString() ?? '',
      teacherId: map['teacher_id']?.toString() ?? '',
      weekday: map['weekday'] ?? 0,
      timeSlot: map['time_slot'] ?? '',
      isActive: map['is_active'] ?? true,
    );
  }
}