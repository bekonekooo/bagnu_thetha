import 'package:flutter_application_1/core/services/supabase_service.dart';

import 'package:flutter_application_1/features/favorites/data/models/recent_content_model.dart';

import 'package:flutter_application_1/features/meditations/data/models/meditation_model.dart';

import 'package:flutter_application_1/features/workshops/data/models/workshop_day_model.dart';
import 'package:flutter_application_1/features/workshops/data/models/workshop_model.dart';

class ContentHistoryService {
  Future<List<RecentContentModel>> fetchRecentContents({
    int limit = 10,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return [];
    }

    final safeLimit = limit < 1
        ? 10
        : limit > 50
            ? 50
            : limit;

    final historyResponse = await supabase
        .from('content_play_history')
        .select('''
          id,
          content_type,
          meditation_id,
          workshop_id,
          workshop_day_id,
          played_at
        ''')
        .eq('user_id', user.id)
        .order('played_at', ascending: false)
        .limit(safeLimit);

    final historyRows = (historyResponse as List)
        .map(
          (item) => Map<String, dynamic>.from(
            item as Map,
          ),
        )
        .toList();

    if (historyRows.isEmpty) {
      return [];
    }

    final meditationIds = historyRows
        .where(
          (row) => row['content_type'] == 'meditation',
        )
        .map(
          (row) => row['meditation_id']?.toString() ?? '',
        )
        .where(
          (id) => id.isNotEmpty,
        )
        .toSet()
        .toList();

    final workshopIds = historyRows
        .where(
          (row) => row['content_type'] == 'workshop_day',
        )
        .map(
          (row) => row['workshop_id']?.toString() ?? '',
        )
        .where(
          (id) => id.isNotEmpty,
        )
        .toSet()
        .toList();

    final workshopDayIds = historyRows
        .where(
          (row) => row['content_type'] == 'workshop_day',
        )
        .map(
          (row) => row['workshop_day_id']?.toString() ?? '',
        )
        .where(
          (id) => id.isNotEmpty,
        )
        .toSet()
        .toList();

    final meditationMap = <String, MeditationModel>{};
    final workshopMap = <String, WorkshopModel>{};
    final workshopDayMap = <String, WorkshopDayModel>{};

    if (meditationIds.isNotEmpty) {
      final response = await supabase
          .from('meditations')
          .select()
          .inFilter('id', meditationIds)
          .eq('is_active', true);

      for (final item in response as List) {
        final meditation = MeditationModel.fromMap(
          Map<String, dynamic>.from(item as Map),
        );

        meditationMap[meditation.id] = meditation;
      }
    }

    if (workshopIds.isNotEmpty) {
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
          .inFilter('id', workshopIds)
          .eq('is_active', true);

      for (final item in response as List) {
        final workshop = WorkshopModel.fromMap(
          Map<String, dynamic>.from(item as Map),
        );

        workshopMap[workshop.id] = workshop;
      }
    }

    if (workshopDayIds.isNotEmpty) {
      final response = await supabase
          .from('workshop_days')
          .select()
          .inFilter('id', workshopDayIds);

      for (final item in response as List) {
        final day = WorkshopDayModel.fromMap(
          Map<String, dynamic>.from(item as Map),
        );

        workshopDayMap[day.id] = day;
      }
    }

    final result = <RecentContentModel>[];

    for (final row in historyRows) {
      final contentType =
          row['content_type']?.toString() ?? '';

      if (contentType == 'meditation') {
        final meditationId =
            row['meditation_id']?.toString() ?? '';

        final meditation = meditationMap[meditationId];

        if (meditation == null) {
          continue;
        }

        result.add(
          RecentContentModel(
            historyId: row['id']?.toString() ?? '',
            contentType: contentType,
            playedAt: DateTime.tryParse(
              row['played_at']?.toString() ?? '',
            ),
            meditation: meditation,
            workshop: null,
            workshopDay: null,
          ),
        );

        continue;
      }

      if (contentType == 'workshop_day') {
        final workshopId =
            row['workshop_id']?.toString() ?? '';

        final workshopDayId =
            row['workshop_day_id']?.toString() ?? '';

        final workshop = workshopMap[workshopId];
        final workshopDay =
            workshopDayMap[workshopDayId];

        if (workshop == null || workshopDay == null) {
          continue;
        }

        result.add(
          RecentContentModel(
            historyId: row['id']?.toString() ?? '',
            contentType: contentType,
            playedAt: DateTime.tryParse(
              row['played_at']?.toString() ?? '',
            ),
            meditation: null,
            workshop: workshop,
            workshopDay: workshopDay,
          ),
        );
      }
    }

    return result.take(safeLimit).toList();
  }

  Future<void> clearMyHistory() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    await supabase
        .from('content_play_history')
        .delete()
        .eq('user_id', user.id);
  }
}