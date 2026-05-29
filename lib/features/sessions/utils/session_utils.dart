import '../data/models/session_model.dart';

class SessionUtils {
  static const Duration videoOpenBefore = Duration(minutes: 10);
  static const Duration sessionDuration = Duration(hours: 1);

  static DateTime? safeParseDate(String date) {
    try {
      return DateTime.parse(date);
    } catch (_) {
      return null;
    }
  }

  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime? combineDateAndTime(String? date, String? time) {
    if (date == null || time == null) return null;

    final parsedDate = safeParseDate(date);
    if (parsedDate == null) return null;

    final cleanDate = normalizeDate(parsedDate);

    final parts = time.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    return DateTime(
      cleanDate.year,
      cleanDate.month,
      cleanDate.day,
      hour,
      minute,
    );
  }

  static DateTime? getSessionStart(SessionModel session) {
    return combineDateAndTime(
      session.sessionDate,
      session.sessionTime,
    );
  }

  static DateTime? getVideoOpenTime(SessionModel session) {
    final start = getSessionStart(session);
    if (start == null) return null;

    return start.subtract(videoOpenBefore);
  }

  static DateTime? getSessionEnd(SessionModel session) {
    final start = getSessionStart(session);
    if (start == null) return null;

    return start.add(sessionDuration);
  }

  static bool canJoinVideoSession(SessionModel session) {
    if (session.status == 'cancelled') return false;
    if (session.status == 'completed') return false;

    final videoOpenAt = getVideoOpenTime(session);
    final sessionEnd = getSessionEnd(session);

    if (videoOpenAt == null || sessionEnd == null) return false;

    final now = DateTime.now();

    return now.isAfter(videoOpenAt) && now.isBefore(sessionEnd);
  }

  static bool isSessionInProgress(SessionModel session) {
    if (session.status == 'cancelled') return false;
    if (session.status == 'completed') return false;

    final start = getSessionStart(session);
    final end = getSessionEnd(session);

    if (start == null || end == null) return false;

    final now = DateTime.now();

    return now.isAfter(start) && now.isBefore(end);
  }

  static bool isSessionFinished(SessionModel session) {
    if (session.status == 'cancelled') return false;

    final end = getSessionEnd(session);
    if (end == null) return false;

    return DateTime.now().isAfter(end);
  }

  static String resolveStatus(SessionModel session) {
    if (session.status == 'cancelled') return 'cancelled';
    if (session.status == 'completed') return 'completed';
    if (session.status == 'in_progress') return 'in_progress';

    if (isSessionFinished(session)) {
      return 'completed';
    }

    if (isSessionInProgress(session)) {
      return 'in_progress';
    }

    return 'upcoming';
  }

  static String getVideoJoinMessage(SessionModel session) {
    final start = getSessionStart(session);
    final videoOpenAt = getVideoOpenTime(session);
    final end = getSessionEnd(session);

    if (start == null || videoOpenAt == null || end == null) {
      return 'Görüntülü ders zamanı okunamadı.';
    }

    final now = DateTime.now();

    if (now.isBefore(videoOpenAt)) {
      return 'Görüntülü ders, başlamasına 10 dakika kala aktif olur.';
    }

    if (now.isAfter(end)) {
      return 'Bu seans için görüntülü ders süresi doldu.';
    }

    if (now.isAfter(start)) {
      return 'Ders başladı. Görüntülü derse katılabilirsin.';
    }

    return 'Görüntülü derse katılabilirsin.';
  }
}