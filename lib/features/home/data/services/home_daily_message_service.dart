import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/core/services/supabase_service.dart';
import '../models/home_daily_message_model.dart';

class HomeDailyMessageService {
  static const Duration _cacheDuration = Duration(hours: 12);

  static const String _cachedIdKey = 'home_daily_message_id';
  static const String _cachedTitleKey = 'home_daily_message_title';
  static const String _cachedSubtitleKey = 'home_daily_message_subtitle';
  static const String _cachedAtKey = 'home_daily_message_cached_at';

  Future<HomeDailyMessageModel> getMessageForHome() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedMessage = _getCachedMessageIfValid(prefs);

    if (cachedMessage != null) {
      return cachedMessage;
    }

    try {
      final data = await supabase
          .from('home_daily_messages')
          .select('id, title, subtitle')
          .eq('is_active', true);

      final messages = (data as List)
          .map((item) {
            return HomeDailyMessageModel.fromMap(
              Map<String, dynamic>.from(item as Map),
            );
          })
          .where((message) {
            return message.title.trim().isNotEmpty &&
                message.subtitle.trim().isNotEmpty;
          })
          .toList();

      if (messages.isEmpty) {
        final oldCachedMessage = _getAnyCachedMessage(prefs);

        if (oldCachedMessage != null) {
          return oldCachedMessage;
        }

        return HomeDailyMessageModel.fallback;
      }

      final random = Random();
      final selectedMessage = messages[random.nextInt(messages.length)];

      await _saveMessageToCache(prefs, selectedMessage);

      return selectedMessage;
    } catch (e) {
      final oldCachedMessage = _getAnyCachedMessage(prefs);

      if (oldCachedMessage != null) {
        return oldCachedMessage;
      }

      return HomeDailyMessageModel.fallback;
    }
  }

  HomeDailyMessageModel? _getCachedMessageIfValid(SharedPreferences prefs) {
    final cachedAtText = prefs.getString(_cachedAtKey);

    if (cachedAtText == null || cachedAtText.trim().isEmpty) {
      return null;
    }

    final cachedAt = DateTime.tryParse(cachedAtText);

    if (cachedAt == null) {
      return null;
    }

    final now = DateTime.now();
    final difference = now.difference(cachedAt);

    if (difference >= _cacheDuration) {
      return null;
    }

    return _getAnyCachedMessage(prefs);
  }

  HomeDailyMessageModel? _getAnyCachedMessage(SharedPreferences prefs) {
    final id = prefs.getString(_cachedIdKey);
    final title = prefs.getString(_cachedTitleKey);
    final subtitle = prefs.getString(_cachedSubtitleKey);

    if (title == null || subtitle == null) {
      return null;
    }

    if (title.trim().isEmpty || subtitle.trim().isEmpty) {
      return null;
    }

    return HomeDailyMessageModel(
      id: id ?? 'cached',
      title: title,
      subtitle: subtitle,
    );
  }

  Future<void> _saveMessageToCache(
    SharedPreferences prefs,
    HomeDailyMessageModel message,
  ) async {
    await prefs.setString(_cachedIdKey, message.id);
    await prefs.setString(_cachedTitleKey, message.title);
    await prefs.setString(_cachedSubtitleKey, message.subtitle);
    await prefs.setString(_cachedAtKey, DateTime.now().toIso8601String());
  }
}