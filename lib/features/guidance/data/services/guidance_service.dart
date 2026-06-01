import 'package:flutter_application_1/core/services/supabase_service.dart';

class GuidanceService {
  Future<Map<String, dynamic>> createGuidanceRequest({
    required String fullName,
    required String guidanceType,
    required String birthDate,
    String? birthTime,
    String? birthPlace,
    String? extraInfo,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Devam etmek için giriş yapmalısın.');
    }

    final response = await supabase.functions.invoke(
      'dynamic-action',
      body: {
        'full_name': fullName,
        'guidance_type': guidanceType,
        'birth_date': birthDate,
        'birth_time': birthTime,
        'birth_place': birthPlace,
        'extra_info': extraInfo,
      },
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception('Rehberlik oluşturulamadı. Geçersiz cevap alındı.');
    }

    final result = Map<String, dynamic>.from(data);

    if (result['error'] != null) {
      throw Exception(result['error'].toString());
    }

    final aiResult = result['result']?.toString();

    if (aiResult == null || aiResult.trim().isEmpty) {
      throw Exception('AI sonucu boş döndü.');
    }

    return result;
  }
}