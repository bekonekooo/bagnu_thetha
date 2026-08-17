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
      throw Exception(
        'Devam etmek için giriş yapmalısın.',
      );
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
      throw Exception(
        'Rehberlik oluşturulamadı. Geçersiz cevap alındı.',
      );
    }

    final result = Map<String, dynamic>.from(data);

    if (result['error'] != null) {
      throw Exception(
        result['error'].toString(),
      );
    }

    final aiResult = result['result']?.toString();

    if (aiResult == null ||
        aiResult.trim().isEmpty) {
      throw Exception(
        'AI sonucu boş döndü.',
      );
    }

    return result;
  }

  Future<List<GuidanceHistoryModel>>
      fetchMyGuidanceHistory() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Rehberlik geçmişini görmek için giriş yapmalısın.',
      );
    }

    final response = await supabase
        .from('guidance_requests')
        .select()
        .eq('user_id', user.id)
        .order(
          'created_at',
          ascending: false,
        );

    return (response as List)
        .map(
          (item) => GuidanceHistoryModel.fromMap(
            Map<String, dynamic>.from(
              item as Map,
            ),
          ),
        )
        .where(
          (item) => item.result.trim().isNotEmpty,
        )
        .toList();
  }
}

class GuidanceHistoryModel {
  final String id;
  final String fullName;
  final String guidanceType;
  final String birthDate;
  final String birthTime;
  final String birthPlace;
  final String extraInfo;
  final String result;
  final String chartImageUrl;
  final DateTime? createdAt;

  const GuidanceHistoryModel({
    required this.id,
    required this.fullName,
    required this.guidanceType,
    required this.birthDate,
    required this.birthTime,
    required this.birthPlace,
    required this.extraInfo,
    required this.result,
    required this.chartImageUrl,
    required this.createdAt,
  });

  factory GuidanceHistoryModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return GuidanceHistoryModel(
      id: map['id']?.toString() ?? '',
      fullName:
          map['full_name']?.toString() ?? '',
      guidanceType:
          map['guidance_type']?.toString() ?? '',
      birthDate:
          map['birth_date']?.toString() ?? '',
      birthTime:
          map['birth_time']?.toString() ?? '',
      birthPlace:
          map['birth_place']?.toString() ?? '',
      extraInfo:
          map['extra_info']?.toString() ?? '',
      result:
          map['result']?.toString() ?? '',
      chartImageUrl:
          map['chart_image_url']?.toString() ?? '',
      createdAt: DateTime.tryParse(
        map['created_at']?.toString() ?? '',
      ),
    );
  }

  String get typeLabel {
    switch (guidanceType) {
      case 'chinese_zodiac':
        return 'Çin Burcu';

      case 'astrology':
        return 'Astroloji';

      case 'numerology':
        return 'Numeroloji';

      default:
        return 'Rehberlik';
    }
  }

  String get formattedDate {
    final date = createdAt?.toLocal();

    if (date == null) {
      return '';
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }

  String get title {
    if (fullName.trim().isEmpty) {
      return typeLabel;
    }

    return '$typeLabel • $fullName';
  }

  String get subtitle {
    if (extraInfo.trim().isNotEmpty) {
      return extraInfo;
    }

    if (birthPlace.trim().isNotEmpty) {
      return birthPlace;
    }

    return 'Kişisel AI rehberliği';
  }
}