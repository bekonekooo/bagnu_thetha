import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

    try {
      await supabase.from('sessions').insert({
        'user_id': user.id,
        'teacher_id': teacherId,
        'teacher_name': teacherName,
        'session_date': sessionDate.toIso8601String().split('T').first,
        'session_time': sessionTime,
        'status': 'upcoming',
        'notes': notes,
      });
    } catch (e) {
      throw Exception('Bu saat dolmuş olabilir, lütfen başka bir saat seçin');
    }
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
        .eq('status', 'upcoming');

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

  DateTime? _combineDateAndTime(String date, String time) {
    try {
      final parsedDate = DateTime.parse(date);

      final parts = time.split(':');
      if (parts.length != 2) return null;

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);

      if (hour == null || minute == null) return null;

      return DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        hour,
        minute,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> markPastSessionsAsCompleted() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final response = await supabase
        .from('sessions')
        .select()
        .eq('user_id', user.id)
        .eq('status', 'upcoming');

    final sessions = (response as List)
        .map((item) => SessionModel.fromMap(item))
        .toList();

    final now = DateTime.now();

    for (final session in sessions) {
      final sessionDateTime =
          _combineDateAndTime(session.sessionDate, session.sessionTime);

      if (sessionDateTime == null) continue;

      if (sessionDateTime.isBefore(now)) {
        await supabase
            .from('sessions')
            .update({'status': 'completed'})
            .eq('id', session.id)
            .eq('user_id', user.id);
      }
    }
  }

  RealtimeChannel subscribeToTeacherSessions({
    required String teacherId,
    required VoidCallback onChange,
  }) {
    final channel = supabase.channel('teacher-sessions-$teacherId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'sessions',
      callback: (payload) {
        debugPrint('Realtime payload event: ${payload.eventType}');
        debugPrint('Realtime newRecord: ${payload.newRecord}');
        debugPrint('Realtime oldRecord: ${payload.oldRecord}');

        final newTeacherId = payload.newRecord['teacher_id']?.toString();
        final oldTeacherId = payload.oldRecord['teacher_id']?.toString();

        if (newTeacherId == teacherId || oldTeacherId == teacherId) {
          onChange();
        }
      },
    );

    channel.subscribe((status, [error]) {
      debugPrint('Realtime status: $status');
      if (error != null) {
        debugPrint('Realtime error: $error');
      }
    });

    return channel;
  }

  Future<void> removeChannel(RealtimeChannel channel) async {
    await supabase.removeChannel(channel);
  }
}