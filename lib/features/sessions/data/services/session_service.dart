import 'package:flutter_application_1/core/services/supabase_service.dart';
import '../models/session_model.dart';

class SessionService {
  Future<void> createSession({
    required String teacherId,
    required String teacherName,
    required DateTime sessionDate,
    required String sessionTime,
    String? notes,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    await supabase.from('sessions').insert({
      'user_id': user.id,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'session_date': sessionDate.toIso8601String().split('T').first,
      'session_time': sessionTime,
      'status': 'upcoming',
      'notes': notes,
    });
  }

  Future<List<SessionModel>> fetchMySessions() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final response = await supabase
        .from('sessions')
        .select()
        .eq('user_id', user.id)
        .order('session_date', ascending: true);

    return (response as List)
        .map((item) => SessionModel.fromMap(item))
        .toList();
  }
}