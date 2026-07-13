import 'package:file_picker/file_picker.dart';
import 'package:flutter_application_1/core/services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/meditation_comment_model.dart';
import '../models/meditation_model.dart';

class MeditationService {
  static const String mediaBucket = 'meditation-media';
  static const String thumbnailsBucket = 'meditation-thumbnails';

  static const String recentlyPlayedMeditationIdsKey =
      'recently_played_meditation_ids';

  Future<List<MeditationModel>> fetchActiveMeditations() async {
    final response = await supabase
        .from('meditations')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => MeditationModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<MeditationModel>> fetchMyFavoriteMeditations() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Favorileri görmek için giriş yapmalısın.');
    }

    final likesResponse = await supabase
        .from('meditation_likes')
        .select('meditation_id, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final likedRows = likesResponse as List;

    if (likedRows.isEmpty) {
      return [];
    }

    final meditationIds = likedRows
        .map((item) => item['meditation_id']?.toString() ?? '')
        .where((id) => id.trim().isNotEmpty)
        .toList();

    if (meditationIds.isEmpty) {
      return [];
    }

    final meditationsResponse = await supabase
        .from('meditations')
        .select()
        .inFilter('id', meditationIds)
        .eq('is_active', true);

    final meditations = (meditationsResponse as List)
        .map((item) => MeditationModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    meditations.sort((a, b) {
      final aIndex = meditationIds.indexOf(a.id);
      final bIndex = meditationIds.indexOf(b.id);

      return aIndex.compareTo(bIndex);
    });

    return meditations;
  }

  Future<void> saveRecentlyPlayedMeditation(String meditationId) async {
    final cleanedId = meditationId.trim();

    if (cleanedId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    final currentIds =
        prefs.getStringList(recentlyPlayedMeditationIdsKey) ?? [];

    final updatedIds = [
      cleanedId,
      ...currentIds.where((id) => id != cleanedId),
    ].take(20).toList();

    await prefs.setStringList(
      recentlyPlayedMeditationIdsKey,
      updatedIds,
    );
  }

  Future<List<MeditationModel>> fetchRecentlyPlayedMeditations() async {
    final prefs = await SharedPreferences.getInstance();

    final meditationIds =
        prefs.getStringList(recentlyPlayedMeditationIdsKey) ?? [];

    if (meditationIds.isEmpty) {
      return [];
    }

    final response = await supabase
        .from('meditations')
        .select()
        .inFilter('id', meditationIds)
        .eq('is_active', true);

    final meditations = (response as List)
        .map((item) => MeditationModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    meditations.sort((a, b) {
      final aIndex = meditationIds.indexOf(a.id);
      final bIndex = meditationIds.indexOf(b.id);

      return aIndex.compareTo(bIndex);
    });

    return meditations;
  }

  Future<List<MeditationModel>> fetchMyTeacherMeditations() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Devam etmek için giriş yapmalısın.');
    }

    final response = await supabase
        .from('meditations')
        .select()
        .eq('created_by', user.id)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => MeditationModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<MeditationModel>> fetchMeditationsByTeacherUserId(
  String teacherUserId,
) async {
  final cleanUserId = teacherUserId.trim();

  if (cleanUserId.isEmpty) {
    return [];
  }

  final response = await supabase
      .from('meditations')
      .select()
      .eq('created_by', cleanUserId)
      .eq('is_active', true)
      .order('sort_order', ascending: true)
      .order('created_at', ascending: false);

  return (response as List)
      .map(
        (item) => MeditationModel.fromMap(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList();
}

  Future<int> fetchMeditationLikeCount(String meditationId) async {
    final response = await supabase
        .from('meditation_likes')
        .select('id')
        .eq('meditation_id', meditationId);

    return (response as List).length;
  }

  Future<int> fetchMeditationCommentCount(String meditationId) async {
    final response = await supabase
        .from('meditation_comments')
        .select('id')
        .eq('meditation_id', meditationId);

    return (response as List).length;
  }

  Future<bool> fetchIsMeditationLikedByMe(String meditationId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return false;
    }

    final response = await supabase
        .from('meditation_likes')
        .select('id')
        .eq('meditation_id', meditationId)
        .eq('user_id', user.id)
        .maybeSingle();

    return response != null;
  }

  Future<bool> toggleMeditationLike(String meditationId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Beğenmek için giriş yapmalısın.');
    }

    final isLiked = await fetchIsMeditationLikedByMe(meditationId);

    if (isLiked) {
      await supabase
          .from('meditation_likes')
          .delete()
          .eq('meditation_id', meditationId)
          .eq('user_id', user.id);

      return false;
    }

    await supabase.from('meditation_likes').insert({
      'meditation_id': meditationId,
      'user_id': user.id,
    });

    return true;
  }

  Future<List<MeditationCommentModel>> fetchMeditationComments(
    String meditationId,
  ) async {
    final response = await supabase
        .from('meditation_comments')
        .select('''
          id,
          meditation_id,
          user_id,
          comment_text,
          created_at,
          profiles (
            full_name,
            image_url
          )
        ''')
        .eq('meditation_id', meditationId)
        .order('created_at', ascending: false);

    return (response as List).map((item) {
      return MeditationCommentModel.fromMap(
        Map<String, dynamic>.from(item),
      );
    }).toList();
  }

  Future<void> addMeditationComment({
    required String meditationId,
    required String commentText,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Yorum yazmak için giriş yapmalısın.');
    }

    final cleanedComment = commentText.trim();

    if (cleanedComment.isEmpty) {
      throw Exception('Yorum boş olamaz.');
    }

    await supabase.from('meditation_comments').insert({
      'meditation_id': meditationId,
      'user_id': user.id,
      'comment_text': cleanedComment,
    });
  }

  Future<void> deleteMeditationComment(String commentId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Devam etmek için giriş yapmalısın.');
    }

    await supabase
        .from('meditation_comments')
        .delete()
        .eq('id', commentId)
        .eq('user_id', user.id);
  }

  Future<String> uploadMeditationMedia({
    required PlatformFile file,
    required String type,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Devam etmek için giriş yapmalısın.');
    }

    final bytes = file.bytes;

    if (bytes == null) {
      throw Exception('Dosya okunamadı. Lütfen dosyayı tekrar seç.');
    }

    final extension = _cleanExtension(file.extension);
    final fileName = _safeFileName(file.name);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final path = '${user.id}/$timestamp-$fileName';

    await supabase.storage.from(mediaBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _mediaContentType(type, extension),
            upsert: true,
          ),
        );

    return supabase.storage.from(mediaBucket).getPublicUrl(path);
  }

