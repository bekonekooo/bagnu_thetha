import '../data/models/session_model.dart';

class SessionUtils {
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
    if (parts.length != 2) return null;

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

  static bool isPastSession(SessionModel session) {
    final dt = combineDateAndTime(session.sessionDate, session.sessionTime);
    if (dt == null) return false;

    return dt.isBefore(DateTime.now());
  }

  static String resolveStatus(SessionModel session) {
    if (session.status == 'cancelled') return 'cancelled';
    if (session.status == 'completed') return 'completed';

    if (isPastSession(session)) {
      return 'completed';
    }

    return 'upcoming';
  }
}