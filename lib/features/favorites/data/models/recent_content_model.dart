import 'package:flutter_application_1/features/meditations/data/models/meditation_model.dart';
import 'package:flutter_application_1/features/workshops/data/models/workshop_day_model.dart';
import 'package:flutter_application_1/features/workshops/data/models/workshop_model.dart';

class RecentContentModel {
  final String historyId;
  final String contentType;
  final DateTime? playedAt;

  final MeditationModel? meditation;

  final WorkshopModel? workshop;
  final WorkshopDayModel? workshopDay;

  const RecentContentModel({
    required this.historyId,
    required this.contentType,
    required this.playedAt,
    required this.meditation,
    required this.workshop,
    required this.workshopDay,
  });

  bool get isMeditation {
    return contentType == 'meditation' &&
        meditation != null;
  }

  bool get isWorkshopDay {
    return contentType == 'workshop_day' &&
        workshop != null &&
        workshopDay != null;
  }

  String get title {
    if (isMeditation) {
      return meditation!.title;
    }

    if (isWorkshopDay) {
      return workshopDay!.title;
    }

    return 'İçerik';
  }

  String get subtitle {
    if (isMeditation) {
      return meditation!.description;
    }

    if (isWorkshopDay) {
      return '${workshop!.title} • ${workshopDay!.dayNumber}. Gün';
    }

    return '';
  }

  String get imageUrl {
    if (isMeditation) {
      return meditation!.thumbnailUrl;
    }

    if (isWorkshopDay) {
      return workshop!.imageUrl;
    }

    return '';
  }

  String get typeLabel {
    if (isMeditation) {
      return meditation!.typeLabel;
    }

    if (isWorkshopDay) {
      return workshopDay!.contentTypeLabel;
    }

    return 'İçerik';
  }

  String get durationText {
    if (isMeditation) {
      return meditation!.durationText;
    }

    if (isWorkshopDay) {
      return workshopDay!.durationText;
    }

    return '';
  }
}