  Future<String> uploadThumbnail({
    required PlatformFile file,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Devam etmek için giriş yapmalısın.');
    }

    final bytes = file.bytes;

    if (bytes == null) {
      throw Exception('Kapak görseli okunamadı. Lütfen görseli tekrar seç.');
    }

    final extension = _cleanExtension(file.extension);
    final fileName = _safeFileName(file.name);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final path = '${user.id}/$timestamp-$fileName';

    await supabase.storage.from(thumbnailsBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _imageContentType(extension),
            upsert: true,
          ),
        );

    return supabase.storage.from(thumbnailsBucket).getPublicUrl(path);
  }

  Future<void> createMeditation({
    required String title,
    required String description,
    required String type,
    required String category,
    required String durationText,
    required String mediaUrl,
    required String thumbnailUrl,
    required bool isActive,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Devam etmek için giriş yapmalısın.');
    }

    await supabase.from('meditations').insert({
      'created_by': user.id,
      'title': title,
      'description': description,
      'type': type,
      'category': category,
      'duration_text': durationText,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl.trim().isEmpty ? null : thumbnailUrl.trim(),
      'is_active': isActive,
    });
  }

  Future<void> toggleMeditationActive({
    required String meditationId,
    required bool isActive,
  }) async {
    await supabase
        .from('meditations')
        .update({
          'is_active': isActive,
        })
        .eq('id', meditationId);
  }

  Future<void> deleteMeditation(String meditationId) async {
    await supabase.from('meditations').delete().eq('id', meditationId);
  }

  String _cleanExtension(String? extension) {
    final value = extension?.toLowerCase().trim();

    if (value == null || value.isEmpty) {
      return 'file';
    }

    return value.replaceAll('.', '');
  }

  String _safeFileName(String fileName) {
    final cleaned = fileName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\.\-_]'), '');

    if (cleaned.isEmpty) {
      return 'meditation-file';
    }

    return cleaned;
  }

  String _mediaContentType(String type, String extension) {
    if (type == 'audio') {
      switch (extension) {
        case 'mp3':
          return 'audio/mpeg';
        case 'wav':
          return 'audio/wav';
        case 'm4a':
          return 'audio/mp4';
        case 'aac':
          return 'audio/aac';
        case 'ogg':
          return 'audio/ogg';
        default:
          return 'audio/mpeg';
      }
    }

    if (type == 'video') {
      switch (extension) {
        case 'mp4':
          return 'video/mp4';
        case 'mov':
          return 'video/quicktime';
        case 'webm':
          return 'video/webm';
        default:
          return 'video/mp4';
      }
    }

    return 'application/octet-stream';
  }

  String _imageContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}