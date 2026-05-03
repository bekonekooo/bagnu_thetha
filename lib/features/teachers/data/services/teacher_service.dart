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

  /// 🔥 YENİ METHOD (HATA BURADAN GELİYORDU)
  Future<TeacherModel?> fetchMyTeacherProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final response = await supabase
        .from('teachers')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return TeacherModel.fromMap(response);
  }
}