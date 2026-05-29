import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_application_1/core/services/supabase_service.dart';
import 'package:flutter_application_1/features/notifications/data/services/notification_service.dart';

import '../models/session_model.dart';

class SessionService {
  static const Duration sessionDuration = Duration(hours: 1);

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

      final teacherResponse = await supabase
          .from('teachers')
          .select('user_id')
          .eq('id', teacherId)
          .maybeSingle();

      final teacherUserId = teacherResponse?['user_id']?.toString();

      if (teacherUserId != null && teacherUserId.isNotEmpty) {
        await NotificationService().createNotification(
          userId: teacherUserId,
          title: 'Yeni Seans Rezervasyonu',
          message:
              '$teacherName için ${sessionDate.toIso8601String().split('T').first} - $sessionTime saatinde yeni bir seans oluşturuldu.',
          type: 'booking',
        );
      }
    } catch (e) {
      throw Exception('Bu saat dolmuş olabilir, lütfen başka bir saat seçin');
    }
  }

  Future<List<SessionModel>> fetchMySessions() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    await syncMySessionStatuses();

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
        .inFilter('status', ['upcoming', 'in_progress']);

    return (response as List)
        .map((item) => item['session_time'].toString())
        .toList();
  }

  Future<void> cancelSession(String sessionId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final updatedSessions = await supabase
        .from('sessions')
        .update({'status': 'cancelled'})
        .eq('id', sessionId)
        .eq('user_id', user.id)
        .inFilter('status', ['upcoming', 'in_progress'])
        .select();

    if ((updatedSessions as List).isEmpty) {
      throw Exception('Seans iptal edilemedi veya zaten iptal edilmiş.');
    }

    final session = updatedSessions.first;

    final teacherId = session['teacher_id']?.toString();
    final teacherName = session['teacher_name']?.toString() ?? 'Öğretmen';
    final sessionDate = session['session_date']?.toString() ?? '';
    final sessionTime = session['session_time']?.toString() ?? '';

    if (teacherId == null || teacherId.isEmpty) return;

    final teacherResponse = await supabase
        .from('teachers')
        .select('user_id')
        .eq('id', teacherId)
        .maybeSingle();

    final teacherUserId = teacherResponse?['user_id']?.toString();

    if (teacherUserId != null && teacherUserId.isNotEmpty) {
      await NotificationService().createNotification(
        userId: teacherUserId,
        title: 'Seans Öğrenci Tarafından İptal Edildi',
        message:
            '$teacherName için $sessionDate - $sessionTime seansı öğrenci tarafından iptal edildi.',
        type: 'student_cancelled',
      );
    }
  }

  DateTime? _combineDateAndTime(String date, String time) {
    try {
      final parsedDate = DateTime.parse(date);
      final parts = time.split(':');

      if (parts.length < 2) return null;

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

  String _resolveDatabaseStatus(SessionModel session) {
    if (session.status == 'cancelled') return 'cancelled';
    if (session.status == 'completed') return 'completed';

    final sessionStart = _combineDateAndTime(
      session.sessionDate,
      session.sessionTime,
    );

    if (sessionStart == null) return session.status;

    final sessionEnd = sessionStart.add(sessionDuration);
    final now = DateTime.now();

    if (now.isAfter(sessionEnd)) {
      return 'completed';
    }

    if (now.isAfter(sessionStart) && now.isBefore(sessionEnd)) {
      return 'in_progress';
    }

    return 'upcoming';
  }

  Future<void> syncMySessionStatuses() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final response = await supabase
        .from('sessions')
        .select()
        .eq('user_id', user.id)
        .inFilter('status', ['upcoming', 'in_progress']);

    final sessions = (response as List)
        .map((item) => SessionModel.fromMap(item))
        .toList();

    for (final session in sessions) {
      final newStatus = _resolveDatabaseStatus(session);

      if (newStatus != session.status) {
        await supabase
            .from('sessions')
            .update({'status': newStatus})
            .eq('id', session.id)
            .eq('user_id', user.id);
      }
    }
  }

  Future<void> syncTeacherSessionStatuses() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final teacherResponse = await supabase
        .from('teachers')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (teacherResponse == null) {
      throw Exception(
        'Bu hesaba bağlı öğretmen profili yok.\nSupabase → teachers.user_id kontrol et.',
      );
    }

    final teacherId = teacherResponse['id'].toString();

    final response = await supabase
        .from('sessions')
        .select()
        .eq('teacher_id', teacherId)
        .inFilter('status', ['upcoming', 'in_progress']);

    final sessions = (response as List)
        .map((item) => SessionModel.fromMap(item))
        .toList();

    for (final session in sessions) {
      final newStatus = _resolveDatabaseStatus(session);

      if (newStatus != session.status) {
        await supabase
            .from('sessions')
            .update({'status': newStatus})
            .eq('id', session.id)
            .eq('teacher_id', teacherId);
      }
    }
  }

  Future<void> markPastSessionsAsCompleted() async {
    await syncMySessionStatuses();
  }

  Future<String> fetchMyTeacherId() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final teacherResponse = await supabase
        .from('teachers')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (teacherResponse == null) {
      throw Exception(
        'Bu hesaba bağlı öğretmen profili yok.\nSupabase → teachers.user_id kontrol et.',
      );
    }

    return teacherResponse['id'].toString();
  }

  Future<void> cancelTeacherSession(String sessionId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final teacherResponse = await supabase
        .from('teachers')
        .select('id')
        .eq('user_id', user.id)
        .limit(1);

    if ((teacherResponse as List).isEmpty) {
      throw Exception(
        'Bu hesaba bağlı öğretmen profili yok. teachers.user_id alanını kontrol et.',
      );
    }

    final teacherId = teacherResponse.first['id'].toString();

    final updatedSessions = await supabase
        .from('sessions')
        .update({'status': 'cancelled'})
        .eq('id', sessionId)
        .eq('teacher_id', teacherId)
        .inFilter('status', ['upcoming', 'in_progress'])
        .select();

    if ((updatedSessions as List).isEmpty) {
      throw Exception(
        'Seans güncellenemedi. sessions.teacher_id ile teachers.id eşleşmiyor olabilir veya RLS UPDATE izni eksik.',
      );
    }

    final session = updatedSessions.first;
    final studentUserId = session['user_id']?.toString();

    if (studentUserId != null && studentUserId.isNotEmpty) {
      await NotificationService().createNotification(
        userId: studentUserId,
        title: 'Seans İptal Edildi',
        message:
            '${session['session_date']} - ${session['session_time']} seansınız öğretmen tarafından iptal edildi.',
        type: 'cancelled',
      );
    }
  }

  Future<List<SessionModel>> fetchTeacherSessions() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    await syncTeacherSessionStatuses();

    final teacherResponse = await supabase
        .from('teachers')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (teacherResponse == null) {
      throw Exception(
        'Bu hesaba bağlı öğretmen profili yok.\nSupabase → teachers.user_id kontrol et.',
      );
    }

    final teacherId = teacherResponse['id'].toString();

    final sessionsResponse = await supabase
        .from('sessions')
        .select()
        .eq('teacher_id', teacherId)
        .order('session_date', ascending: true)
        .order('session_time', ascending: true);

    final sessions = List<Map<String, dynamic>>.from(sessionsResponse);

    final userIds = sessions
        .map((session) => session['user_id']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    if (userIds.isEmpty) {
      return sessions.map((item) => SessionModel.fromMap(item)).toList();
    }

    final profilesResponse = await supabase
        .from('profiles')
        .select('id, full_name')
        .inFilter('id', userIds);

    final profiles = List<Map<String, dynamic>>.from(profilesResponse);

    final profileMap = {
      for (final profile in profiles)
        profile['id'].toString(): profile['full_name']?.toString(),
    };

    final sessionsWithStudentNames = sessions.map((session) {
      return {
        ...session,
        'student_name': profileMap[session['user_id'].toString()],
      };
    }).toList();

    return sessionsWithStudentNames
        .map((item) => SessionModel.fromMap(item))
        .toList();
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
        final newTeacherId = payload.newRecord['teacher_id']?.toString();
        final oldTeacherId = payload.oldRecord['teacher_id']?.toString();

        if (newTeacherId == teacherId || oldTeacherId == teacherId) {
          onChange();
        }
      },
    );

    channel.subscribe();

    return channel;
  }

  Future<void> removeChannel(RealtimeChannel channel) async {
    await supabase.removeChannel(channel);
  }
}