import 'package:flutter_application_1/core/services/supabase_service.dart';
import 'package:flutter_application_1/features/trainings/data/models/training_model.dart';

class TrainingService {
  Future<List<TrainingModel>> fetchActiveTrainings() async {
    final response = await supabase
        .from('trainings')
        .select('''
          *,
          teachers (
            id,
            name,
            specialty,
            image_url
          ),
          training_sessions (
            id,
            training_id,
            session_date,
            start_time,
            end_time,
            sort_order,
            created_at
          )
        ''')
        .eq('is_active', true)
        .order('created_at', ascending: false);

    final trainings = (response as List)
        .map(
          (item) => TrainingModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    trainings.sort((a, b) {
      final aDate = a.firstStartDateTime;
      final bDate = b.firstStartDateTime;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return aDate.compareTo(bDate);
    });

    return trainings;
  }

  Future<List<TrainingModel>> fetchActiveTrainingsByTeacherId(
  String teacherId,
) async {
  final cleanTeacherId = teacherId.trim();

  if (cleanTeacherId.isEmpty) {
    return [];
  }

  final response = await supabase
      .from('trainings')
      .select('''
        *,
        teachers (
          id,
          name,
          specialty,
          image_url
        ),
        training_sessions (
          id,
          training_id,
          session_date,
          start_time,
          end_time,
          sort_order,
          created_at
        )
      ''')
      .eq('teacher_id', cleanTeacherId)
      .eq('is_active', true)
      .order('created_at', ascending: false);

  final trainings = (response as List)
      .map(
        (item) => TrainingModel.fromMap(
          Map<String, dynamic>.from(item as Map),
        ),
      )
      .toList();

  trainings.sort((a, b) {
    final aDate = a.firstStartDateTime;
    final bDate = b.firstStartDateTime;

    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;

    return aDate.compareTo(bDate);
  });

  return trainings;
}



  Future<List<TrainingModel>> fetchMyTeacherTrainings() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Devam etmek için giriş yapmalısın.');
    }

    final response = await supabase
        .from('trainings')
        .select('''
          *,
          teachers (
            id,
            name,
            specialty,
            image_url
          ),
          training_sessions (
            id,
            training_id,
            session_date,
            start_time,
            end_time,
            sort_order,
            created_at
          )
        ''')
        .eq('created_by', user.id)
        .order('created_at', ascending: false);

    final trainings = (response as List)
        .map(
          (item) => TrainingModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    trainings.sort((a, b) {
      final aDate = a.firstStartDateTime;
      final bDate = b.firstStartDateTime;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return aDate.compareTo(bDate);
    });

    return trainings;
  }

