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

  Future<List<AvailabilityModel>> fetchAllTeacherAvailability({
    required String teacherId,
  }) async {
    final response = await supabase
        .from('teacher_availability')
        .select()
        .eq('teacher_id', teacherId)
        .eq('is_active', true)
        .order('weekday', ascending: true)
        .order('time_slot', ascending: true);

    return (response as List)
        .map((item) => AvailabilityModel.fromMap(item))
        .toList();
  }

  Future<void> addAvailability({
    required String teacherId,
    required int weekday,
    required String timeSlot,
  }) async {
    final existing = await supabase
        .from('teacher_availability')
        .select()
        .eq('teacher_id', teacherId)
        .eq('weekday', weekday)
        .eq('time_slot', timeSlot)
        .eq('is_active', true);

    if ((existing as List).isNotEmpty) {
      throw Exception('Bu saat zaten ekli');
    }

    await supabase.from('teacher_availability').insert({
      'teacher_id': teacherId,
      'weekday': weekday,
      'time_slot': timeSlot,
      'is_active': true,
    });
  }

  Future<void> addMultipleAvailability({
    required String teacherId,
    required int weekday,
    required List<String> timeSlots,
  }) async {
    final existingResponse = await supabase
        .from('teacher_availability')
        .select('time_slot')
        .eq('teacher_id', teacherId)
        .eq('weekday', weekday)
        .eq('is_active', true);

    final existingTimes = (existingResponse as List)
        .map((item) => item['time_slot'].toString())
        .toSet();

    final newSlots = timeSlots
        .where((time) => !existingTimes.contains(time))
        .map((time) {
      return {
        'teacher_id': teacherId,
        'weekday': weekday,
        'time_slot': time,
        'is_active': true,
      };
    }).toList();

    if (newSlots.isEmpty) {
      throw Exception('Seçilen saatlerin hepsi zaten ekli');
    }

    await supabase.from('teacher_availability').insert(newSlots);
  }

  Future<void> deleteAvailability(String availabilityId) async {
    await supabase
        .from('teacher_availability')
        .update({'is_active': false})
        .eq('id', availabilityId);
  }

  Future<void> clearDayAvailability({
    required String teacherId,
    required int weekday,
  }) async {
    await supabase
        .from('teacher_availability')
        .update({'is_active': false})
        .eq('teacher_id', teacherId)
        .eq('weekday', weekday)
        .eq('is_active', true);
  }
}