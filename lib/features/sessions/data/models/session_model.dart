class SessionModel {
  final String id;
  final String userId;
  final String teacherId;
  final String teacherName;
  final String sessionDate;
  final String sessionTime;
  final String status;
  final String? notes;
  final String? createdAt;

  SessionModel({
    required this.id,
    required this.userId,
    required this.teacherId,
    required this.teacherName,
    required this.sessionDate,
    required this.sessionTime,
    required this.status,
    this.notes,
    this.createdAt,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      teacherId: map['teacher_id'] ?? '',
      teacherName: map['teacher_name'] ?? '',
      sessionDate: map['session_date'] ?? '',
      sessionTime: map['session_time'] ?? '',
      status: map['status'] ?? '',
      notes: map['notes'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'session_date': sessionDate,
      'session_time': sessionTime,
      'status': status,
      'notes': notes,
      'created_at': createdAt,
    };
  }
}