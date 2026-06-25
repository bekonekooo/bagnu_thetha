import 'package:flutter_application_1/core/services/supabase_service.dart';
import 'package:flutter_application_1/features/social/data/models/social_target.dart';

class RatingService {
  Future<void> setRating(
    SocialTarget type,
    String targetId,
    int score,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Devam etmek için giriş yapmalısın.');
    }

    if (score < 1 || score > 5) {
      throw Exception('Puan 1 ile 5 arasında olmalı.');
    }

    await supabase.from('ratings').upsert(
      {
        'user_id': user.id,
        'target_type': type.dbValue,
        'target_id': targetId,
        'score': score,
      },
      onConflict: 'user_id,target_type,target_id',
    );
  }

  Future<int?> fetchMyRating(SocialTarget type, String targetId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    final response = await supabase
        .from('ratings')
        .select('score')
        .eq('user_id', user.id)
        .eq('target_type', type.dbValue)
        .eq('target_id', targetId)
        .maybeSingle();

    final score = response?['score'];

    if (score == null) {
      return null;
    }

    return score is int ? score : int.tryParse(score.toString());
  }
}
