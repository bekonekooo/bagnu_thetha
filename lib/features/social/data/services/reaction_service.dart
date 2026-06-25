import 'package:flutter_application_1/core/services/supabase_service.dart';
import 'package:flutter_application_1/features/social/data/models/social_target.dart';

class ReactionService {
  Future<void> like(SocialTarget type, String targetId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Devam etmek için giriş yapmalısın.');
    }

    await supabase.from('likes').insert({
      'user_id': user.id,
      'target_type': type.dbValue,
      'target_id': targetId,
    });
  }

  Future<void> unlike(SocialTarget type, String targetId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Devam etmek için giriş yapmalısın.');
    }

    await supabase
        .from('likes')
        .delete()
        .eq('user_id', user.id)
        .eq('target_type', type.dbValue)
        .eq('target_id', targetId);
  }

  Future<bool> isLiked(SocialTarget type, String targetId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return false;
    }

    final response = await supabase
        .from('likes')
        .select('id')
        .eq('user_id', user.id)
        .eq('target_type', type.dbValue)
        .eq('target_id', targetId)
        .maybeSingle();

    return response != null;
  }
}
