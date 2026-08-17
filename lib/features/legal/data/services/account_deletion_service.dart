import '../../../../core/services/supabase_service.dart';

class AccountDeletionService {
  Future<void> deleteAccount() async {
    if (supabase.auth.currentUser == null) {
      throw Exception('Hesap silme işlemi için giriş yapmalısınız.');
    }

    final response = await supabase.functions.invoke(
      'delete-account',
      body: const {'confirm': true},
    );

    final data = response.data;
    if (data is Map && data['success'] != true) {
      throw Exception(
        data['error']?.toString() ?? 'Hesap silme işlemi tamamlanamadı.',
      );
    }
  }
}
