import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_application_1/core/services/supabase_service.dart';

import 'package:flutter_application_1/features/workshops/data/models/workshop_comment_model.dart';
import 'package:flutter_application_1/features/workshops/data/models/workshop_day_model.dart';
import 'package:flutter_application_1/features/workshops/data/models/workshop_model.dart';

class WorkshopService {
  static const String mediaBucket = 'workshop-media';
  static const String coverBucket = 'workshop-covers';

  // =======================================================
  // AKTİF ATÖLYELER
  // =======================================================

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

    return (response as List)
        .map(
          (item) => WorkshopModel.fromMap(
            Map<String, dynamic>.from(
              item as Map,
            ),
          ),
        )
        .toList();
  }

  // =======================================================
  // ÖĞRETMENİN ATÖLYELERİ
  // =======================================================

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

    return (response as List)
        .map(
          (item) => WorkshopModel.fromMap(
            Map<String, dynamic>.from(
              item as Map,
            ),
          ),
        )
        .toList();
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

    final teacherId =
        response?['id']?.toString() ?? '';

    if (teacherId.trim().isEmpty) {
      throw Exception(
        'Bu hesaba bağlı öğretmen profili bulunamadı.',
      );
    }

    return teacherId;
  }

  // =======================================================
  // ATÖLYE GÜNLERİ
  // =======================================================

  Future<List<WorkshopDayModel>> fetchWorkshopDays(
    String workshopId,
  ) async {
    final cleanWorkshopId = workshopId.trim();

    if (cleanWorkshopId.isEmpty) {
      return [];
    }

    final response = await supabase
        .from('workshop_days')
        .select()
        .eq(
          'workshop_id',
          cleanWorkshopId,
        )
        .order(
          'day_number',
          ascending: true,
        );

    return (response as List)
        .map(
          (item) => WorkshopDayModel.fromMap(
            Map<String, dynamic>.from(
              item as Map,
            ),
          ),
        )
        .toList();
  }

  // =======================================================
  // ATÖLYE OLUŞTURMA
  // =======================================================

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

    final cleanTitle = title.trim();
    final cleanDescription = description.trim();
    final cleanCategory = category.trim();
    final cleanImageUrl = imageUrl.trim();
    final cleanCurrency = currency.trim().toLowerCase();

    if (cleanTitle.isEmpty) {
      throw Exception(
        'Atölye başlığı boş olamaz.',
      );
    }

    if (durationDays < 1 ||
        durationDays > 20) {
      throw Exception(
        'Atölye süresi 1 ile 20 gün arasında olmalıdır.',
      );
    }

    if (days.length != durationDays) {
      throw Exception(
        'Her atölye günü için bir içerik eklemelisin.',
      );
    }

    if (price < 0) {
      throw Exception(
        'Atölye fiyatı sıfırdan küçük olamaz.',
      );
    }

    if (capacity != null &&
        capacity <= 0) {
      throw Exception(
        'Kapasite en az 1 olmalıdır.',
      );
    }

    final teacherId =
        await fetchMyTeacherId();

    final workshopResponse = await supabase
        .from('workshops')
        .insert({
          'teacher_id': teacherId,
          'created_by': user.id,
          'title': cleanTitle,
          'description': cleanDescription,
          'image_url': cleanImageUrl.isEmpty
              ? null
              : cleanImageUrl,
          'category': cleanCategory.isEmpty
              ? null
              : cleanCategory,
          'duration_days': durationDays,
          'price': price,
          'currency': cleanCurrency.isEmpty
              ? 'try'
              : cleanCurrency,
          'capacity': capacity,
          'is_active': false,
        })
        .select('id')
        .single();

    final workshopId =
        workshopResponse['id']?.toString() ?? '';

    if (workshopId.trim().isEmpty) {
      throw Exception(
        'Atölye oluşturulamadı.',
      );
    }

    final dayRows =
        days.map((day) {
      final title =
          day['title']?.toString().trim() ?? '';

      final contentType =
          day['content_type']
                  ?.toString()
                  .trim() ??
              '';

      final contentUrl =
          day['content_url']
                  ?.toString()
                  .trim() ??
              '';

      if (title.isEmpty) {
        throw Exception(
          'Atölye günü başlığı boş olamaz.',
        );
      }

      if (![
        'audio',
        'video',
        'link',
      ].contains(contentType)) {
        throw Exception(
          'Geçersiz içerik türü.',
        );
      }

      if (contentUrl.isEmpty) {
        throw Exception(
          'Atölye günü içerik bağlantısı boş olamaz.',
        );
      }

      return {
        'workshop_id': workshopId,
        'day_number': day['day_number'],
        'title': title,
        'description':
            day['description']
                    ?.toString()
                    .trim() ??
                '',
        'content_type': contentType,
        'content_url': contentUrl,
        'duration_text':
            day['duration_text']
                    ?.toString()
                    .trim() ??
                '',
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
          .eq(
            'id',
            workshopId,
          );

      rethrow;
    }
  }

  Future<void> toggleWorkshopActive({
    required String workshopId,
    required bool isActive,
  }) async {
    final cleanWorkshopId =
        workshopId.trim();

    if (cleanWorkshopId.isEmpty) {
      throw Exception(
        'Atölye kimliği bulunamadı.',
      );
    }

    await supabase
        .from('workshops')
        .update({
          'is_active': isActive,
          'updated_at':
              DateTime.now().toIso8601String(),
        })
        .eq(
          'id',
          cleanWorkshopId,
        );
  }

  Future<void> deleteWorkshop(
    String workshopId,
  ) async {
    final cleanWorkshopId =
        workshopId.trim();

    if (cleanWorkshopId.isEmpty) {
      return;
    }

    await supabase
        .from('workshops')
        .delete()
        .eq(
          'id',
          cleanWorkshopId,
        );
  }

  // =======================================================
  // KATILIM
  // =======================================================

  Future<bool> hasJoinedWorkshop(
    String workshopId,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return false;
    }

    final cleanWorkshopId =
        workshopId.trim();

    if (cleanWorkshopId.isEmpty) {
      return false;
    }

    final response = await supabase
        .from('workshop_students')
        .select('id')
        .eq(
          'workshop_id',
          cleanWorkshopId,
        )
        .eq(
          'student_id',
          user.id,
        )
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

    final cleanWorkshopId =
        workshopId.trim();

    if (cleanWorkshopId.isEmpty) {
      throw Exception(
        'Atölye kimliği bulunamadı.',
      );
    }

    final alreadyJoined =
        await hasJoinedWorkshop(
      cleanWorkshopId,
    );

    if (alreadyJoined) {
      return;
    }

    await supabase
        .from('workshop_students')
        .insert({
          'workshop_id':
              cleanWorkshopId,
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

    final cleanWorkshopId =
        workshopId.trim();

    if (cleanWorkshopId.isEmpty) {
      return;
    }

    await supabase
        .from('workshop_students')
        .delete()
        .eq(
          'workshop_id',
          cleanWorkshopId,
        )
        .eq(
          'student_id',
          user.id,
        );
  }

  Future<Map<String, bool>> fetchJoinedMap(
    List<String> workshopIds,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null ||
        workshopIds.isEmpty) {
      return {};
    }

    final cleanIds = workshopIds
        .map(
          (id) => id.trim(),
        )
        .where(
          (id) => id.isNotEmpty,
        )
        .toSet()
        .toList();

    if (cleanIds.isEmpty) {
      return {};
    }

    final response = await supabase
        .from('workshop_students')
        .select('workshop_id')
        .eq(
          'student_id',
          user.id,
        )
        .inFilter(
          'workshop_id',
          cleanIds,
        );

    final result = <String, bool>{};

    for (final item in response as List) {
      final workshopId =
          item['workshop_id']
                  ?.toString() ??
              '';

      if (workshopId.isNotEmpty) {
        result[workshopId] = true;
      }
    }

    return result;
  }

  Future<int> fetchWorkshopStudentCount(
    String workshopId,
  ) async {
    final cleanWorkshopId =
        workshopId.trim();

    if (cleanWorkshopId.isEmpty) {
      return 0;
    }

    final response = await supabase
        .from('workshop_students')
        .select('id')
        .eq(
          'workshop_id',
          cleanWorkshopId,
        );

    return (response as List).length;
  }

  // =======================================================
  // FAVORİ ATÖLYELER
  // =======================================================

  Future<List<WorkshopModel>>
      fetchMyFavoriteWorkshops() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Favorileri görmek için giriş yapmalısın.',
      );
    }

    final likesResponse = await supabase
        .from('workshop_likes')
        .select(
          'workshop_id, created_at',
        )
        .eq(
          'user_id',
          user.id,
        )
        .order(
          'created_at',
          ascending: false,
        );

    final likedRows =
        likesResponse as List;

    if (likedRows.isEmpty) {
      return [];
    }

    final workshopIds = likedRows
        .map(
          (item) =>
              item['workshop_id']
                  ?.toString() ??
              '',
        )
        .where(
          (id) => id.trim().isNotEmpty,
        )
        .toList();

    if (workshopIds.isEmpty) {
      return [];
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
          )
        ''')
        .inFilter(
          'id',
          workshopIds,
        )
        .eq(
          'is_active',
          true,
        );

    final workshops = (response as List)
        .map(
          (item) => WorkshopModel.fromMap(
            Map<String, dynamic>.from(
              item as Map,
            ),
          ),
        )
        .toList();

    workshops.sort((a, b) {
      final aIndex =
          workshopIds.indexOf(a.id);

      final bIndex =
          workshopIds.indexOf(b.id);

      return aIndex.compareTo(bIndex);
    });

    return workshops;
  }

  // =======================================================
  // SON OYNATILAN ATÖLYE İÇERİĞİ
  // =======================================================

  Future<void> saveRecentlyPlayedWorkshopDay({
    required String workshopId,
    required String workshopDayId,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    final cleanWorkshopId =
        workshopId.trim();

    final cleanWorkshopDayId =
        workshopDayId.trim();

    if (cleanWorkshopId.isEmpty ||
        cleanWorkshopDayId.isEmpty) {
      return;
    }

    await supabase.rpc(
      'save_workshop_day_play_history',
      params: {
        'target_workshop_id':
            cleanWorkshopId,
        'target_workshop_day_id':
            cleanWorkshopDayId,
      },
    );
  }

  // =======================================================
  // BEĞENİ
  // =======================================================

  Future<int> fetchWorkshopLikeCount(
    String workshopId,
  ) async {
    final cleanWorkshopId =
        workshopId.trim();

    if (cleanWorkshopId.isEmpty) {
      return 0;
    }

    final response = await supabase
        .from('workshop_likes')
        .select('id')
        .eq(
          'workshop_id',
          cleanWorkshopId,
        );

    return (response as List).length;
  }

  Future<bool> fetchIsWorkshopLikedByMe(
    String workshopId,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return false;
    }

    final cleanWorkshopId =
        workshopId.trim();

    if (cleanWorkshopId.isEmpty) {
      return false;
    }

    final response = await supabase
        .from('workshop_likes')
        .select('id')
        .eq(
          'workshop_id',
          cleanWorkshopId,
        )
        .eq(
          'user_id',
          user.id,
        )
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

    final cleanWorkshopId =
        workshopId.trim();

    if (cleanWorkshopId.isEmpty) {
      throw Exception(
        'Atölye kimliği bulunamadı.',
      );
    }

    final isLiked =
        await fetchIsWorkshopLikedByMe(
      cleanWorkshopId,
    );

    if (isLiked) {
      await supabase
          .from('workshop_likes')
          .delete()
          .eq(
            'workshop_id',
            cleanWorkshopId,
          )
          .eq(
            'user_id',
            user.id,
          );

      return false;
    }

    await supabase
        .from('workshop_likes')
        .insert({
          'workshop_id':
              cleanWorkshopId,
          'user_id': user.id,
        });

    return true;
  }

  // =======================================================
  // YORUMLAR
  // =======================================================

  Future<int> fetchWorkshopCommentCount(
    String workshopId,
  ) async {
    final cleanWorkshopId =
        workshopId.trim();

    if (cleanWorkshopId.isEmpty) {
      return 0;
    }

    final response = await supabase
        .from('workshop_comments')
        .select('id')
        .eq(
          'workshop_id',
          cleanWorkshopId,
        );

    return (response as List).length;
  }

  Future<List<WorkshopCommentModel>>
      fetchWorkshopComments(
    String workshopId,
  ) async {
    final cleanWorkshopId =
        workshopId.trim();

    if (cleanWorkshopId.isEmpty) {
      return [];
    }

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
        .eq(
          'workshop_id',
          cleanWorkshopId,
        )
        .order(
          'created_at',
          ascending: false,
        );

    return (response as List)
        .map(
          (item) => WorkshopCommentModel.fromMap(
            Map<String, dynamic>.from(
              item as Map,
            ),
          ),
        )
        .toList();
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

    final cleanWorkshopId =
        workshopId.trim();

    final cleanComment =
        commentText.trim();

    if (cleanWorkshopId.isEmpty) {
      throw Exception(
        'Atölye kimliği bulunamadı.',
      );
    }

    final hasJoined =
        await hasJoinedWorkshop(
      cleanWorkshopId,
    );

    if (!hasJoined) {
      throw Exception(
        'Yorum yazabilmek için bu atölyeye kayıt olmalısın.',
      );
    }

    if (cleanComment.isEmpty) {
      throw Exception(
        'Yorum boş olamaz.',
      );
    }

    if (cleanComment.length > 1000) {
      throw Exception(
        'Yorum en fazla 1000 karakter olabilir.',
      );
    }

    await supabase
        .from('workshop_comments')
        .insert({
          'workshop_id':
              cleanWorkshopId,
          'user_id': user.id,
          'comment_text':
              cleanComment,
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

    final cleanCommentId =
        commentId.trim();

    if (cleanCommentId.isEmpty) {
      return;
    }

    await supabase
        .from('workshop_comments')
        .delete()
        .eq(
          'id',
          cleanCommentId,
        )
        .eq(
          'user_id',
          user.id,
        );
  }

  // =======================================================
  // DOSYA YÜKLEME
  // =======================================================

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
        _cleanExtension(
      file.extension,
    );

    final fileName =
        _safeFileName(
      file.name,
    );

    final timestamp =
        DateTime.now()
            .millisecondsSinceEpoch;

    final path =
        '${user.id}/$timestamp-$fileName';

    await supabase.storage
        .from(mediaBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType:
                _mediaContentType(
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
        _cleanExtension(
      file.extension,
    );

    final fileName =
        _safeFileName(
      file.name,
    );

    final timestamp =
        DateTime.now()
            .millisecondsSinceEpoch;

    final path =
        '${user.id}/$timestamp-$fileName';

    await supabase.storage
        .from(coverBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType:
                _imageContentType(
              extension,
            ),
            upsert: true,
          ),
        );

    return supabase.storage
        .from(coverBucket)
        .getPublicUrl(path);
  }

  // =======================================================
  // DOSYA YARDIMCI METOTLARI
  // =======================================================

  String _cleanExtension(
    String? extension,
  ) {
    final value =
        extension
            ?.toLowerCase()
            .trim();

    if (value == null ||
        value.isEmpty) {
      return 'file';
    }

    return value.replaceAll(
      '.',
      '',
    );
  }

  String _safeFileName(
    String fileName,
  ) {
    final cleaned = fileName
        .trim()
        .toLowerCase()
        .replaceAll(
          RegExp(r'\s+'),
          '-',
        )
        .replaceAll(
          RegExp(
            r'[^a-z0-9\.\-_]',
          ),
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