  Future<String> fetchMyTeacherId() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Devam etmek için giriş yapmalısın.');
    }

    final response = await supabase
        .from('teachers')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    final teacherId = response?['id']?.toString();

    if (teacherId == null || teacherId.isEmpty) {
      throw Exception('Bu hesaba bağlı öğretmen profili bulunamadı.');
    }

    return teacherId;
  }

  DateTime _parseSessionDateTime({
    required String sessionDate,
    required String timeText,
  }) {
    final cleanTime = timeText.length == 5 ? '$timeText:00' : timeText;

    return DateTime.parse('$sessionDate $cleanTime');
  }

  Future<void> createTraining({
    required String title,
    required String description,
    required String imageUrl,
    required String category,
    required String locationType,
    required String locationText,
    required double price,
    required String currency,
    required int? capacity,
    required List<Map<String, dynamic>> sessions,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Devam etmek için giriş yapmalısın.');
    }

    if (sessions.isEmpty) {
      throw Exception('En az bir eğitim günü/saat aralığı eklemelisin.');
    }

    final teacherId = await fetchMyTeacherId();

    final sortedSessions = [...sessions];

    sortedSessions.sort((a, b) {
      final aDate = a['session_date']?.toString() ?? '';
      final bDate = b['session_date']?.toString() ?? '';

      final dateCompare = aDate.compareTo(bDate);

      if (dateCompare != 0) {
        return dateCompare;
      }

      final aStart = a['start_time']?.toString() ?? '';
      final bStart = b['start_time']?.toString() ?? '';

      return aStart.compareTo(bStart);
    });

    final firstSession = sortedSessions.first;
    final lastSession = sortedSessions.last;

    final firstSessionDate = firstSession['session_date']?.toString();
    final firstStartTime = firstSession['start_time']?.toString();

    final lastSessionDate = lastSession['session_date']?.toString();
    final lastEndTime = lastSession['end_time']?.toString();

    if (firstSessionDate == null ||
        firstSessionDate.isEmpty ||
        firstStartTime == null ||
        firstStartTime.isEmpty ||
        lastSessionDate == null ||
        lastSessionDate.isEmpty ||
        lastEndTime == null ||
        lastEndTime.isEmpty) {
      throw Exception('Eğitim gün/saat bilgileri eksik.');
    }

    final startAt = _parseSessionDateTime(
      sessionDate: firstSessionDate,
      timeText: firstStartTime,
    );

    final endAt = _parseSessionDateTime(
      sessionDate: lastSessionDate,
      timeText: lastEndTime,
    );

    final trainingResponse = await supabase
        .from('trainings')
        .insert({
          'teacher_id': teacherId,
          'created_by': user.id,
          'title': title,
          'description': description,
          'image_url': imageUrl.trim().isEmpty ? null : imageUrl.trim(),
          'category': category.trim().isEmpty ? null : category.trim(),
          'location_type': locationType,
          'location_text':
              locationText.trim().isEmpty ? null : locationText.trim(),
          'price': price,
          'currency': currency,
          'capacity': capacity,
          'start_at': startAt.toIso8601String(),
          'end_at': endAt.toIso8601String(),
          'is_active': false,
        })
        .select('id')
        .single();

    final trainingId = trainingResponse['id']?.toString();

    if (trainingId == null || trainingId.isEmpty) {
      throw Exception('Eğitim oluşturulamadı.');
    }

    final sessionRows = sortedSessions.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      return {
        'training_id': trainingId,
        'session_date': item['session_date'],
        'start_time': item['start_time'],
        'end_time': item['end_time'],
        'sort_order': index,
      };
    }).toList();

    await supabase.from('training_sessions').insert(sessionRows);
  }

  Future<void> toggleTrainingActive({
    required String trainingId,
    required bool isActive,
  }) async {
    await supabase
        .from('trainings')
        .update({
          'is_active': isActive,
        })
        .eq('id', trainingId);
  }

  Future<void> deleteTraining(String trainingId) async {
    await supabase.from('trainings').delete().eq('id', trainingId);
  }

  Future<bool> hasJoinedTraining(String trainingId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return false;
    }

    final response = await supabase
        .from('training_students')
        .select('id')
        .eq('training_id', trainingId)
        .eq('student_id', user.id)
        .maybeSingle();

    return response != null;
  }

  Future<void> joinTraining(String trainingId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Devam etmek için giriş yapmalısın.');
    }

    await supabase.from('training_students').insert({
      'training_id': trainingId,
      'student_id': user.id,
    });
  }

  Future<void> leaveTraining(String trainingId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Devam etmek için giriş yapmalısın.');
    }

    await supabase
        .from('training_students')
        .delete()
        .eq('training_id', trainingId)
        .eq('student_id', user.id);
  }

  Future<Map<String, bool>> fetchJoinedMap(List<String> trainingIds) async {
    final user = supabase.auth.currentUser;

    if (user == null || trainingIds.isEmpty) {
      return {};
    }

    final response = await supabase
        .from('training_students')
        .select('training_id')
        .eq('student_id', user.id)
        .inFilter('training_id', trainingIds);

    final result = <String, bool>{};

    for (final item in response as List) {
      final trainingId = item['training_id']?.toString();

      if (trainingId != null) {
        result[trainingId] = true;
      }
    }

    return result;
  }
}