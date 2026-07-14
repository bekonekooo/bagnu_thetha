import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_application_1/core/services/supabase_service.dart';
import 'package:flutter_application_1/features/workshops/data/models/workshop_comment_model.dart';
import 'package:flutter_application_1/features/workshops/data/models/workshop_day_model.dart';
import 'package:flutter_application_1/features/workshops/data/models/workshop_model.dart';

class WorkshopService {
  static const String mediaBucket = 'workshop-media';
  static const String coverBucket = 'workshop-covers';

  Future<List<WorkshopModel>> fetchActiveWorkshops() async {
    final response = await supabase
        .from('workshops')
        .select('''
          *,
          teachers (
            id,
            name,
            specialty,
            image_url
          )
        ''')
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (response as List).map((item) {
      return WorkshopModel.fromMap(
        Map<String, dynamic>.from(item as Map),
      );
    }).toList();
  }

  Future<List<WorkshopModel>>
      fetchMyTeacherWorkshops() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Devam etmek için giriş yapmalısın.',
      );
    }

    final response = await supabase
        .from('workshops')
        .select('''
          *,
          teachers (
            id,
            name,
            specialty,
            image_url
          ),
          workshop_days (
            id,
            workshop_id,
            day_number,
            title,
            description,
            content_type,
            content_url,
            duration_text,
            created_at
          )
        ''')
        .eq('created_by', user.id)
        .order('created_at', ascending: false);

    return (response as List).map((item) {
      return WorkshopModel.fromMap(
        Map<String, dynamic>.from(item as Map),
      );
    }).toList();
  }

  Future<String> fetchMyTeacherId() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Devam etmek için giriş yapmalısın.',
      );
    }

    final response = await supabase
        .from('teachers')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    final teacherId = response?['id']?.toString();

    if (teacherId == null || teacherId.isEmpty) {
      throw Exception(
        'Bu hesaba bağlı öğretmen profili bulunamadı.',
      );
    }

    return teacherId;
  }

  Future<List<WorkshopDayModel>> fetchWorkshopDays(
    String workshopId,
  ) async {
    final response = await supabase
        .from('workshop_days')
        .select()
        .eq('workshop_id', workshopId)
        .order('day_number', ascending: true);

    return (response as List).map((item) {
      return WorkshopDayModel.fromMap(
        Map<String, dynamic>.from(item),
      );
    }).toList();
  }

  Future<void> createWorkshop({
    required String title,
    required String description,
    required String imageUrl,
    required String category,
    required int durationDays,
    required double price,
    required String currency,
    required int? capacity,
    required List<Map<String, dynamic>> days,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Devam etmek için giriş yapmalısın.',
      );
    }

    if (durationDays < 1 || durationDays > 20) {
      throw Exception(
        'Atölye süresi 1 ile 20 gün arasında olmalıdır.',
      );
    }

    if (days.length != durationDays) {
      throw Exception(
        'Her atölye günü için bir içerik eklemelisin.',
      );
    }

    final teacherId = await fetchMyTeacherId();

    final workshopResponse = await supabase
        .from('workshops')
        .insert({
          'teacher_id': teacherId,
          'created_by': user.id,
          'title': title.trim(),
          'description': description.trim(),
          'image_url': imageUrl.trim().isEmpty
              ? null
              : imageUrl.trim(),
          'category': category.trim().isEmpty
              ? null
              : category.trim(),
          'duration_days': durationDays,
          'price': price,
          'currency': currency,
          'capacity': capacity,
          'is_active': false,
        })
        .select('id')
        .single();

    final workshopId =
        workshopResponse['id']?.toString();

    if (workshopId == null || workshopId.isEmpty) {
      throw Exception('Atölye oluşturulamadı.');
    }

    final dayRows = days.map((day) {
      return {
        'workshop_id': workshopId,
        'day_number': day['day_number'],
        'title': day['title'],
        'description': day['description'],
        'content_type': day['content_type'],
        'content_url': day['content_url'],
        'duration_text': day['duration_text'],
      };
    }).toList();

    try {
      await supabase
          .from('workshop_days')
          .insert(dayRows);
    } catch (error) {
      await supabase
          .from('workshops')
          .delete()
          .eq('id', workshopId);

      rethrow;
    }
  }

  Future<void> toggleWorkshopActive({
    required String workshopId,
    required bool isActive,
  }) async {
    await supabase
        .from('workshops')
        .update({
          'is_active': isActive,
        })
        .eq('id', workshopId);
  }

  Future<void> deleteWorkshop(
    String workshopId,
  ) async {
    await supabase
        .from('workshops')
        .delete()
        .eq('id', workshopId);
  }

  Future<bool> hasJoinedWorkshop(
    String workshopId,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return false;
    }

    final response = await supabase
        .from('workshop_students')
        .select('id')
        .eq('workshop_id', workshopId)
        .eq('student_id', user.id)
        .maybeSingle();

    return response != null;
  }

  Future<void> joinWorkshop(
    String workshopId,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Atölyeye katılmak için giriş yapmalısın.',
      );
    }

    await supabase
        .from('workshop_students')
        .insert({
          'workshop_id': workshopId,
          'student_id': user.id,
        });
  }

  Future<void> leaveWorkshop(
    String workshopId,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Devam etmek için giriş yapmalısın.',
      );
    }

    await supabase
        .from('workshop_students')
        .delete()
        .eq('workshop_id', workshopId)
        .eq('student_id', user.id);
  }

  Future<Map<String, bool>> fetchJoinedMap(
    List<String> workshopIds,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null || workshopIds.isEmpty) {
      return {};
    }

    final response = await supabase
        .from('workshop_students')
        .select('workshop_id')
        .eq('student_id', user.id)
        .inFilter('workshop_id', workshopIds);

    final result = <String, bool>{};

    for (final item in response as List) {
      final workshopId =
          item['workshop_id']?.toString();

      if (workshopId != null) {
        result[workshopId] = true;
      }
    }

    return result;
  }

  Future<int> fetchWorkshopStudentCount(
    String workshopId,
  ) async {
    final response = await supabase
        .from('workshop_students')
        .select('id')
        .eq('workshop_id', workshopId);

    return (response as List).length;
  }

  Future<int> fetchWorkshopLikeCount(
    String workshopId,
  ) async {
    final response = await supabase
        .from('workshop_likes')
        .select('id')
        .eq('workshop_id', workshopId);

    return (response as List).length;
  }

  Future<bool> fetchIsWorkshopLikedByMe(
    String workshopId,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return false;
    }

    final response = await supabase
        .from('workshop_likes')
        .select('id')
        .eq('workshop_id', workshopId)
        .eq('user_id', user.id)
        .maybeSingle();

    return response != null;
  }

  Future<bool> toggleWorkshopLike(
    String workshopId,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Beğenmek için giriş yapmalısın.',
      );
    }

    final isLiked =
        await fetchIsWorkshopLikedByMe(workshopId);

    if (isLiked) {
      await supabase
          .from('workshop_likes')
          .delete()
          .eq('workshop_id', workshopId)
          .eq('user_id', user.id);

      return false;
    }

    await supabase
        .from('workshop_likes')
        .insert({
          'workshop_id': workshopId,
          'user_id': user.id,
        });

    return true;
  }

  Future<int> fetchWorkshopCommentCount(
    String workshopId,
  ) async {
    final response = await supabase
        .from('workshop_comments')
        .select('id')
        .eq('workshop_id', workshopId);

    return (response as List).length;
  }

  Future<List<WorkshopCommentModel>>
      fetchWorkshopComments(
    String workshopId,
  ) async {
    final response = await supabase
        .from('workshop_comments')
        .select('''
          id,
          workshop_id,
          user_id,
          comment_text,
          created_at,
          profiles (
            full_name,
            image_url
          )
        ''')
        .eq('workshop_id', workshopId)
        .order('created_at', ascending: false);

    return (response as List).map((item) {
      return WorkshopCommentModel.fromMap(
        Map<String, dynamic>.from(item),
      );
    }).toList();
  }

  Future<void> addWorkshopComment({
    required String workshopId,
    required String commentText,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Yorum yazmak için giriş yapmalısın.',
      );
    }

    final hasJoined =
        await hasJoinedWorkshop(workshopId);

    if (!hasJoined) {
      throw Exception(
        'Yorum yazabilmek için bu atölyeye kayıt olmalısın.',
      );
    }

    final cleanComment = commentText.trim();

    if (cleanComment.isEmpty) {
      throw Exception('Yorum boş olamaz.');
    }

    if (cleanComment.length > 1000) {
      throw Exception(
        'Yorum en fazla 1000 karakter olabilir.',
      );
    }

    await supabase
        .from('workshop_comments')
        .insert({
          'workshop_id': workshopId,
          'user_id': user.id,
          'comment_text': cleanComment,
        });
  }

  Future<void> deleteWorkshopComment(
    String commentId,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Devam etmek için giriş yapmalısın.',
      );
    }

    await supabase
        .from('workshop_comments')
        .delete()
        .eq('id', commentId)
        .eq('user_id', user.id);
  }

  Future<String> uploadWorkshopMedia({
    required PlatformFile file,
    required String contentType,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Dosya yüklemek için giriş yapmalısın.',
      );
    }

    final bytes = file.bytes;

    if (bytes == null) {
      throw Exception(
        'Dosya okunamadı. Dosyayı tekrar seç.',
      );
    }

    final extension =
        _cleanExtension(file.extension);

    final fileName = _safeFileName(file.name);

    final timestamp =
        DateTime.now().millisecondsSinceEpoch;

    final path =
        '${user.id}/$timestamp-$fileName';

    await supabase.storage
        .from(mediaBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _mediaContentType(
              contentType,
              extension,
            ),
            upsert: true,
          ),
        );

    return supabase.storage
        .from(mediaBucket)
        .getPublicUrl(path);
  }

  Future<String> uploadWorkshopCover({
    required PlatformFile file,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Kapak yüklemek için giriş yapmalısın.',
      );
    }

    final bytes = file.bytes;

    if (bytes == null) {
      throw Exception(
        'Kapak görseli okunamadı.',
      );
    }

    final extension =
        _cleanExtension(file.extension);

    final fileName = _safeFileName(file.name);

    final timestamp =
        DateTime.now().millisecondsSinceEpoch;

    final path =
        '${user.id}/$timestamp-$fileName';

    await supabase.storage
        .from(coverBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType:
                _imageContentType(extension),
            upsert: true,
          ),
        );

    return supabase.storage
        .from(coverBucket)
        .getPublicUrl(path);
  }

  String _cleanExtension(
    String? extension,
  ) {
    final value =
        extension?.toLowerCase().trim();

    if (value == null || value.isEmpty) {
      return 'file';
    }

    return value.replaceAll('.', '');
  }

  String _safeFileName(
    String fileName,
  ) {
    final cleaned = fileName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(
          RegExp(r'[^a-z0-9\.\-_]'),
          '',
        );

    if (cleaned.isEmpty) {
      return 'workshop-file';
    }

    return cleaned;
  }

  String _mediaContentType(
    String contentType,
    String extension,
  ) {
    if (contentType == 'audio') {
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

    if (contentType == 'video') {
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

  String _imageContentType(
    String extension,
  ) {
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