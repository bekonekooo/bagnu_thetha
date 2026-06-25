import 'package:flutter_application_1/core/services/supabase_service.dart';
import 'package:flutter_application_1/features/social/data/models/social_target.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  Future<void> submitReport({
    required SocialTarget type,
    required String targetId,
    required String reason,
    String? details,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Devam etmek için giriş yapmalısın.');
    }

    final trimmedDetails = details?.trim();

    try {
      await supabase.from('reports').insert({
        'reporter_id': user.id,
        'target_type': type.dbValue,
        'target_id': targetId,
        'reason': reason,
        'details': trimmedDetails != null && trimmedDetails.isNotEmpty
            ? trimmedDetails
            : null,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Bu içeriği zaten bildirdin.');
      }

      rethrow;
    }
  }
}
