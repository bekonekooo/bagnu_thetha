import 'package:flutter_application_1/core/services/supabase_service.dart';
import 'package:flutter_application_1/features/social/data/models/comment_model.dart';
import 'package:flutter_application_1/features/social/data/models/social_target.dart';

class CommentService {
  Future<List<CommentModel>> fetchComments(
    SocialTarget type,
    String targetId,
  ) async {
    final response = await supabase
        .from('comments')
        .select('*, profiles(full_name, image_url)')
        .eq('target_type', type.dbValue)
        .eq('target_id', targetId)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (item) => CommentModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<CommentModel> addComment(
    SocialTarget type,
    String targetId,
    String body,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Devam etmek için giriş yapmalısın.');
    }

    final trimmed = body.trim();

    if (trimmed.isEmpty) {
      throw Exception('Yorum boş olamaz.');
    }

    final response = await supabase
        .from('comments')
        .insert({
          'user_id': user.id,
          'target_type': type.dbValue,
          'target_id': targetId,
          'body': trimmed,
        })
        .select('*, profiles(full_name, image_url)')
        .single();

    return CommentModel.fromMap(Map<String, dynamic>.from(response));
  }

  Future<void> deleteComment(String commentId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Devam etmek için giriş yapmalısın.');
    }

    await supabase.from('comments').delete().eq('id', commentId);
  }
}
