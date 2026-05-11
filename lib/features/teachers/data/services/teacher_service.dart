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

  Future<void> updateMyTeacherProfile({
    required String teacherId,
    required String name,
    required String specialty,
    required String category,
    required String experience,
    required String bio,
    required String imageUrl,
    required bool isActive,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    await supabase
        .from('teachers')
        .update({
          'name': name,
          'specialty': specialty,
          'category': category,
          'experience': experience,
          'bio': bio,
          'image_url': imageUrl,
          'is_active': isActive,
        })
        .eq('id', teacherId)
        .eq('user_id', user.id);
  }
}