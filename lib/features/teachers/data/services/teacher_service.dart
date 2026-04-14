import 'package:flutter_application_1/core/services/supabase_service.dart';
import '../models/teacher_model.dart';

class TeacherService {
  Future<List<TeacherModel>> fetchTeachers() async {
    final response = await supabase
        .from('teachers')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => TeacherModel.fromMap(item))
        .toList();
  }
}