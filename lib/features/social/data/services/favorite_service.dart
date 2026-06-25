import 'package:flutter_application_1/core/services/supabase_service.dart';
import 'package:flutter_application_1/features/social/data/models/favorite_model.dart';
import 'package:flutter_application_1/features/social/data/models/social_target.dart';

class FavoriteService {
  Future<void> addFavorite(SocialTarget type, String targetId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Devam etmek için giriş yapmalısın.');
    }

    await supabase.from('favorites').insert({
      'user_id': user.id,
      'target_type': type.dbValue,
      'target_id': targetId,
    });
  }

  Future<void> removeFavorite(SocialTarget type, String targetId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Devam etmek için giriş yapmalısın.');
    }

    await supabase
        .from('favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('target_type', type.dbValue)
        .eq('target_id', targetId);
  }

  Future<bool> isFavorite(SocialTarget type, String targetId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return false;
    }

    final response = await supabase
        .from('favorites')
        .select('id')
        .eq('user_id', user.id)
        .eq('target_type', type.dbValue)
        .eq('target_id', targetId)
        .maybeSingle();

    return response != null;
  }

  Future<Map<String, bool>> fetchFavoriteMap(
    SocialTarget type,
    List<String> ids,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null || ids.isEmpty) {
      return {};
    }

    final response = await supabase
        .from('favorites')
        .select('target_id')
        .eq('user_id', user.id)
        .eq('target_type', type.dbValue)
        .inFilter('target_id', ids);

    final result = <String, bool>{};

    for (final item in response as List) {
      final targetId = item['target_id']?.toString();

      if (targetId != null) {
        result[targetId] = true;
      }
    }

    return result;
  }

  Future<List<FavoriteModel>> fetchMyFavorites({SocialTarget? type}) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Devam etmek için giriş yapmalısın.');
    }

    var query =
        supabase.from('favorites').select('*').eq('user_id', user.id);

    if (type != null) {
      query = query.eq('target_type', type.dbValue);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map(
          (item) => FavoriteModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}
