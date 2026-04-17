import 'package:flutter_application_1/core/services/supabase_service.dart';
import '../models/availability_model.dart';

class AvailabilityService {
  Future<List<AvailabilityModel>> fetchTeacherAvailability({
    required String teacherId,
    required int weekday,
  }) async {
    final response = await supabase
        .from('teacher_availability')
        .select()
        .eq('teacher_id', teacherId)
        .eq('weekday', weekday)
        .eq('is_active', true)
        .order('time_slot', ascending: true);

    return (response as List)
        .map((item) => AvailabilityModel.fromMap(item))
        .toList();
  }
}