import 'package:flutter_application_1/core/services/supabase_service.dart';

class ProfileService {
  Future<Map<String, dynamic>> fetchMyProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return response;
  }

  Future<void> updateMyProfile({
    required String fullName,
    required String phone,
    required String bio,
    required String imageUrl,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    await supabase
        .from('profiles')
        .update({
          'full_name': fullName,
          'phone': phone,
          'bio': bio,
          'image_url': imageUrl,
        })
        .eq('id', user.id);
  }
}