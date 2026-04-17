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
        .order('session_date', ascending: true)
        .order('session_time', ascending: true);

    return (response as List)
        .map((item) => SessionModel.fromMap(item))
        .toList();
  }

  Future<List<String>> fetchBookedTimes({
    required String teacherId,
    required DateTime sessionDate,
  }) async {
    final formattedDate = sessionDate.toIso8601String().split('T').first;

    final response = await supabase
        .from('sessions')
        .select('session_time')
        .eq('teacher_id', teacherId)
        .eq('session_date', formattedDate)
        .neq('status', 'cancelled');

    return (response as List)
        .map((item) => item['session_time'].toString())
        .toList();
  }

  Future<void> cancelSession(String sessionId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    await supabase
        .from('sessions')
        .update({
          'status': 'cancelled',
        })
        .eq('id', sessionId)
        .eq('user_id', user.id);
  }

  Future<void> markPastSessionsAsCompleted() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final today = DateTime.now();
    final todayString =
        DateTime(today.year, today.month, today.day).toIso8601String().split('T').first;

    await supabase
        .from('sessions')
        .update({
          'status': 'completed',
        })
        .eq('user_id', user.id)
        .eq('status', 'upcoming')
        .lt('session_date', todayString);
  }
}